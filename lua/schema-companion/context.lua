local M = {
  -- format of the identifier should be bufnr: client_id: context
  ---@type table<number, table<number, schema_companion.Context>>
  ctx = {},
}

local schema = require("schema-companion.schema")
local log = require("schema-companion.log")

---@param bufnr number
---@param client_id number
---@return schema_companion.Context | nil
function M.read(bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if M.ctx[bufnr] == nil then
    return nil
  end

  return M.ctx[bufnr][client_id]
end

---
---@param bufnr number
---@return table<number, schema_companion.Context>
function M.read_buffer_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if M.ctx[bufnr] == nil then
    return {}
  end

  return M.ctx[bufnr]
end

---@param bufnr number
---@param client_id number
---@param context schema_companion.Context
---@return schema_companion.Context
function M.write(bufnr, client_id, context)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if M.ctx[bufnr] == nil then
    M.ctx[bufnr] = {}
  end

  M.ctx[bufnr][client_id] = vim.tbl_extend("force", M.ctx[bufnr][client_id] or {}, context)

  return M.ctx[bufnr][client_id]
end

---
---@param bufnr number
---@param client_id number
---@return boolean
function M.had_discovered(bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if M.ctx[bufnr] == nil then
    return false
  elseif M.ctx[bufnr][client_id] == nil then
    return false
  end

  return M.ctx[bufnr][client_id]._discovered or false
end

---@param bufnr number
---@param client vim.lsp.Client
---@return nil
function M.discover(bufnr, client)
  coroutine.resume(coroutine.create(function()
    if not M.read(bufnr, client.id) then
      log.error("bufnr=%d client_id=%d doesn't exist", bufnr, client.id)

      return
    elseif not require("schema-companion.lsp").has_store_initialized(client.id) then
      log.debug("bufnr=%d client_id=%d is not yet initialized", bufnr, client.id)

      return
    elseif M.had_discovered(bufnr, client.id) then
      log.debug("bufnr=%d client_id=%d already executed", bufnr, client.id)

      return M.read(bufnr, client.id)
    end

    M.write(bufnr, client.id, { _discovered = true })

    local s = M.match(bufnr)
    log.debug("bufnr=%d client_id=%d autodiscover settled: %s", bufnr, client.id, s)
  end))
end

--- Matches a schema to the given buffer.
---@param bufnr number?
---@return schema_companion.Schema[] | nil
function M.match(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ctxs = M.read_buffer_context(bufnr)

  for client_id, ctx in pairs(ctxs) do
    local schemas = {}

    for _, source in pairs(ctx.adapter:get_sources()) do
      local matches = source.match(ctx, bufnr)

      if matches and #matches > 0 then
        log.debug("bufnr=%d client_id=%d adapter_name=%s schema matched this file: %d", bufnr, client_id, ctx.adapter.name, #matches)
      end

      schemas = vim.list_extend(schemas, matches)
    end

    M.set_ctx_schemas(bufnr, client_id, schemas)
  end
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param client_id number
---@return schema_companion.Schema[] | nil
function M.get_ctx_schemas(bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ctx = M.read(bufnr, client_id)

  if not ctx then
    return nil
  end

  return ctx.schemas
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param client_id number
---@param schemas schema_companion.Schema[]
function M.set_ctx_schemas(bufnr, client_id, schemas)
  bufnr = bufnr or 0

  local ctx = M.write(bufnr, client_id, { schemas = schemas })

  ctx.adapter:on_update_schemas(bufnr, schemas)

  return ctx.schemas
end

---@param bufnr number
---@param adapter schema_companion.Adapter
function M.setup(bufnr, adapter)
  M.write(bufnr, adapter:get_client().id, {
    adapter = adapter,
    schemas = schema.get_default_schemas(),
    _discovered = false,
  })

  M.discover(bufnr, adapter:get_client())
end

return M
