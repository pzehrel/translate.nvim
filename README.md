# translate.nvim

English | [中文](README.zh.md)

Bilingual LSP Hover for Neovim. Press `gK` to see the original type hint and an LLM translation side by side in the same floating window.

- Original hover content appears instantly
- LLM translation streams in below once ready
- Works with any OpenAI-style LLM endpoint or a custom client
- Caches results so repeated hovers feel instant

## Requirements

- Neovim 0.10+
- An LSP client that supports `textDocument/hover`
- `curl` (or supply your own `llm.translate` function)
- An LLM API key

## Installation

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

## Quick Start

1. Set `OPENAI_API_KEY` in your environment.
2. Install the plugin with the config above.
3. Place your cursor on a symbol and press `gK`.
4. The original LSP hover appears first; the translation is appended after the LLM responds.

## Usage

### Default keymap

- `gK` — show bilingual LSP hover for the symbol under the cursor.

### Commands

| Command | Description |
|---|---|
| `:TranslateHover` | Show bilingual LSP hover. |
| `:TranslateHover!` | Skip cache and re-translate; update cache on success. |
| `:TranslateCacheClear` | Clear all translation results from the cache. |
| `:TranslateCacheDelete {source_text}` | Delete every variant of a source text from the cache. |
| `:TranslateCacheStats` | Show cache stats: entries, hits, misses, pending requests. |
| `:checkhealth translate` | Verify requirements and configuration. |

### Override `K` instead of `gK`

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

## Features

- **Non-blocking bilingual hover**: the original LSP response shows immediately; the LLM translation is appended when it arrives.
- **Session and persistent cache**: LRU/TTL cache in memory by default, optional disk persistence across restarts.
- **Custom system prompt**: replace the built-in prompt with your own string or a function that receives file context and cache state.
- **Custom LLM client**: bypass `curl` entirely and provide your own `translate` function.
- **Privacy-conscious cache**: the cache stores hashes and translations only, never the raw source text, file paths, prompts, or API keys.

## Configuration

Full options with defaults:

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
    api_key = nil,                 -- string or function returning a string
    api_key_env = "LLM_API_KEY",   -- ignored when api_key is set
    timeout = 30000,
    curl = "curl",
    headers = {},
    system_prompt = nil,           -- string or function(context) -> string
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

### API key

The plugin reads the key from `LLM_API_KEY` by default. Use a different variable:

```lua
llm = { api_key_env = "OPENAI_API_KEY" }
```

Or provide it directly (takes precedence over `api_key_env`):

```lua
llm = {
  api_key = function()
    return os.getenv("PROJECT_LLM_API_KEY")
  end,
}
```

### Custom system prompt

String:

```lua
llm = {
  system_prompt = [[
Translate the natural-language parts of the LSP Hover into Simplified Chinese.
Preserve all Markdown, code, type signatures, identifiers, and links.
Return only the translated Markdown.
  ]],
}
```

Function with context:

```lua
llm = {
  system_prompt = function(context)
    -- context.target_language
    -- context.text
    -- context.file_path        -- current buffer path, empty when unnamed
    -- context.extension        -- file extension without dot, empty when none
    -- context.cache.hit        -- whether a cached translation exists
    -- context.cache.translation -- the cached translation, or nil
    return "Translate software documentation into " .. context.target_language
  end,
}
```

When omitted, a built-in software-documentation prompt is used.

### Cache

Enable persistent disk cache:

```lua
cache = {
  persistence = true,
  ttl = 7 * 24 * 60 * 60 * 1000,
  max_entries = 1000,
}
```

The cache file stores hash keys, source hashes, translations, and timestamps. It never stores raw source text, file paths, prompts, or API keys. The default path lives in the OS temporary directory and may be cleaned up by the OS; set `cache.path` to keep it elsewhere.

### Custom LLM client

```lua
llm = {
  translate = function(text, opts, callback)
    -- callback(nil, translated_text) on success
    -- callback(error_message) on failure
    -- optionally return a cancel function
  end,
}
```

## Lua API

```lua
require("translate").hover({ force = true })   -- skip cache and re-translate
require("translate").clear_cache()             -- clear all cache entries
require("translate").delete_cache(text)        -- delete all variants of source text
require("translate").delete_cache_key(key)     -- delete a single exact cache key
require("translate").cache_stats()             -- return cache statistics
```

## Development

Development dependencies:

- StyLua
- Luacheck
- Lua Language Server 3.18.2+

```sh
make format   -- format code
make lint     -- lint code
make typecheck -- run LuaCATS type check
make test     -- run tests
make check    -- run all of the above
```

The project uses LuaCATS annotations for all public configuration, callbacks, and internal data structures. `.luarc.json` configures editor diagnostics; `make typecheck` includes the current Neovim runtime types and checks the whole workspace.
