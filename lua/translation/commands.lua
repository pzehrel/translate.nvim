---@class TranslationCommandsModule
local M = {}

---@return nil
function M.register()
  vim.api.nvim_create_user_command("TranslateHover", function()
    require("translation").hover()
  end, {
    desc = "显示双语 LSP Hover",
  })
end

return M
