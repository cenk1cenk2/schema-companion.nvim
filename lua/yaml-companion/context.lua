local M = {}

local matchers = require("yaml-companion.matchers")
local schema = require("yaml-companion.schema")

local log = require("yaml-companion.log")

---@type { client: vim.lsp.client, schema: Schema, executed: boolean}[]
M.ctxs = {}
M.initialized_client_ids = {}

---@param bufnr number
---@param client vim.lsp.client
---@return SchemaResult | nil
function M.autodiscover(bufnr, client)
  if not M.ctxs[bufnr] then
    log.error("bufnr=%d client_id=%d doesn't exists", bufnr, client.id)
    return
  end

  if not M.initialized_client_ids[client.id] then
    log.debug("bufnr=%d client_id=%d is not yet initialized", bufnr, client.id)
    return
  end

  if M.ctxs[bufnr].executed then
    log.debug("bufnr=%d client_id=%d already executed", bufnr, client.id)
    return M.ctxs[bufnr].schema
  end

  M.ctxs[bufnr].executed = true
  local current_schema = schema.current(bufnr)

  -- if LSP returns a name that means it came from SchemaStore
  -- and we can use it right away
  if current_schema.name and current_schema.uri ~= schema.default_schema().uri then
    M.ctxs[bufnr].schema = current_schema
    log.debug("bufnr=%d client_id=%d schema=%s an SchemaStore defined schema matched this file", bufnr, client.id, current_schema.name or current_schema.uri)
    return M.ctxs[bufnr].schema

    -- if it returned something without a name it means it came from our own
    -- internal schema table and we have to loop through it to get the name
  else
    for _, option_schema in ipairs(schema.from_options()) do
      if option_schema.uri == current_schema.uri then
        M.ctxs[bufnr].schema = option_schema
        log.debug("bufnr=%d client_id=%d schema=%s an user defined schema matched this file", bufnr, client.id, option_schema.name)
        return M.ctxs[bufnr].schema
      end
    end
    log.debug("bufnr=%d client_id=%d no user defined schema matched this file", bufnr, client.id)
  end

  -- if LSP is not using any schema, use registered matchers
  for _, matcher in ipairs(matchers.get()) do
    local result = matcher.match(bufnr)
    if result then
      M.schema(bufnr, result)
      log.debug("bufnr=%d client_id=%d schema=%s a registered matcher matched this file", bufnr, client.id, result.name)
      return M.ctxs[bufnr].schema
    end

    log.debug("bufnr=%d client_id=%d no registered matcher matched this file", bufnr, client.id)
  end

  -- No schema matched
  log.debug("bufnr=%d client_id=%d no registered schema matches", bufnr, client.id)

  return {}
end

---@param bufnr number
---@param client vim.lsp.client
function M.setup(bufnr, client)
  -- The server does support formatting but it is disabled by default
  -- https://github.com/redhat-developer/yaml-language-server/issues/486
  if require("yaml-companion").config.formatting then
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
  end

  local state = {
    client = client,
    schema = schema.default_schema(),
    executed = false,
  }

  M.ctxs[bufnr] = state

  -- The first time this won't work because the client is not initialized yet
  -- but it will be called once per client from the initialized_handler when it is.
  M.autodiscover(bufnr, client)
end

--- gets or sets the schema in its context and lsp
---@param bufnr number
---@param data Schema | SchemaResult | nil
---@return Schema
function M.schema(bufnr, data)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if M.ctxs[bufnr] == nil then
    return schema.default_schema()
  end

  if data and data.uri and data.name then
    M.ctxs[bufnr].schema = data

    local bufuri = vim.uri_from_bufnr(bufnr)
    local client = M.ctxs[bufnr].client
    local settings = client.settings

    -- we don't want more than 1 schema per file
    for key, _ in ipairs(settings.yaml.schemas) do
      if settings.yaml.schemas[key] == bufuri then
        settings.yaml.schemas[key] = nil
      end
    end

    local override = {}
    override[data.uri] = bufuri

    log.debug("file=%s schema=%s set new override", bufuri, data.uri)

    settings = vim.tbl_deep_extend("force", settings, { yaml = { schemas = override } })
    client.settings = vim.tbl_deep_extend("force", settings, { yaml = { schemas = override } })
    client.workspace_did_change_configuration(client.settings)
  end

  return M.ctxs[bufnr].schema
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param schema SchemaResult | Schema
function M.set_buffer_schema(bufnr, s)
  return M.schema(bufnr, s)
end

--- Get the schema used for a buffer.
---@param bufnr number: Buffer number
function M.get_buffer_schema(bufnr)
  return M.schema(bufnr)
end

return M
