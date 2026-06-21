---@class TranslationCacheModule
local M = {}

---@type table<string, TranslationCacheEntry>
local entries = {}
---@type table<string, table<string, boolean>>
local text_index = {}
---@type table<string, { callbacks: table<integer, TranslationCallback>, cancel: TranslationCancel? }>
local pending = {}
---@type TranslationCacheConfig?
local config = nil
local loaded = false
local next_callback_id = 0
---@type uv.uv_timer_t?
local write_timer = nil
local stats = {
  hits = 0,
  misses = 0,
  writes = 0,
  deletes = 0,
}

---@return integer
local function now()
  local seconds, microseconds = vim.uv.gettimeofday()
  return seconds * 1000 + math.floor(microseconds / 1000)
end

---@param value string
---@return string
local function hash(value)
  return vim.fn.sha256(value)
end

---@param entry TranslationCacheEntry
---@return boolean
local function expired(entry)
  return entry.expires_at <= now()
end

---@param key string
---@return nil
local function remove(key)
  local entry = entries[key]
  if not entry then
    return
  end
  entries[key] = nil
  local keys = text_index[entry.text_hash]
  if keys then
    keys[key] = nil
    if vim.tbl_isempty(keys) then
      text_index[entry.text_hash] = nil
    end
  end
end

---@param entry TranslationCacheEntry
---@return nil
local function index(entry)
  local keys = text_index[entry.text_hash] or {}
  keys[entry.key] = true
  text_index[entry.text_hash] = keys
end

---@return nil
local function prune()
  for key, entry in pairs(entries) do
    if expired(entry) then
      remove(key)
    end
  end

  local count = vim.tbl_count(entries)
  while config and count > config.max_entries do
    local oldest_key = nil
    local oldest_access = math.huge
    for key, entry in pairs(entries) do
      if entry.accessed_at < oldest_access then
        oldest_key = key
        oldest_access = entry.accessed_at
      end
    end
    if not oldest_key then
      break
    end
    remove(oldest_key)
    count = count - 1
  end
end

---@return nil
local function write_disk()
  if not config or not config.persistence then
    return
  end

  prune()
  local list = {}
  for _, entry in pairs(entries) do
    table.insert(list, entry)
  end

  local directory = vim.fn.fnamemodify(config.path, ":h")
  vim.fn.mkdir(directory, "p")
  local temporary = config.path .. ".tmp"
  local file = io.open(temporary, "w")
  if not file then
    return
  end
  file:write(vim.json.encode({ version = 1, entries = list }))
  file:close()
  os.rename(temporary, config.path)
end

---@return nil
local function schedule_write()
  if not config or not config.persistence then
    return
  end
  if write_timer then
    write_timer:stop()
    write_timer:close()
  end
  write_timer = vim.uv.new_timer()
  if not write_timer then
    return
  end
  write_timer:start(
    config.debounce,
    0,
    vim.schedule_wrap(function()
      write_timer:stop()
      write_timer:close()
      write_timer = nil
      write_disk()
    end)
  )
end

---@return nil
local function load_disk()
  if loaded or not config or not config.persistence then
    return
  end
  loaded = true
  local file = io.open(config.path, "r")
  if not file then
    return
  end
  local content = file:read("*a")
  file:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" or decoded.version ~= 1 then
    return
  end
  ---@cast decoded TranslationPersistentCache
  for _, entry in ipairs(decoded.entries or {}) do
    if not expired(entry) then
      entries[entry.key] = entry
      index(entry)
    end
  end
  prune()
end

---@param opts TranslationCacheConfig
---@return nil
function M.setup(opts)
  config = opts
  loaded = false
  if opts.enabled then
    load_disk()
  end
end

---@param text string
---@return TranslationPromptCacheContext
function M.context(text)
  if not config or not config.enabled then
    return { hit = false }
  end
  load_disk()
  local text_hash = hash(text)
  local keys = text_index[text_hash]
  local newest = nil
  for key in pairs(keys or {}) do
    local entry = entries[key]
    if entry and not expired(entry) then
      if not newest or entry.accessed_at > newest.accessed_at then
        newest = entry
      end
    else
      remove(key)
    end
  end
  if not newest then
    return { hit = false }
  end
  newest.accessed_at = now()
  return {
    hit = true,
    translation = newest.translated,
  }
end

---@param text string
---@param messages TranslationChatMessage[]
---@param opts TranslationConfig
---@return string
function M.key(text, messages, opts)
  return hash(vim.json.encode({
    endpoint = opts.llm.endpoint,
    model = opts.llm.model,
    messages = messages,
    target_language = opts.target_language,
    text_hash = hash(text),
  }))
end

---@param key string
---@return string?
function M.get(key)
  if not config or not config.enabled then
    return nil
  end
  load_disk()
  local entry = entries[key]
  if not entry or expired(entry) then
    if entry then
      remove(key)
    end
    stats.misses = stats.misses + 1
    return nil
  end
  entry.accessed_at = now()
  stats.hits = stats.hits + 1
  return entry.translated
end

---@param key string
---@param text string
---@param translated string
---@return nil
function M.set(key, text, translated)
  if not config or not config.enabled then
    return
  end
  local timestamp = now()
  entries[key] = {
    key = key,
    text_hash = hash(text),
    translated = translated,
    created_at = timestamp,
    accessed_at = timestamp,
    expires_at = timestamp + config.ttl,
  }
  index(entries[key])
  stats.writes = stats.writes + 1
  prune()
  schedule_write()
end

---@param key string
---@param producer fun(done: TranslationCallback): TranslationCancel?
---@param callback TranslationCallback
---@param opts? { bypass: boolean?, on_success: fun(translated: string)? }
---@return TranslationCancel?
function M.run(key, producer, callback, opts)
  opts = opts or {}
  if not config or not config.enabled then
    return producer(function(err, translated)
      if not err and translated and opts.on_success then
        opts.on_success(translated)
      end
      callback(err, translated)
    end)
  end

  if not opts.bypass then
    local cached = M.get(key)
    if cached then
      vim.schedule(function()
        callback(nil, cached)
      end)
      return nil
    end
  end

  local task = pending[key]
  next_callback_id = next_callback_id + 1
  local callback_id = next_callback_id
  if task and not opts.bypass then
    task.callbacks[callback_id] = callback
  else
    local previous = task
    task = { callbacks = {} }
    if previous and opts.bypass then
      for id, waiting in pairs(previous.callbacks) do
        task.callbacks[id] = waiting
      end
      if previous.cancel then
        previous.cancel()
      end
    end
    task.callbacks[callback_id] = callback
    pending[key] = task
    task.cancel = producer(function(err, translated)
      if pending[key] ~= task then
        return
      end
      local callbacks = task.callbacks
      pending[key] = nil
      if not err and translated and opts.on_success then
        opts.on_success(translated)
      end
      for _, waiting in pairs(callbacks) do
        waiting(err, translated)
      end
    end)
  end

  return function()
    local current = pending[key]
    if not current then
      return
    end
    current.callbacks[callback_id] = nil
    if vim.tbl_isempty(current.callbacks) then
      if current.cancel then
        current.cancel()
      end
      pending[key] = nil
    end
  end
end

---@param key string
---@return boolean
function M.delete_key(key)
  load_disk()
  if not entries[key] then
    return false
  end
  remove(key)
  stats.deletes = stats.deletes + 1
  schedule_write()
  return true
end

---@param text string
---@return integer deleted
function M.delete_text(text)
  load_disk()
  local keys = text_index[hash(text)]
  if not keys then
    return 0
  end
  local list = vim.tbl_keys(keys)
  for _, key in ipairs(list) do
    remove(key)
  end
  stats.deletes = stats.deletes + #list
  schedule_write()
  return #list
end

---@return nil
function M.clear()
  entries = {}
  text_index = {}
  if config and config.persistence then
    os.remove(config.path)
  end
end

---@return TranslationCacheStats
function M.stats()
  return {
    entries = vim.tbl_count(entries),
    pending = vim.tbl_count(pending),
    hits = stats.hits,
    misses = stats.misses,
    writes = stats.writes,
    deletes = stats.deletes,
  }
end

---@return nil
function M.flush()
  if write_timer then
    write_timer:stop()
    write_timer:close()
    write_timer = nil
  end
  write_disk()
end

return M
