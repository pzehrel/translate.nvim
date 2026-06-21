test("config exposes expected defaults", function()
  local config = require("translation.config")
  local defaults = config.defaults()
  assert(defaults.target_language == "zh-CN")
  assert(defaults.keymaps.hover == "gK")
  assert(defaults.llm.timeout == 15000)
end)

test("config setup deep merges without mutating defaults", function()
  local config = require("translation.config")
  local result = config.setup({
    hover = { border = "single" },
    llm = { model = "test-model" },
  })
  assert(result.hover.border == "single")
  assert(result.hover.max_width == 100)
  assert(result.llm.model == "test-model")
  assert(config.defaults().llm.model == "")
end)
