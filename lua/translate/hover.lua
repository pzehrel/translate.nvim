---@class TranslateHoverModule
local M = {}

local augroup = vim.api.nvim_create_augroup("translate.nvim", { clear = true })
local generation = 0
---@type TranslateCancel?
local cancel_translation = nil

---@param bufnr integer
---@param lhs string
---@return boolean
local function has_buffer_mapping(bufnr, lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
    if mapping.lhs == lhs then
      return true
    end
  end
  return false
end

---@param lhs string
---@return boolean
local function has_global_mapping(lhs)
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  return type(mapping) == "table" and next(mapping) ~= nil
end

---@param client vim.lsp.Client?
---@return boolean
local function supports_hover(client)
  return client ~= nil and client:supports_method("textDocument/hover")
end

---@param config TranslateConfig
---@return nil
function M.setup_keymap(config)
  vim.api.nvim_clear_autocmds({ group = augroup })
  if config.keymaps.hover == false then
    return
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(event)
      ---@cast event vim.api.keyset.create_autocmd.callback_args
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      local lhs = config.keymaps.hover
      ---@cast lhs string
      if
        not supports_hover(client)
        or has_buffer_mapping(event.buf, lhs)
        or has_global_mapping(lhs)
      then
        return
      end

      vim.keymap.set("n", lhs, M.show, {
        buffer = event.buf,
        desc = "Bilingual LSP Hover",
      })
    end,
  })
end

---@param bufnr integer
---@return lsp.TextDocumentPositionParams
local function request_params(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })
  local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
  return vim.lsp.util.make_position_params(0, encoding)
end

---@param bufnr integer
---@return TranslateSourceContext
local function source_context(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  return {
    file_path = file_path,
    extension = file_path == "" and "" or vim.fn.fnamemodify(file_path, ":e"),
  }
end

---@param opts? TranslateHoverRequestOptions
---@return nil
function M.show(opts)
  opts = opts or {}
  local view = require("translate.view")
  if opts.force and view.is_open() then
    view.close()
  elseif view.focus() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local config = require("translate.config").get()

  generation = generation + 1
  local request_generation = generation
  if cancel_translation then
    cancel_translation()
    cancel_translation = nil
  end

  vim.lsp.buf_request_all(bufnr, "textDocument/hover", request_params(bufnr), function(responses)
    if request_generation ~= generation or not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
      return
    end
    if not vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor) then
      return
    end

    local original = require("translate.markdown").collect(responses)
    if original == "" then
      vim.notify(
        "No LSP Hover content at current position",
        vim.log.levels.INFO,
        { title = "translate.nvim" }
      )
      return
    end

    view.open(original, config)
    cancel_translation = require("translate.llm").translate(
      original,
      config,
      function(err, translated)
        cancel_translation = nil
        if request_generation ~= generation or not view.is_open() then
          return
        end
        if err then
          view.fail(err)
          return
        end
        view.finish(assert(translated))
      end,
      vim.tbl_extend("force", source_context(bufnr), {
        bypass_cache = opts.force == true,
      })
    )
  end)
end

return M
