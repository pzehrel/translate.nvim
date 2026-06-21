---@type fun(name: string, fn: fun())
local test = assert(_G.test)

local markdown = require("translation.markdown")

test("normalizes markup content", function()
  assert(markdown.normalize({ kind = "markdown", value = "**hello**" }) == "**hello**")
end)

test("normalizes marked strings and code blocks", function()
  local result = markdown.normalize({
    "description",
    { language = "lua", value = "local x = 1" },
  })
  assert(result == "description\n\n```lua\nlocal x = 1\n```")
end)

test("collects unique hover responses", function()
  local result = markdown.collect({
    [1] = { result = { contents = "same" } },
    [2] = { result = { contents = "same" } },
    [3] = { result = { contents = "different" } },
  })
  assert(result == "different\n\n---\n\nsame")
end)
