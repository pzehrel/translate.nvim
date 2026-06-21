# translation.nvim

使用通用 LLM API 增强 Neovim 的 LSP Hover。

当前开发重点是 `gK` 双语 Hover：原始类型提示会立即显示，LLM 译文完成后追加到同一个浮窗。插件不集成 GitHub Copilot，也不接入 Google、Bing、DeepL 等独立翻译服务。

## 要求

- Neovim 0.10+
- `curl`，或自定义 `llm.translate`
- 支持 `textDocument/hover` 的 LSP Client

## 配置

```lua
require("translation").setup({
  target_language = "zh-CN",
  keymaps = {
    hover = "gK",
  },
  llm = {
    endpoint = "https://example.com/v1/chat/completions",
    model = "your-model",
    api_key_env = "LLM_API_KEY",
  },
  cache = {
    enabled = true,
    max_entries = 500,
    ttl = 30 * 60 * 1000,
    persistence = false,
    path = vim.fs.joinpath(vim.uv.os_tmpdir(), "translation.nvim", "cache.json"),
  },
})
```

插件默认从 `LLM_API_KEY` 环境变量读取密钥。也可以修改环境变量名：

```lua
llm = {
  api_key_env = "OPENAI_API_KEY",
}
```

`api_key` 仍支持字符串或回调，并且优先于 `api_key_env`：

```lua
llm = {
  api_key = function()
    return os.getenv("PROJECT_LLM_API_KEY")
  end,
}
```

## 自定义 System Prompt

`llm.system_prompt` 支持字符串：

```lua
llm = {
  system_prompt = [[
Translate the natural-language parts of the LSP Hover into Simplified Chinese.
Preserve all Markdown, code, type signatures, identifiers, and links.
Return only the translated Markdown.
  ]],
}
```

也支持函数，可根据目标语言和原文动态生成：

```lua
llm = {
  system_prompt = function(context)
    -- context.target_language
    -- context.text
    -- context.file_path：当前 buffer 的绝对路径，未命名时为空字符串
    -- context.extension：不带点的文件扩展名，无扩展名时为空字符串
    -- context.cache.hit：当前原文是否存在未过期的历史译文
    -- context.cache.translation：历史译文；未命中时为 nil
    return "Translate software documentation into " .. context.target_language
  end,
}
```

未配置时使用插件内置的软件文档翻译 Prompt。

`context.cache` 是当前原文的历史缓存提示。真正的缓存命中仍以最终 System Prompt、User 内容、模型、Endpoint 和目标语言共同计算，避免 Prompt 或模型变化后误用旧结果。

## 翻译结果缓存

默认启用当前 Neovim 会话内的 LRU/TTL 缓存，并合并相同的进行中请求。持久化默认关闭，可显式开启：

```lua
cache = {
  persistence = true,
  ttl = 7 * 24 * 60 * 60 * 1000,
  max_entries = 1000,
}
```

磁盘缓存只保存哈希键、原文哈希、译文和时间戳，不保存原文、文件路径、Prompt 或 API Key。写入采用防抖和临时文件原子替换；缓存文件损坏时会被忽略。

默认目录位于操作系统临时目录下。它通常可以跨 Neovim 重启复用，但操作系统可随时清理，因此不应视为永久数据。用户仍可通过 `cache.path` 指定其他位置。

## 自行覆盖 `K`

```lua
require("translation").setup({
  keymaps = {
    hover = false,
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", require("translation").hover, {
      buffer = event.buf,
      desc = "双语 LSP Hover",
    })
  end,
})
```

## 自定义 LLM Client

```lua
require("translation").setup({
  llm = {
    translate = function(text, opts, callback)
      -- 完成后调用 callback(nil, translated_text)
      -- 失败时调用 callback(error_message)
      -- 可以返回一个取消函数
    end,
  },
})
```

## 命令

- `:TranslateHover`：显示双语 LSP Hover。
- `:TranslateHover!`：跳过缓存重新翻译，成功后更新该请求的缓存。
- `:TranslateCacheClear`：清除翻译结果缓存。
- `:TranslateCacheDelete {原文}`：删除该原文在不同模型、Prompt 和目标语言下的缓存变体。
- `:TranslateCacheStats`：显示缓存条目、命中、未命中和进行中请求数量。
- `:checkhealth translation`：检查运行环境和配置。

Lua API 也支持精确删除：

```lua
require("translation").delete_cache(text)      -- 按原文删除所有变体
require("translation").delete_cache_key(key)   -- 按精确缓存键删除
require("translation").hover({ force = true }) -- 跳过读取并重新翻译
```

## 开发

开发环境还需要：

- StyLua
- Luacheck
- Lua Language Server 3.18.2+

项目通过 LuaCATS 注解描述全部公开配置、回调和内部数据结构。`.luarc.json` 用于编辑器诊断，`make typecheck` 会自动加入当前 Neovim runtime 的类型定义并执行完整工作区检查。

```sh
make format
make lint
make typecheck
make test
make check
```
