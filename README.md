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
    return "Translate software documentation into " .. context.target_language
  end,
}
```

未配置时使用插件内置的软件文档翻译 Prompt。

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
- `:checkhealth translation`：检查运行环境和配置。

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
