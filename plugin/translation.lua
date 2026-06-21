if vim.g.loaded_translation_nvim == 1 then
  return
end
vim.g.loaded_translation_nvim = 1

require("translation.commands").register()
