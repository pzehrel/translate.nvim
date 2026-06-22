---@class TranslateHealthModule
local M = {}

---@return nil
function M.check()
  vim.health.start("translate.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim version meets 0.10+")
  else
    vim.health.error("Requires Neovim 0.10 or higher")
  end

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl found")
  else
    vim.health.warn("curl not found; please configure custom llm.translate")
  end

  local config = require("translate.config").get()
  if type(config.llm.translate) == "function" then
    vim.health.ok("Custom LLM client configured")
  elseif config.llm.endpoint ~= "" and config.llm.model ~= "" then
    vim.health.ok("OpenAI-style LLM endpoint and model configured")
  else
    vim.health.warn("LLM endpoint and model not yet configured")
  end

  if config.keymaps.hover == false then
    vim.health.info("Default Hover mapping disabled")
  else
    vim.health.info("Default bilingual Hover mapping: " .. config.keymaps.hover)
  end

  if not config.cache.enabled then
    vim.health.info("Translation result cache disabled")
  elseif config.cache.persistence then
    vim.health.ok("Translation result persistent cache enabled: " .. config.cache.path)
  else
    vim.health.info("Session-level translation result cache enabled, disk persistence disabled")
  end
end

return M
