local M = {}

local function append(target, value)
  if type(value) == "string" then
    if value ~= "" then
      table.insert(target, value)
    end
    return
  end

  if type(value) ~= "table" then
    return
  end

  if value.kind and value.value then
    append(target, value.value)
    return
  end

  if value.language and value.value then
    table.insert(target, ("```%s\n%s\n```"):format(value.language, value.value))
    return
  end

  if value.value then
    append(target, value.value)
    return
  end

  for _, item in ipairs(value) do
    append(target, item)
  end
end

function M.normalize(contents)
  local parts = {}
  append(parts, contents)
  return table.concat(parts, "\n\n")
end

function M.collect(responses)
  local seen = {}
  local values = {}

  for _, response in pairs(responses or {}) do
    local result = response.result or response
    local text = result and M.normalize(result.contents)
    if text and text ~= "" and not seen[text] then
      seen[text] = true
      table.insert(values, text)
    end
  end

  table.sort(values)
  return table.concat(values, "\n\n---\n\n")
end

return M
