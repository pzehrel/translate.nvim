local M = {}

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

function M.messages(text, opts)
  local system_prompt, err = M.resolve_system_prompt(opts.llm.system_prompt, {
    target_language = opts.target_language,
    text = text,
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
