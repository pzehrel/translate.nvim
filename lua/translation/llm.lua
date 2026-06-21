local M = {}

local function resolve_api_key(api_key)
  if type(api_key) == "function" then
    local ok, value = pcall(api_key)
    return ok and value or nil
  end
  return api_key
end

local function custom_translate(fn, text, opts, callback)
  local ok, cancel_or_error = pcall(fn, text, opts, callback)
  if not ok then
    callback(tostring(cancel_or_error))
    return nil
  end
  return cancel_or_error
end

local function parse_response(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    return nil, "LLM 返回了无效 JSON"
  end

  local choice = decoded.choices and decoded.choices[1]
  local content = choice and choice.message and choice.message.content
  if type(content) ~= "string" or content == "" then
    return nil, "LLM 返回内容为空"
  end

  return content
end

function M.translate(text, opts, callback)
  local llm = opts.llm
  if type(llm.translate) == "function" then
    return custom_translate(llm.translate, text, opts, callback)
  end

  if llm.endpoint == "" or llm.model == "" then
    callback("尚未配置 LLM endpoint 和 model")
    return nil
  end

  local headers = {
    "Content-Type: application/json",
  }
  local api_key = resolve_api_key(llm.api_key)
  if api_key and api_key ~= "" then
    table.insert(headers, "Authorization: Bearer " .. api_key)
  end
  for name, value in pairs(llm.headers or {}) do
    table.insert(headers, ("%s: %s"):format(name, value))
  end

  local body = vim.json.encode({
    model = llm.model,
    messages = require("translation.prompt").messages(text, opts.target_language),
    stream = false,
  })

  local command = {
    llm.curl,
    "--silent",
    "--show-error",
    "--fail-with-body",
    "--max-time",
    tostring(math.max(1, math.ceil(llm.timeout / 1000))),
  }
  for _, header in ipairs(headers) do
    vim.list_extend(command, { "-H", header })
  end
  vim.list_extend(command, { "-d", body, llm.endpoint })

  local process = vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(("LLM 请求失败：%s"):format(vim.trim(result.stderr or "")))
        return
      end

      local content, err = parse_response(result.stdout or "")
      callback(err, content)
    end)
  end)

  return function()
    if process then
      pcall(process.kill, process, 15)
    end
  end
end

return M
