---@meta

---@alias TranslateCancel fun()
---@alias TranslateCallback fun(err: string?, translated: string?)
---@alias TranslateApiKey string|fun(): string?
---@alias TranslateSystemPrompt string|fun(context: TranslatePromptContext): string
---@alias TranslateCustomTranslate fun(text:string, opts:TranslateConfig, cb:TranslateCallback):TranslateCancel?

---@class TranslatePromptContext
---@field target_language string
---@field text string
---@field file_path string
---@field extension string
---@field cache TranslatePromptCacheContext

---@class TranslatePromptCacheContext
---@field hit boolean
---@field translation string?

---@class TranslateSourceContext
---@field file_path? string
---@field extension? string
---@field cache? TranslatePromptCacheContext
---@field bypass_cache? boolean

---@class TranslateHoverRequestOptions
---@field force? boolean

---@class TranslateKeymapConfig
---@field hover string|false

---@class TranslateHoverConfig
---@field border string
---@field max_width integer
---@field max_height integer
---@field show_original boolean

---@class TranslateLlmConfig
---@field endpoint string
---@field model string
---@field api_key TranslateApiKey?
---@field api_key_env string
---@field system_prompt TranslateSystemPrompt?
---@field timeout integer
---@field translate TranslateCustomTranslate?
---@field curl string
---@field headers table<string, string>

---@class TranslateCacheConfig
---@field enabled boolean
---@field max_entries integer
---@field ttl integer
---@field persistence boolean
---@field path string
---@field debounce integer

---@class TranslateConfig
---@field target_language string
---@field keymaps TranslateKeymapConfig
---@field hover TranslateHoverConfig
---@field llm TranslateLlmConfig
---@field cache TranslateCacheConfig

---@class TranslateKeymapOptions
---@field hover? string|false

---@class TranslateHoverOptions
---@field border? string
---@field max_width? integer
---@field max_height? integer
---@field show_original? boolean

---@class TranslateLlmOptions
---@field endpoint? string
---@field model? string
---@field api_key? TranslateApiKey
---@field api_key_env? string
---@field system_prompt? TranslateSystemPrompt
---@field timeout? integer
---@field translate? TranslateCustomTranslate
---@field curl? string
---@field headers? table<string, string>

---@class TranslateCacheOptions
---@field enabled? boolean
---@field max_entries? integer
---@field ttl? integer
---@field persistence? boolean
---@field path? string
---@field debounce? integer

---@class TranslateOptions
---@field target_language? string
---@field keymaps? TranslateKeymapOptions
---@field hover? TranslateHoverOptions
---@field llm? TranslateLlmOptions
---@field cache? TranslateCacheOptions

---@class TranslatePromptOptions
---@field target_language string
---@field llm TranslateLlmConfig|TranslateLlmOptions

---@class TranslateChatMessage
---@field role "system"|"user"
---@field content string

---@class TranslateViewState
---@field bufnr integer?
---@field winid integer?
---@field original string

---@class TranslateMarkedString
---@field language? string
---@field value string
---@field kind? string

---@alias TranslateHoverContents string|TranslateMarkedString|TranslateHoverContents[]

---@class TranslateHoverResult
---@field contents TranslateHoverContents

---@class TranslateLspResponse
---@field result? TranslateHoverResult

---@class TranslateOpenAiMessage
---@field content? string

---@class TranslateOpenAiChoice
---@field message? TranslateOpenAiMessage

---@class TranslateOpenAiResponse
---@field choices? TranslateOpenAiChoice[]

---@class TranslateCacheEntry
---@field key string
---@field text_hash string
---@field translated string
---@field created_at integer
---@field accessed_at integer
---@field expires_at integer

---@class TranslateCacheStats
---@field entries integer
---@field pending integer
---@field hits integer
---@field misses integer
---@field writes integer
---@field deletes integer

---@class TranslatePersistentCache
---@field version integer
---@field entries TranslateCacheEntry[]

return {}
