---@class TranslationPromptModule
local M = {}

---@param context TranslationPromptContext
---@return string
function M.default_system_prompt(context)
  return table.concat({
    "You translate software documentation.",
    "Translate only natural-language prose into " .. context.target_language .. ".",
    "Preserve Markdown structure exactly.",
    "Do not translate or duplicate fenced code blocks, type signatures, inline code, URLs,",
    "symbol names, identifiers, or link targets.",
    "Return only the translated Markdown.",
  }, " ")
end

---@param system_prompt TranslationSystemPrompt?
---@param context TranslationPromptContext
---@return string? prompt
---@return string? error
function M.resolve_system_prompt(system_prompt, context)
  if type(system_prompt) == "function" then
    local ok, value = pcall(system_prompt, context)
    if not ok then
      return nil, tostring(value)
    end
    if type(value) ~= "string" or value == "" then
      return nil, "llm.system_prompt 回调必须返回非空字符串"
    end
    return value
  end

  if type(system_prompt) == "string" and system_prompt ~= "" then
    return system_prompt
  end

  return M.default_system_prompt(context)
end

---@param text string
---@param opts TranslationConfig|TranslationPromptOptions
---@param source_context? TranslationSourceContext
---@return TranslationChatMessage[]? messages
---@return string? error
function M.messages(text, opts, source_context)
  source_context = source_context or {}
  local system_prompt, err = M.resolve_system_prompt(opts.llm.system_prompt, {
    target_language = opts.target_language,
    text = text,
    file_path = source_context.file_path or "",
    extension = source_context.extension or "",
    cache = source_context.cache or { hit = false },
  })
  if not system_prompt then
    return nil, err
  end

  return {
    {
      role = "system",
      content = system_prompt,
    },
    {
      role = "user",
      content = text,
    },
  }
end

return M
