local M = {}

local log = require("schema-companion.log")

local sync_timeout = 5000

---@param bufnr number
---@param method string
---@return table | nil
function M.request_sync(bufnr, method)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  local result = {}

  for _, client in pairs(clients) do
    local response, error = client.request_sync(method, { vim.uri_from_bufnr(bufnr) }, sync_timeout, bufnr)

    if error then
      log.error("bufnr=%d error=%s", bufnr, error)
    elseif response and response.err then
      log.error("bufnr=%d error=%s", bufnr, response.err)
    elseif response and response.result then
      vim.list_extend(result, response.result)
    end
  end

  return result
end

-- get all known schemas by the yamlls attached to {bufnr}
---@param bufnr number
---@return schema_companion.Schema | nil
function M.get_all_schemas(bufnr)
  local response = M.request_sync(bufnr, "yaml/get/all/jsonSchemas")

  return response
end

-- Get matching schemas to current buffer.
---@param bufnr number
---@return schema_companion.Schema[] | nil
function M.get_schemas(bufnr)
  local response = M.request_sync(bufnr, "yaml/get/jsonSchema")

  return response
end

-- get schema used for {bufnr} from the yamlls attached to it
---@param bufnr number
---@return schema_companion.Schema | nil
function M.get_schema(bufnr)
  local response = M.get_schemas(bufnr)

  if response and response[1] then
    return response[1]
  end
end

function M.store_initialized(_, _, req, _)
  local client_id = req.client_id

  require("schema-companion.context").initialized_client_ids[client_id] = true

  local client = vim.lsp.get_client_by_id(client_id)

  if not client then
    error(("LSP Client is not available anymore: %d"):format(client_id))
  end

  local buffers = vim.lsp.get_buffers_by_client_id(client_id)

  for _, bufnr in ipairs(buffers) do
    log.debug("client_id=%s bufnr=%d running autodiscover", client_id, bufnr)

    require("schema-companion.context").discover(bufnr, client)
  end
end

return M
