---@class TranslationModule
local M = {}

---@param opts? TranslationOptions
---@return TranslationConfig
function M.setup(opts)
  local config = require("translation.config").setup(opts)
  require("translation.cache").setup(config.cache)
  require("translation.hover").setup_keymap(config)
  return config
end

---@param opts? TranslationHoverRequestOptions
---@return nil
function M.hover(opts)
  require("translation.hover").show(opts)
end

---@return nil
function M.clear_cache()
  require("translation.cache").clear()
end

---@param text string
---@return integer deleted
function M.delete_cache(text)
  return require("translation.cache").delete_text(text)
end

---@param key string
---@return boolean
function M.delete_cache_key(key)
  return require("translation.cache").delete_key(key)
end

---@return TranslationCacheStats
function M.cache_stats()
  return require("translation.cache").stats()
end

return M
