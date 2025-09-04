local M = {
  ---format is client_id: adapter
  ---@type table<number, schema_companion.Adapter>
  ctx = {},
  helmls = require("schema-companion.adapters.helmls"),
  yamlls = require("schema-companion.adapters.yamlls"),
  jsonls = require("schema-companion.adapters.jsonls"),
}

local log = require("schema-companion.log")

--- Reads the adapter associated with a client.
---@param client_id number
---@return schema_companion.Adapter
function M.read(client_id)
  local adapter = M.ctx[client_id]

  if not adapter then
    error(("no adapter found: client_id=%d"):format(client_id))
  end

  log.debug("adapter found: client_id=%d adapter_name=%s", client_id, adapter.name)

  return adapter
end

--- Associates an adapter with a client.
---@param client_id number
---@param adapter schema_companion.Adapter
---@return schema_companion.Adapter
function M.write(client_id, adapter)
  if M.ctx[client_id] then
    log.debug("adapter already set: client_id=%d adapter_name=%s", client_id, M.ctx[client_id].name)

    return M.ctx[client_id]
  end

  M.ctx[client_id] = adapter

  log.debug("adapter registered: client_id=%d adapter_name=%s", client_id, adapter.name)

  return adapter
end

function M.delete(client_id)
  local adapter = M.ctx[client_id]

  if not adapter then
    log.debug("no adapter to delete: client_id=%d", client_id)
    return nil
  end

  M.ctx[client_id] = nil
  log.debug("adapter deleted: client_id=%d adapter_name=%s", client_id, adapter.name)

  return adapter
end

function M.has_initialized(client_id)
  return M.ctx[client_id] ~= nil
end

return M
