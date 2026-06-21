local M = {}

function M.setup(opts)
  local config = require("translation.config").setup(opts)
  require("translation.hover").setup_keymap(config)
  return config
end

function M.hover()
  return require("translation.hover").show()
end

return M
