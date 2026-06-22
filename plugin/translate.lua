if vim.g.loaded_translate_nvim == 1 then
  return
end
vim.g.loaded_translate_nvim = 1

require("translate.commands").register()
