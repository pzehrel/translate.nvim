---@class TranslateConfigModule
local M = {}

---@type TranslateConfig
local defaults = {
  target_language = "zh-CN",
  keymaps = {
    hover = "gK",
  },
  hover = {
    border = "rounded",
    max_width = 100,
    max_height = 30,
    show_original = true,
  },
  llm = {
    endpoint = "",
    model = "",
    api_key = nil,
    api_key_env = "LLM_API_KEY",
    system_prompt = nil,
    timeout = 15000,
    translate = nil,
    curl = "curl",
    headers = {},
  },
  cache = {
    enabled = true,
    max_entries = 500,
    ttl = 30 * 60 * 1000,
    persistence = false,
    path = vim.fs.joinpath(vim.uv.os_tmpdir(), "translate.nvim", "cache.json"),
    debounce = 1500,
  },
}

---@type TranslateConfig
local options = vim.deepcopy(defaults)

---@param opts? TranslateOptions
---@return TranslateConfig
function M.setup(opts)
  ---@type TranslateConfig
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return options
end

---@return TranslateConfig
function M.get()
  return options
end

---@return TranslateConfig
function M.defaults()
  return vim.deepcopy(defaults)
end

return M
