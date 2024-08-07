local M = {}

local request_sync = require("yaml-companion.lsp.util").request_sync

-- get all known schemas by the yamlls attached to {bufnr}
---@param bufnr number
---@return SchemaResult | nil
function M.get_all_jsonschemas(bufnr)
  local response = request_sync(bufnr, "yaml/get/all/jsonSchemas")

  return response
end

-- get schema used for {bufnr} from the yamlls attached to it
---@param bufnr number
---@return SchemaResult | nil
function M.get_jsonschema(bufnr)
  local response = request_sync(bufnr, "yaml/get/jsonSchema")

  if response and response[1] then
    return response[1]
  end
end

return M
