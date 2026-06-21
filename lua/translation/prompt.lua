local M = {}

function M.messages(text, target_language)
  return {
    {
      role = "system",
      content = table.concat({
        "You translate software documentation.",
        "Translate only natural-language prose into " .. target_language .. ".",
        "Preserve Markdown structure exactly.",
        "Do not translate or duplicate fenced code blocks, type signatures, inline code, URLs,",
        "symbol names, identifiers, or link targets.",
        "Return only the translated Markdown.",
      }, " "),
    },
    {
      role = "user",
      content = text,
    },
  }
end

return M
