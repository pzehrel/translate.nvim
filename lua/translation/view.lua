local M = {}

local state = {
  bufnr = nil,
  winid = nil,
  original = "",
}

local function lines(text)
  return vim.split(text, "\n", { plain = true })
end

local function render(body)
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines(body))
  vim.bo[state.bufnr].modifiable = false
end

function M.is_open()
  return state.winid ~= nil and vim.api.nvim_win_is_valid(state.winid)
end

function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(state.winid)
    return true
  end
  return false
end

function M.open(original, config)
  state.original = original
  local body = original .. "\n\n---\n\n_正在翻译…_"
  local bufnr, winid = vim.lsp.util.open_floating_preview(lines(body), "markdown", {
    border = config.hover.border,
    max_width = config.hover.max_width,
    max_height = config.hover.max_height,
    focusable = true,
    focus = false,
  })
  state.bufnr = bufnr
  state.winid = winid
end

function M.finish(translated)
  render(state.original .. "\n\n---\n\n" .. translated)
end

function M.fail(message)
  render(state.original .. "\n\n---\n\n> [!warning]\n> " .. message)
end

function M.reset()
  state.bufnr = nil
  state.winid = nil
  state.original = ""
end

return M
