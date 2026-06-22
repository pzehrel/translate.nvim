# translate.nvim

[English](README.md) | 中文

为 Neovim 提供双语 LSP Hover。把光标停在符号上按 `gK`，原始类型提示和 LLM 译文会先后出现在同一个浮窗里。

- 原始 Hover 内容立即显示
- LLM 译文准备好后自动追加到下方
- 支持任意 OpenAI 风格接口，也可以接入你自己的 LLM Client
- 翻译结果会缓存，重复查看几乎无延迟

## 要求

- Neovim 0.10+
- 支持 `textDocument/hover` 的 LSP Client
- `curl`（或自己实现 `llm.translate`）
- LLM API 密钥

## 安装

### lazy.nvim

```lua
{
  "pzehrel/translate.nvim",
  config = function()
    require("translate").setup({
      target_language = "zh-CN",
      llm = {
        endpoint = "https://api.openai.com/v1/chat/completions",
        model = "gpt-4o-mini",
        api_key_env = "OPENAI_API_KEY",
      },
    })
  end,
}
```

### vim-plug

```vim
Plug 'pzehrel/translate.nvim'
```

```lua
require("translate").setup({
  target_language = "zh-CN",
  llm = {
    endpoint = "https://api.openai.com/v1/chat/completions",
    model = "gpt-4o-mini",
    api_key_env = "OPENAI_API_KEY",
  },
})
```

## 快速开始

1. 在环境中设置 `OPENAI_API_KEY`。
2. 用上面的配置安装插件。
3. 光标停在代码符号上，按 `gK`。
4. 先看到原始 LSP Hover，LLM 返回后译文自动追加到同一浮窗。

## 使用

### 默认快捷键

- `gK` — 显示光标下符号的双语 LSP Hover。

### 命令

| 命令 | 说明 |
|---|---|
| `:TranslateHover` | 显示双语 LSP Hover。 |
| `:TranslateHover!` | 跳过缓存重新翻译；成功后更新该请求缓存。 |
| `:TranslateCacheClear` | 清空所有翻译缓存。 |
| `:TranslateCacheDelete {source_text}` | 删除某段原文对应的所有缓存变体。 |
| `:TranslateCacheStats` | 显示缓存条目、命中、未命中和进行中请求数量。 |
| `:checkhealth translate` | 检查环境依赖和配置。 |

### 把 `K` 改成双语 Hover

```lua
require("translate").setup({
  keymaps = { hover = false },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", require("translate").hover, {
      buffer = event.buf,
      desc = "Bilingual LSP Hover",
    })
  end,
})
```

## 特性

- **非阻塞双语浮窗**：原始 LSP 响应立即显示，LLM 译文到达后自动追加。
- **会话缓存与持久化缓存**：默认内存 LRU/TTL 缓存，可选磁盘持久化，跨 Neovim 重启复用。
- **自定义 System Prompt**：可用字符串或函数替换内置 Prompt，函数可获取文件上下文和缓存状态。
- **自定义 LLM Client**：完全绕过 `curl`，提供自己的 `translate` 函数。
- **隐私友好的缓存**：缓存只保存哈希键、原文哈希、译文和时间戳，不保存原文、文件路径、Prompt 或 API Key。

## 配置

完整默认配置：

```lua
require("translate").setup({
  target_language = "zh-CN",
  keymaps = {
    hover = "gK",
  },
  hover = {
    border = "rounded",
    max_width = 80,
    max_height = 30,
    show_original = true,
  },
  llm = {
    endpoint = "",
    model = "",
    api_key = nil,                 -- 字符串或返回字符串的函数
    api_key_env = "LLM_API_KEY",   -- 设置 api_key 时忽略此项
    timeout = 30000,
    curl = "curl",
    headers = {},
    system_prompt = nil,           -- 字符串或 function(context) -> string
    translate = nil,               -- function(text, opts, callback) -> cancel?
  },
  cache = {
    enabled = true,
    max_entries = 500,
    ttl = 30 * 60 * 1000,
    persistence = false,
    path = vim.fs.joinpath(vim.uv.os_tmpdir(), "translate.nvim", "cache.json"),
    debounce = 1000,
  },
})
```

### API 密钥

插件默认从 `LLM_API_KEY` 读取密钥。换成其他环境变量：

```lua
llm = { api_key_env = "OPENAI_API_KEY" }
```

或直接提供（优先级高于 `api_key_env`）：

```lua
llm = {
  api_key = function()
    return os.getenv("PROJECT_LLM_API_KEY")
  end,
}
```

### 自定义 System Prompt

字符串形式：

```lua
llm = {
  system_prompt = [[
Translate the natural-language parts of the LSP Hover into Simplified Chinese.
Preserve all Markdown, code, type signatures, identifiers, and links.
Return only the translated Markdown.
  ]],
}
```

函数形式，可获取上下文：

```lua
llm = {
  system_prompt = function(context)
    -- context.target_language
    -- context.text
    -- context.file_path        -- 当前 buffer 绝对路径，未命名时为空字符串
    -- context.extension        -- 不带点的文件扩展名，无扩展名时为空字符串
    -- context.cache.hit        -- 是否存在未过期缓存
    -- context.cache.translation -- 缓存译文，未命中时为 nil
    return "Translate software documentation into " .. context.target_language
  end,
}
```

不配置时，插件使用内置的软件文档翻译 Prompt。

### 缓存

开启磁盘持久化：

```lua
cache = {
  persistence = true,
  ttl = 7 * 24 * 60 * 60 * 1000,
  max_entries = 1000,
}
```

缓存文件只保存哈希键、原文哈希、译文和时间戳，不保存原文、文件路径、Prompt 或 API Key。默认路径位于操作系统临时目录，可能被系统清理；可通过 `cache.path` 指定其他位置。

### 自定义 LLM Client

```lua
llm = {
  translate = function(text, opts, callback)
    -- 成功时调用 callback(nil, translated_text)
    -- 失败时调用 callback(error_message)
    -- 可返回一个取消函数
  end,
}
```

## Lua API

```lua
require("translate").hover({ force = true })   -- 跳过缓存重新翻译
require("translate").clear_cache()             -- 清空缓存
require("translate").delete_cache(text)        -- 按原文删除所有变体
require("translate").delete_cache_key(key)     -- 按精确缓存键删除
require("translate").cache_stats()             -- 返回缓存统计信息
```

## 开发

开发依赖：

- StyLua
- Luacheck
- Lua Language Server 3.18.2+

```sh
make format      -- 格式化代码
make lint        -- 静态检查
make typecheck   -- LuaCATS 类型检查
make test        -- 运行测试
make check       -- 执行以上全部
```

项目使用 LuaCATS 注解描述公开配置、回调和内部数据结构。`.luarc.json` 用于编辑器诊断，`make typecheck` 会自动加入当前 Neovim runtime 类型定义并执行完整工作区检查。
