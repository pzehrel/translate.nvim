test("custom llm client receives translation options", function()
  local received = nil
  local result = nil
  local config = require("translation.config").setup({
    target_language = "ja",
    llm = {
      translate = function(text, opts, callback)
        received = { text = text, language = opts.target_language }
        callback(nil, "翻訳")
      end,
    },
  })

  require("translation.llm").translate("hello", config, function(err, translated)
    assert(err == nil)
    result = translated
  end)

  assert(received.text == "hello")
  assert(received.language == "ja")
  assert(result == "翻訳")
end)

test("llm client reports missing endpoint and model", function()
  local message = nil
  local config = require("translation.config").setup({
    llm = {
      endpoint = "",
      model = "",
    },
  })

  require("translation.llm").translate("hello", config, function(err)
    message = err
  end)

  assert(message == "尚未配置 LLM endpoint 和 model")
end)
