---@type fun(name: string, fn: fun())
local test = assert(_G.test)

local prompt = require("translate.prompt")

test("uses default system prompt with target language", function()
  local messages = assert(prompt.messages("hello", {
    target_language = "zh-CN",
    llm = {},
  }))

  assert(messages[1].role == "system")
  assert(messages[1].content:find("zh%-CN") ~= nil)
  assert(messages[2].content == "hello")
end)

test("accepts custom system prompt string", function()
  local messages = assert(prompt.messages("hello", {
    target_language = "zh-CN",
    llm = {
      system_prompt = "Custom translator prompt",
    },
  }))

  assert(messages[1].content == "Custom translator prompt")
end)

test("accepts dynamic system prompt function", function()
  ---@type TranslatePromptContext?
  local received = nil
  local messages = assert(prompt.messages("hover text", {
    target_language = "ja",
    llm = {
      system_prompt = function(context)
        received = context
        return "Translate to " .. context.target_language
      end,
    },
  }, {
    file_path = "/workspace/src/example.ts",
    extension = "ts",
  }))

  assert(received ~= nil)
  assert(received.text == "hover text")
  assert(received.target_language == "ja")
  assert(received.file_path == "/workspace/src/example.ts")
  assert(received.extension == "ts")
  assert(messages[1].content == "Translate to ja")
end)

test("uses empty file context when source is unavailable", function()
  ---@type TranslatePromptContext?
  local received = nil
  assert(prompt.messages("hover text", {
    target_language = "zh-CN",
    llm = {
      system_prompt = function(context)
        received = context
        return "translate"
      end,
    },
  }))

  assert(received ~= nil)
  assert(received.file_path == "")
  assert(received.extension == "")
end)

test("exposes current text cache to dynamic system prompt", function()
  ---@type TranslatePromptContext?
  local received = nil
  assert(prompt.messages("hover text", {
    target_language = "zh-CN",
    llm = {
      system_prompt = function(context)
        received = context
        return "translate"
      end,
    },
  }, {
    cache = {
      hit = true,
      translation = "缓存译文",
    },
  }))

  assert(received ~= nil)
  assert(received.cache.hit == true)
  assert(received.cache.translation == "缓存译文")
end)

test("reports invalid dynamic system prompt", function()
  local invalid_prompt = function()
    return nil
  end
  ---@cast invalid_prompt any

  local messages, err = prompt.messages("hello", {
    target_language = "zh-CN",
    llm = {
      system_prompt = invalid_prompt,
    },
  })

  assert(messages == nil)
  assert(err == "llm.system_prompt callback must return a non-empty string")
end)
