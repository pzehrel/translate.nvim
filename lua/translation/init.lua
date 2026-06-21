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

---@return nil
function M.hover()
  require("translation.hover").show()
end

---@return nil
function M.clear_cache()
  require("translation.cache").clear()
end

---@return TranslationCacheStats
function M.cache_stats()
  return require("translation.cache").stats()
end

return M
