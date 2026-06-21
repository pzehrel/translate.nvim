---@meta

---@alias TranslationCancel fun()
---@alias TranslationCallback fun(err: string?, translated: string?)
---@alias TranslationApiKey string|fun(): string?
---@alias TranslationSystemPrompt string|fun(context: TranslationPromptContext): string
---@alias TranslationCustomTranslate fun(text:string, opts:TranslationConfig, cb:TranslationCallback):TranslationCancel?

---@class TranslationPromptContext
---@field target_language string
---@field text string
---@field file_path string
---@field extension string
---@field cache TranslationPromptCacheContext

---@class TranslationPromptCacheContext
---@field hit boolean
---@field translation string?

---@class TranslationSourceContext
---@field file_path? string
---@field extension? string
---@field cache? TranslationPromptCacheContext
---@field bypass_cache? boolean

---@class TranslationHoverRequestOptions
---@field force? boolean

---@class TranslationKeymapConfig
---@field hover string|false

---@class TranslationHoverConfig
---@field border string
---@field max_width integer
---@field max_height integer
---@field show_original boolean

---@class TranslationLlmConfig
---@field endpoint string
---@field model string
---@field api_key TranslationApiKey?
---@field api_key_env string
---@field system_prompt TranslationSystemPrompt?
---@field timeout integer
---@field translate TranslationCustomTranslate?
---@field curl string
---@field headers table<string, string>

---@class TranslationCacheConfig
---@field enabled boolean
---@field max_entries integer
---@field ttl integer
---@field persistence boolean
---@field path string
---@field debounce integer

---@class TranslationConfig
---@field target_language string
---@field keymaps TranslationKeymapConfig
---@field hover TranslationHoverConfig
---@field llm TranslationLlmConfig
---@field cache TranslationCacheConfig

---@class TranslationKeymapOptions
---@field hover? string|false

---@class TranslationHoverOptions
---@field border? string
---@field max_width? integer
---@field max_height? integer
---@field show_original? boolean

---@class TranslationLlmOptions
---@field endpoint? string
---@field model? string
---@field api_key? TranslationApiKey
---@field api_key_env? string
---@field system_prompt? TranslationSystemPrompt
---@field timeout? integer
---@field translate? TranslationCustomTranslate
---@field curl? string
---@field headers? table<string, string>

---@class TranslationCacheOptions
---@field enabled? boolean
---@field max_entries? integer
---@field ttl? integer
---@field persistence? boolean
---@field path? string
---@field debounce? integer

---@class TranslationOptions
---@field target_language? string
---@field keymaps? TranslationKeymapOptions
---@field hover? TranslationHoverOptions
---@field llm? TranslationLlmOptions
---@field cache? TranslationCacheOptions

---@class TranslationPromptOptions
---@field target_language string
---@field llm TranslationLlmConfig|TranslationLlmOptions

---@class TranslationChatMessage
---@field role "system"|"user"
---@field content string

---@class TranslationViewState
---@field bufnr integer?
---@field winid integer?
---@field original string

---@class TranslationMarkedString
---@field language? string
---@field value string
---@field kind? string

---@alias TranslationHoverContents string|TranslationMarkedString|TranslationHoverContents[]

---@class TranslationHoverResult
---@field contents TranslationHoverContents

---@class TranslationLspResponse
---@field result? TranslationHoverResult

---@class TranslationOpenAiMessage
---@field content? string

---@class TranslationOpenAiChoice
---@field message? TranslationOpenAiMessage

---@class TranslationOpenAiResponse
---@field choices? TranslationOpenAiChoice[]

---@class TranslationCacheEntry
---@field key string
---@field text_hash string
---@field translated string
---@field created_at integer
---@field accessed_at integer
---@field expires_at integer

---@class TranslationCacheStats
---@field entries integer
---@field pending integer
---@field hits integer
---@field misses integer
---@field writes integer
---@field deletes integer

---@class TranslationPersistentCache
---@field version integer
---@field entries TranslationCacheEntry[]

return {}
