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
    api_key = function()
      return os.getenv("LLM_API_KEY")
    end,
  },
})
```

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

```sh
make format
make lint
make test
make check
```

