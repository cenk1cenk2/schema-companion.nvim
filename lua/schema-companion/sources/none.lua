---@class schema_companion.Source
local M = {}

local wrap = require("schema-companion.sources.metatable")

M.name = "None"

M.config = {}

---@param schemas schema_companion.Schema[]
---@return schema_companion.Schema[]
local function enrich_schemas(schemas)
  for _, schema in ipairs(schemas) do
    if schema.source then
      schema.source = ("%s/%s"):format(M.name, schema.source)
    else
      schema.source = M.name
    end
  end
  return schemas
end

function M:get_schemas()
  return enrich_schemas(require("schema-companion.schema").get_default_schemas())
end

return wrap(M)
