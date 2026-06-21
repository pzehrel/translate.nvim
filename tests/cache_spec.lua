---@type fun(name: string, fn: fun())
local test = assert(_G.test)

local cache = require("translation.cache")

local function config(overrides)
  return vim.tbl_deep_extend("force", {
    enabled = true,
    max_entries = 10,
    ttl = 60000,
    persistence = false,
    path = vim.fn.tempname(),
    debounce = 10,
  }, overrides or {})
end

test("caches successful translations by key", function()
  cache.setup(config())
  cache.clear()
  cache.set("request-key", "source text", "translated text")

  assert(cache.get("request-key") == "translated text")
  local context = cache.context("source text")
  assert(context.hit == true)
  assert(context.translation == "translated text")
end)

test("deduplicates pending translation requests", function()
  cache.setup(config())
  cache.clear()
  local producer_calls = 0
  local done = nil
  local results = {}

  local function producer(callback)
    producer_calls = producer_calls + 1
    done = callback
  end

  cache.run("shared-key", producer, function(_, translated)
    table.insert(results, translated)
  end)
  cache.run("shared-key", producer, function(_, translated)
    table.insert(results, translated)
  end)

  assert(producer_calls == 1)
  assert(done ~= nil)
  done(nil, "shared translation")
  assert(#results == 2)
end)

test("persists only hashed metadata and translation", function()
  local path = vim.fn.tempname()
  cache.setup(config({
    persistence = true,
    path = path,
  }))
  cache.clear()
  cache.set("persistent-key", "sensitive source", "safe translation")
  cache.flush()

  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  os.remove(path)

  assert(content:find("safe translation", 1, true) ~= nil)
  assert(content:find("sensitive source", 1, true) == nil)
end)

test("reloads persisted translations in a fresh cache module", function()
  local path = vim.fn.tempname()
  local persistent_config = config({
    persistence = true,
    path = path,
  })
  cache.setup(persistent_config)
  cache.clear()
  cache.set("reload-key", "source", "reloaded translation")
  cache.flush()

  package.loaded["translation.cache"] = nil
  local reloaded = require("translation.cache")
  reloaded.setup(persistent_config)

  assert(reloaded.get("reload-key") == "reloaded translation")
  reloaded.clear()
  package.loaded["translation.cache"] = reloaded
  cache = reloaded
end)
