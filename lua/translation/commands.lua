---@class TranslationCommandsModule
local M = {}

---@return nil
function M.register()
  vim.api.nvim_create_user_command("TranslateHover", function(command)
    require("translation").hover({ force = command.bang })
  end, {
    bang = true,
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

  vim.api.nvim_create_user_command("TranslateCacheDelete", function(command)
    local deleted = require("translation").delete_cache(command.args)
    vim.notify(
      ("已删除 %d 条匹配的翻译缓存"):format(deleted),
      vim.log.levels.INFO,
      { title = "translation.nvim" }
    )
  end, {
    nargs = 1,
    desc = "按原文删除单条或多个缓存变体",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      require("translation.cache").flush()
    end,
  })
end

return M
