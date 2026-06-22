---@class TranslateCommandsModule
local M = {}

---@return nil
function M.register()
  vim.api.nvim_create_user_command("TranslateHover", function(command)
    require("translate").hover({ force = command.bang })
  end, {
    bang = true,
    desc = "Show bilingual LSP Hover",
  })

  vim.api.nvim_create_user_command("TranslateCacheClear", function()
    require("translate").clear_cache()
    vim.notify("Translation cache cleared", vim.log.levels.INFO, { title = "translate.nvim" })
  end, {
    desc = "Clear translation result cache",
  })

  vim.api.nvim_create_user_command("TranslateCacheStats", function()
    local stats = require("translate").cache_stats()
    vim.notify(vim.inspect(stats), vim.log.levels.INFO, { title = "translate.nvim cache" })
  end, {
    desc = "Show translation cache statistics",
  })

  vim.api.nvim_create_user_command("TranslateCacheDelete", function(command)
    local deleted = require("translate").delete_cache(command.args)
    vim.notify(
      ("Deleted %d matching translation cache entries"):format(deleted),
      vim.log.levels.INFO,
      { title = "translate.nvim" }
    )
  end, {
    nargs = 1,
    desc = "Delete one or more cache variants by source text",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      require("translate.cache").flush()
    end,
  })
end

return M
