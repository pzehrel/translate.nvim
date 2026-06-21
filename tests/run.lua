local failures = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

_G.test = test

dofile("tests/config_spec.lua")
dofile("tests/markdown_spec.lua")
dofile("tests/llm_spec.lua")

if failures > 0 then
  vim.cmd("cquit " .. failures)
end

vim.cmd("quit")
