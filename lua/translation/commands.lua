---@class TranslationCommandsModule
local M = {}

---@return nil
function M.register()
  vim.api.nvim_create_user_command("TranslateHover", function()
    require("translation").hover()
  end, {
    desc = "显示双语 LSP Hover",
  })

  vim.api.nvim_create_user_command("TranslateCacheClear", function()
    require("translation").clear_cache()
    vim.notify("翻译缓存已清除", vim.log.levels.INFO, { title = "translation.nvim" })
  end, {
    desc = "清除翻译结果缓存",
  })

  vim.api.nvim_create_user_command("TranslateCacheStats", function()
    local stats = require("translation").cache_stats()
    vim.notify(vim.inspect(stats), vim.log.levels.INFO, { title = "translation.nvim cache" })
  end, {
    desc = "显示翻译缓存统计",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      require("translation.cache").flush()
    end,
  })
end

return M
