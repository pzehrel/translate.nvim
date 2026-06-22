---@class TranslateLlmModule
local M = {}

---@param llm TranslateLlmConfig|TranslateLlmOptions
---@return string?
function M.resolve_api_key(llm)
  local api_key = llm.api_key
  if type(api_key) == "function" then
    local ok, value = pcall(api_key)
    if ok and value and value ~= "" then
      return value
    end
  elseif type(api_key) == "string" and api_key ~= "" then
    return api_key
  end

  if type(llm.api_key_env) == "string" and llm.api_key_env ~= "" then
    local value = vim.env[llm.api_key_env]
    if value and value ~= "" then
      return value
    end
  end

  return nil
end

---@param fn TranslateCustomTranslate
---@param text string
---@param opts TranslateConfig
---@param callback TranslateCallback
---@return TranslateCancel?
local function custom_translate(fn, text, opts, callback)
  local ok, cancel_or_error = pcall(fn, text, opts, callback)
  if not ok then
    callback(tostring(cancel_or_error))
    return nil
  end
  return cancel_or_error
end

---@param stdout string
---@return string? content
---@return string? error
local function parse_response(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    return nil, "LLM returned invalid JSON"
  end

  ---@cast decoded TranslateOpenAiResponse
  local choice = decoded.choices and decoded.choices[1]
  local content = choice and choice.message and choice.message.content
  if type(content) ~= "string" or content == "" then
    return nil, "LLM returned empty content"
  end

  return content
end

---@param text string
---@param opts TranslateConfig
---@param callback TranslateCallback
---@param source_context? TranslateSourceContext
---@return TranslateCancel?
function M.translate(text, opts, callback, source_context)
  local llm = opts.llm
  local cache = require("translate.cache")
  source_context = vim.tbl_extend("force", source_context or {}, {
    cache = cache.context(text),
  })
  local messages, prompt_err = require("translate.prompt").messages(text, opts, source_context)
  if not messages then
    callback(("System Prompt configuration error: %s"):format(prompt_err))
    return nil
  end
  local cache_key = cache.key(text, messages, opts)

  return cache.run(
    cache_key,
    function(done)
      if type(llm.translate) == "function" then
        return custom_translate(llm.translate, text, opts, done)
      end

      if llm.endpoint == "" or llm.model == "" then
        done("LLM endpoint and model not yet configured")
        return nil
      end

      ---@type string[]
      local headers = {
        "Content-Type: application/json",
      }
      local api_key = M.resolve_api_key(llm)
      if api_key and api_key ~= "" then
        table.insert(headers, "Authorization: Bearer " .. api_key)
      end
      for name, value in pairs(llm.headers or {}) do
        table.insert(headers, ("%s: %s"):format(name, value))
      end

      local body = vim.json.encode({
        model = llm.model,
        messages = messages,
        stream = false,
      })

      ---@type string[]
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
            done(("LLM request failed: %s"):format(vim.trim(result.stderr or "")))
            return
          end

          local content, err = parse_response(result.stdout or "")
          done(err, content)
        end)
      end)

      return function()
        if process then
          pcall(process.kill, process, 15)
        end
      end
    end,
    callback,
    {
      bypass = source_context.bypass_cache == true,
      on_success = function(translated)
        cache.set(cache_key, text, translated)
      end,
    }
  )
end

return M
