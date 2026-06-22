---@class TranslateModule
local M = {}

---@param opts? TranslateOptions
---@return TranslateConfig
function M.setup(opts)
  local config = require("translate.config").setup(opts)
  require("translate.cache").setup(config.cache)
  require("translate.hover").setup_keymap(config)
  return config
end

---@param opts? TranslateHoverRequestOptions
---@return nil
function M.hover(opts)
  require("translate.hover").show(opts)
end

---@return nil
function M.clear_cache()
  require("translate.cache").clear()
end

---@param text string
---@return integer deleted
function M.delete_cache(text)
  return require("translate.cache").delete_text(text)
end

---@param key string
---@return boolean
function M.delete_cache_key(key)
  return require("translate.cache").delete_key(key)
end

---@return TranslateCacheStats
function M.cache_stats()
  return require("translate.cache").stats()
end

return M
