local M = {
  -- format of the identifier should be bufnr: client_id: context
  ---@type table<number, table<number, schema_companion.Context>>
  ctx = {},
}

local schema = require("schema-companion.schema")
local log = require("schema-companion.log")

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
function M.delete_buffer_context(bufnr)
  if M.ctx[bufnr] then
    M.ctx[bufnr] = nil
    log.debug("buffer context deleted: bufnr=%d", bufnr)
  else
    log.debug("no context to delete for buffer: bufnr=%d", bufnr)
  end
end

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

  log.debug("updated context: bufnr=%d client_id=%d", bufnr, client_id)

  return M.ctx[bufnr][client_id]
end

---@param bufnr number
---@param client_id number
function M.delete(bufnr, client_id)
  if M.ctx[bufnr] and M.ctx[bufnr][client_id] then
    M.ctx[bufnr][client_id] = nil
    log.debug("buffer context deleted: bufnr=%d client_id=%d", bufnr, client_id)
  else
    log.debug("no context to delete for buffer: bufnr=%d client_id=%d", bufnr, client_id)
  end
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
    xpcall(function()
      if not M.read(bufnr, client.id) then
        log.error("context doesn't exist: bufnr=%d client_id=%d", bufnr, client.id)

        return
      elseif not require("schema-companion.lsp").has_store_initialized(client.id) then
        log.debug("context not yet initialized: bufnr=%d client_id=%d", bufnr, client.id)

        return
      elseif M.had_discovered(bufnr, client.id) then
        log.debug("already discovered: bufnr=%d client_id=%d", bufnr, client.id)

        return M.read(bufnr, client.id)
      end

      M.write(bufnr, client.id, { _discovered = true })

      local schemas = require("schema-companion.schema").match(bufnr)
      log.debug("autodiscover settled: bufnr=%d client_id=%d schemas=%s", bufnr, client.id, schemas)
    end, debug.traceback)
  end))
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param client_id number
---@return schema_companion.Schema[] | nil
function M.get_schemas(bufnr, client_id)
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
function M.set_schemas(bufnr, client_id, schemas)
  if not M.read(bufnr, client_id) then
    log:error("no adapter found for the given buffer and client id yet: bufnr=%s client_id=%s", bufnr, client_id)

    return
  end

  local ctx = M.write(bufnr, client_id, { schemas = schemas })

  ctx.adapter:on_update_schemas(bufnr, schemas)

  return ctx.schemas
end

---@param bufnr number
---@param adapter schema_companion.Adapter
function M.setup(bufnr, adapter)
  local client_id = adapter:get_client().id
  log.debug("setting up context: adapter_name=%s bufnr: %d client_id: %d", adapter.name, bufnr, client_id)

  local augroup = vim.api.nvim_create_augroup("schema-companion-context", { clear = false })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    group = augroup,
    callback = function(e)
      M.delete_buffer_context(e.buf)
    end,
  })

  M.write(bufnr, client_id, {
    adapter = adapter,
    schemas = schema.get_default_schemas(),
    _discovered = false,
  })

  M.discover(bufnr, adapter:get_client())
end

return M
