---@type fun(name: string, fn: fun())
local test = assert(_G.test)

test("custom llm client receives translation options", function()
  ---@type { text: string, language: string }?
  local received = nil
  ---@type string?
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

  assert(received ~= nil)
  assert(received.text == "hello")
  assert(received.language == "ja")
  assert(result == "翻訳")
end)

test("llm client reports missing endpoint and model", function()
  ---@type string?
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

test("api key is read from configured environment variable", function()
  local previous = vim.env.TRANSLATION_NVIM_TEST_KEY
  vim.env.TRANSLATION_NVIM_TEST_KEY = "secret-from-env"

  local value = require("translation.llm").resolve_api_key({
    api_key = nil,
    api_key_env = "TRANSLATION_NVIM_TEST_KEY",
  })

  vim.env.TRANSLATION_NVIM_TEST_KEY = previous
  assert(value == "secret-from-env")
end)

test("explicit api key takes precedence over environment variable", function()
  local previous = vim.env.TRANSLATION_NVIM_TEST_KEY
  vim.env.TRANSLATION_NVIM_TEST_KEY = "secret-from-env"

  local value = require("translation.llm").resolve_api_key({
    api_key = "explicit-secret",
    api_key_env = "TRANSLATION_NVIM_TEST_KEY",
  })

  vim.env.TRANSLATION_NVIM_TEST_KEY = previous
  assert(value == "explicit-secret")
end)
