---@type fun(name: string, fn: fun())
local test = assert(_G.test)

local cache = require("translate.cache")

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

  package.loaded["translate.cache"] = nil
  local reloaded = require("translate.cache")
  reloaded.setup(persistent_config)

  assert(reloaded.get("reload-key") == "reloaded translation")
  reloaded.clear()
  package.loaded["translate.cache"] = reloaded
  cache = reloaded
end)

test("deletes one exact cache key", function()
  cache.setup(config())
  cache.clear()
  cache.set("first-key", "same source", "first translation")
  cache.set("second-key", "same source", "second translation")

  assert(cache.delete_key("first-key") == true)
  assert(cache.get("first-key") == nil)
  assert(cache.get("second-key") == "second translation")
end)

test("deletes every cache variant for source text", function()
  cache.setup(config())
  cache.clear()
  cache.set("first-key", "same source", "first translation")
  cache.set("second-key", "same source", "second translation")
  cache.set("other-key", "other source", "other translation")

  assert(cache.delete_text("same source") == 2)
  assert(cache.get("first-key") == nil)
  assert(cache.get("second-key") == nil)
  assert(cache.get("other-key") == "other translation")
end)

test("bypass starts a new producer even when cache exists", function()
  cache.setup(config())
  cache.clear()
  cache.set("request-key", "source", "old translation")
  local calls = 0
  local translated = nil

  cache.run("request-key", function(done)
    calls = calls + 1
    done(nil, "new translation")
  end, function(_, value)
    translated = value
  end, { bypass = true })

  assert(calls == 1)
  assert(translated == "new translation")
end)

test("bypass supersedes an older pending request", function()
  cache.setup(config())
  cache.clear()
  local old_done = nil
  local new_done = nil
  local old_cancelled = false
  local results = {}

  cache.run("request-key", function(done)
    old_done = done
    return function()
      old_cancelled = true
    end
  end, function(_, translated)
    table.insert(results, translated)
  end)

  cache.run("request-key", function(done)
    new_done = done
  end, function(_, translated)
    table.insert(results, translated)
  end, { bypass = true })

  assert(old_cancelled == true)
  assert(old_done ~= nil)
  assert(new_done ~= nil)
  old_done(nil, "stale translation")
  assert(#results == 0)
  new_done(nil, "fresh translation")
  assert(#results == 2)
  assert(results[1] == "fresh translation")
  assert(results[2] == "fresh translation")
end)
