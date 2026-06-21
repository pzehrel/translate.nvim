local prompt = require("translation.prompt")

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
  local received = nil
  local messages = assert(prompt.messages("hover text", {
    target_language = "ja",
    llm = {
      system_prompt = function(context)
        received = context
        return "Translate to " .. context.target_language
      end,
    },
  }))

  assert(received.text == "hover text")
  assert(received.target_language == "ja")
  assert(messages[1].content == "Translate to ja")
end)

test("reports invalid dynamic system prompt", function()
  local messages, err = prompt.messages("hello", {
    target_language = "zh-CN",
    llm = {
      system_prompt = function()
        return nil
      end,
    },
  })

  assert(messages == nil)
  assert(err == "llm.system_prompt 回调必须返回非空字符串")
end)
