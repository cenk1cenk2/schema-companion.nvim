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

-- taken from require("lspconfig.util").add_hook_after to drop dependency
---@param func function | any
---@param new_fn function | any
function M.add_hook_after(func, new_fn)
  if func then
    return function(...)
      func(...)
      return new_fn(...)
    end
  else
    return new_fn
  end
end

--- Evalautes the property and returns the result.
---@param property function | any
---@return any
function M.evaluate_property(property, ...)
  if type(property) == "function" then
    return property(...)
  end

  return property
end

return M
