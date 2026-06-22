---@class TranslateHealthModule
local M = {}

---@return nil
function M.check()
  vim.health.start("translate.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim 版本满足 0.10+")
  else
    vim.health.error("需要 Neovim 0.10 或更高版本")
  end

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("已找到 curl")
  else
    vim.health.warn("未找到 curl；请配置自定义 llm.translate")
  end

  local config = require("translate.config").get()
  if type(config.llm.translate) == "function" then
    vim.health.ok("已配置自定义 LLM Client")
  elseif config.llm.endpoint ~= "" and config.llm.model ~= "" then
    vim.health.ok("已配置 OpenAI 风格 LLM endpoint 与 model")
  else
    vim.health.warn("尚未配置 LLM endpoint 与 model")
  end

  if config.keymaps.hover == false then
    vim.health.info("默认 Hover 映射已禁用")
  else
    vim.health.info("默认双语 Hover 映射：" .. config.keymaps.hover)
  end

  if not config.cache.enabled then
    vim.health.info("翻译结果缓存已禁用")
  elseif config.cache.persistence then
    vim.health.ok("翻译结果持久化缓存已启用：" .. config.cache.path)
  else
    vim.health.info("已启用会话级翻译结果缓存，磁盘持久化关闭")
  end
end

return M
