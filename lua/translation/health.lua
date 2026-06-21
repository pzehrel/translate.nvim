local M = {}

function M.check()
  vim.health.start("translation.nvim")

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

  local config = require("translation.config").get()
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
end

return M
