local M = {}

local matchers = require("schema-companion.matchers")
local schema = require("schema-companion.schema")

local log = require("schema-companion.log")

---@type { client: vim.lsp.Client, schema: schema_companion.Schema, executed: boolean}[]
M.ctx = {}
M.initialized_client_ids = {}

---@param bufnr number
---@param client vim.lsp.Client
---@return schema_companion.Schema | nil
function M.discover(bufnr, client)
  coroutine.resume(coroutine.create(function()
    if not M.ctx[bufnr] then
      log.error("bufnr=%d client_id=%d doesn't exists", bufnr, client.id)

      return
    elseif not M.initialized_client_ids[client.id] then
      log.debug("bufnr=%d client_id=%d is not yet initialized", bufnr, client.id)

      return
    elseif M.ctx[bufnr].executed then
      log.debug("bufnr=%d client_id=%d already executed", bufnr, client.id)

      return M.ctx[bufnr].schema
    end

    M.ctx[bufnr].executed = true

    local s = M.match(bufnr)
    log.debug("bufnr=%d client_id=%d autodiscover settled: %s", bufnr, client.id, s)
  end))
end

--- Matches a schema to the given buffer.
---@param bufnr number?
---@return schema_companion.Schema | nil
function M.match(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local current_schema = schema.current(bufnr)

  if current_schema and current_schema.name and current_schema.uri ~= schema.default_schema().uri then
    -- if LSP returns a name that means it came from SchemaStore
    -- and we can use it right away
    M.ctx[bufnr].schema = current_schema
    log.debug("bufnr=%d schema=%s an SchemaStore defined schema matched this file", bufnr, current_schema.name or current_schema.uri)

    return M.ctx[bufnr].schema
  end

  -- if it returned something without a name it means it came from our own
  -- internal schema table and we have to loop through it to get the name
  for _, option_schema in ipairs(schema.from_options()) do
    if current_schema and option_schema.uri == current_schema.uri then
      log.debug("bufnr=%d schema=%s an user defined schema matched this file", bufnr, option_schema.name)
      M.schema(bufnr, option_schema)

      return M.ctx[bufnr].schema
    end
  end

  log.debug("bufnr=%d no user defined schema matched this file", bufnr)

  -- if LSP is not using any schema, use registered matchers
  for _, matcher in ipairs(matchers.get()) do
    local result = matcher.match(bufnr)
    if result then
      log.debug("bufnr=%d schema=%s a registered matcher matched this file", bufnr, result.name)
      M.schema(bufnr, result)

      return M.ctx[bufnr].schema
    end

    log.debug("bufnr=%d no registered matcher matched this file", bufnr)
  end

  -- No schema matched
  log.debug("bufnr=%d no registered schema matches", bufnr)
end

--- gets or sets the schema in its context and lsp
---@param bufnr number
---@param data schema_companion.Schema | schema_companion.Schema[] | nil
---@return schema_companion.Schema
function M.schema(bufnr, data)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if M.ctx[bufnr] == nil then
    return schema.default_schema()
  end

  if data and data.uri and data.name then
    M.ctx[bufnr].schema = data

    local bufuri = vim.uri_from_bufnr(bufnr)
    local client = M.ctx[bufnr].client

    local override = {}

    local schemas = {}
    if client.settings and client.settings.yaml and client.settings.yaml.schemas then
      schemas = client.settings.yaml.schemas
    end

    for u, b in pairs(schemas) do
      if b == bufuri then
        override[u] = false
        log.debug("removed override: file=%s schema=%s", b, u)
      end
    end

    override[data.uri] = bufuri

    log.debug("set new override: file=%s schema=%s", bufuri, data.uri)

    client.settings = vim.tbl_deep_extend("force", client.settings, { yaml = { schemas = override } })
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end

  return M.ctx[bufnr].schema
end

--- Set the schema used for a buffer.
---@param bufnr? number: Buffer number
---@param s schema_companion.Schema[] | schema_companion.Schema
function M.set_buffer_schema(bufnr, s)
  return M.schema(bufnr or vim.api.nvim_get_current_buf(), s)
end

--- Get the schema used for a buffer.
---@param bufnr number?: Buffer number
function M.get_buffer_schema(bufnr)
  return M.schema(bufnr or vim.api.nvim_get_current_buf())
end

---@param bufnr number
---@param client vim.lsp.Client
function M.setup(bufnr, client)
  local state = {
    client = client,
    schema = schema.default_schema(),
    executed = false,
  }

  M.ctx[bufnr] = state

  M.discover(bufnr, client)
end

return M
