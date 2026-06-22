---@type fun(name: string, fn: fun())
local test = assert(_G.test)

test("config exposes expected defaults", function()
  local config = require("translate.config")
  local defaults = config.defaults()
  assert(defaults.target_language == "zh-CN")
  assert(defaults.keymaps.hover == "gK")
  assert(defaults.llm.api_key_env == "LLM_API_KEY")
  assert(defaults.llm.timeout == 15000)
  assert(defaults.cache.enabled == true)
  assert(defaults.cache.persistence == false)
  assert(defaults.cache.max_entries == 500)
  assert(defaults.cache.path == vim.fs.joinpath(vim.uv.os_tmpdir(), "translate.nvim", "cache.json"))
end)

test("config setup deep merges without mutating defaults", function()
  local config = require("translate.config")
  local result = config.setup({
    hover = { border = "single" },
    llm = { model = "test-model" },
  })
  assert(result.hover.border == "single")
  assert(result.hover.max_width == 100)
  assert(result.llm.model == "test-model")
  assert(config.defaults().llm.model == "")
end)
