# translate.nvim

Enhance Neovim's LSP Hover with generic LLM APIs.

The current development focus is the `gK` bilingual Hover: original type hints display immediately, and the LLM translation is appended to the same floating window once ready. The plugin does not integrate GitHub Copilot, nor does it connect to Google, Bing, DeepL, or other standalone translation services.

## Requirements

- Neovim 0.10+
- `curl`, or a custom `llm.translate`
- An LSP client that supports `textDocument/hover`

## Configuration

```lua
require("translate").setup({
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
    path = vim.fs.joinpath(vim.uv.os_tmpdir(), "translate.nvim", "cache.json"),
  },
})
```

The plugin reads the API key from the `LLM_API_KEY` environment variable by default. You can change the environment variable name:

```lua
llm = {
  api_key_env = "OPENAI_API_KEY",
}
```

`api_key` still supports strings or callbacks, and takes precedence over `api_key_env`:

```lua
llm = {
  api_key = function()
    return os.getenv("PROJECT_LLM_API_KEY")
  end,
}
```

## Custom System Prompt

`llm.system_prompt` supports strings:

```lua
llm = {
  system_prompt = [[
Translate the natural-language parts of the LSP Hover into Simplified Chinese.
Preserve all Markdown, code, type signatures, identifiers, and links.
Return only the translated Markdown.
  ]],
}
```

It also supports functions that generate the prompt dynamically based on the target language and source text:

```lua
llm = {
  system_prompt = function(context)
    -- context.target_language
    -- context.text
    -- context.file_path: absolute path of the current buffer, empty when unnamed
    -- context.extension: file extension without the leading dot, empty when none
    -- context.cache.hit: whether an unexpired historical translation exists for the current text
    -- context.cache.translation: the historical translation; nil on cache miss
    return "Translate software documentation into " .. context.target_language
  end,
}
```

When not configured, the plugin uses its built-in software documentation translation prompt.

`context.cache` is a historical cache hint for the current text. True cache hits are still determined by the final System Prompt, User content, model, endpoint, and target language, so old results are not reused after the prompt or model changes.

## Translation Result Cache

An LRU/TTL cache is enabled by default within the current Neovim session, and identical in-flight requests are deduplicated. Persistence is disabled by default and can be enabled explicitly:

```lua
cache = {
  persistence = true,
  ttl = 7 * 24 * 60 * 60 * 1000,
  max_entries = 1000,
}
```

The disk cache stores only the hash key, source text hash, translation, and timestamp. It does not store the source text, file path, prompt, or API key. Writes are debounced and use atomic temporary file replacement; corrupted cache files are ignored.

The default directory is under the OS temporary directory. It can usually be reused across Neovim restarts, but the OS may clean it up at any time, so it should not be treated as permanent data. You can still specify another location via `cache.path`.

## Overriding `K` Manually

```lua
require("translate").setup({
  keymaps = {
    hover = false,
  },
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

## Custom LLM Client

```lua
require("translate").setup({
  llm = {
    translate = function(text, opts, callback)
      -- call callback(nil, translated_text) on success
      -- call callback(error_message) on failure
      -- may return a cancel function
    end,
  },
})
```

## Commands

- `:TranslateHover`: Show bilingual LSP Hover.
- `:TranslateHover!`: Skip the cache and re-translate; update the cache for this request on success.
- `:TranslateCacheClear`: Clear the translation result cache.
- `:TranslateCacheDelete {source_text}`: Delete cache variants for the source text across different models, prompts, and target languages.
- `:TranslateCacheStats`: Show cache entries, hits, misses, and in-flight request counts.
- `:checkhealth translate`: Check the runtime environment and configuration.

The Lua API also supports precise deletion:

```lua
require("translate").delete_cache(text)      -- delete all variants by source text
require("translate").delete_cache_key(key)   -- delete by exact cache key
require("translate").hover({ force = true }) -- skip cache and re-translate
```

## Development

The development environment also requires:

- StyLua
- Luacheck
- Lua Language Server 3.18.2+

The project uses LuaCATS annotations to describe all public configuration, callbacks, and internal data structures. `.luarc.json` is used for editor diagnostics, and `make typecheck` automatically includes the current Neovim runtime type definitions and performs a full workspace check.

```sh
make format
make lint
make typecheck
make test
make check
```
