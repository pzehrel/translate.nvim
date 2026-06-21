local M = {}

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
    timeout = 15000,
    translate = nil,
    curl = "curl",
    headers = {},
  },
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return options
end

function M.get()
  return options
end

function M.defaults()
  return vim.deepcopy(defaults)
end

return M
