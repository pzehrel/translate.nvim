---@class TranslationModule
local M = {}

---@param opts? TranslationOptions
---@return TranslationConfig
function M.setup(opts)
  local config = require("translation.config").setup(opts)
  require("translation.hover").setup_keymap(config)
  return config
end

---@return nil
function M.hover()
  require("translation.hover").show()
end

return M
