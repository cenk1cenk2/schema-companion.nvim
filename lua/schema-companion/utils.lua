local M = {}

local curl = require("plenary.curl")
local log = require("schema-companion.log")

--- Ensures the URI exists and returns the value accordingly.
---@param uri string
---@param schema schema_companion.Schema
---@return schema_companion.Schema | nil
function M.ensure_and_return(uri, schema)
  log.debug("Ensuring schema exists: uri=%s", uri)
  local result = curl.head(uri)

  if result.status ~= 200 then
    log.debug("Schema does not exist on remote: uri=%s", uri)
    return nil
  end

  return vim.tbl_extend("force", { uri = uri }, schema)
end

return M
