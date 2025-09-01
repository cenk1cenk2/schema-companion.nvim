local M = {}

local log = require("schema-companion.log")

local sync_timeout = 5000

---@param client vim.lsp.Client
---@param method string
---@param bufnr? number
---@return table | nil
function M.request_sync(client, method, bufnr)
  bufnr = bufnr or 0

  local response, error = client:request_sync(method, { vim.uri_from_bufnr(bufnr) }, sync_timeout, bufnr)

  if error then
    log.debug("failed LSP request: method=%s client=%s bufnr=%d error=%s", client.name, bufnr, error)
  elseif response and response.err then
    log.debug("failed LSP request: method=%s client=%s bufnr=%d error=%s", method, client.name, bufnr, response.err)
  elseif response and response.result then
    return response.result
  end

  return nil
end

--- Handler for the "initialized" LSP notification.
---
---@param client_id number
---@param adapter schema_companion.Adapter
---@return nil
function M.on_store_initialized(client_id, adapter)
  local client = vim.lsp.get_client_by_id(client_id)

  if not client then
    error(("LSP Client is not available anymore: %d"):format(client_id))
  end

  require("schema-companion.adapters").write(client_id, adapter)

  local buffers = vim.lsp.get_buffers_by_client_id(client_id)

  for _, bufnr in ipairs(buffers) do
    log.debug("client_id=%s bufnr=%d running autodiscover", client_id, bufnr)

    require("schema-companion.context").discover(bufnr, client)
  end
end

function M.has_store_initialized(client_id)
  return vim.tbl_contains(vim.tbl_keys(require("schema-companion.adapters").ctx), client_id)
end

return M
