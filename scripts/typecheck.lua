---@class LuaLsConfig
---@field ["workspace.library"]? string[]

local root = vim.fn.getcwd()
local config_path = root .. "/.luarc.json"
local work_dir = root .. "/.nvim-test/luals"
local generated_config = work_dir .. "/luarc.json"

vim.fn.mkdir(work_dir, "p")

local config_file = assert(io.open(config_path, "r"))
local config = vim.json.decode(config_file:read("*a")) --[[@as LuaLsConfig]]
config_file:close()

config["workspace.library"] = { vim.env.VIMRUNTIME }

local output = assert(io.open(generated_config, "w"))
output:write(vim.json.encode(config))
output:close()

local result = vim
  .system({
    "lua-language-server",
    "--configpath=" .. generated_config,
    "--check=" .. root,
    "--checklevel=Warning",
    "--logpath=" .. work_dir,
  }, { text = true })
  :wait()

if result.stdout and result.stdout ~= "" then
  io.write(result.stdout)
end
if result.stderr and result.stderr ~= "" then
  io.stderr:write(result.stderr)
end

os.exit(result.code)
