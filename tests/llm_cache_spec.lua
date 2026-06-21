---@type fun(name: string, fn: fun())
local test = assert(_G.test)

test("llm translation reuses a cached successful result", function()
  local calls = 0
  local config = require("translation.config").setup({
    cache = {
      enabled = true,
      persistence = false,
    },
    llm = {
      translate = function(_, _, callback)
        calls = calls + 1
        callback(nil, "cached translation")
      end,
    },
  })
  local cache = require("translation.cache")
  cache.setup(config.cache)
  cache.clear()

  local first = nil
  require("translation.llm").translate("same text", config, function(_, translated)
    first = translated
  end)
  assert(first == "cached translation")

  local second = nil
  require("translation.llm").translate("same text", config, function(_, translated)
    second = translated
  end)
  vim.wait(100, function()
    return second ~= nil
  end)

  assert(second == "cached translation")
  assert(calls == 1)
end)
