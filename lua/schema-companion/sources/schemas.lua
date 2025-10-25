---@class schema_companion.Source
local M = {}

local wrap = require("schema-companion.sources.metatable")

M.name = "Schemas"

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

local function apply(self, schemas)
  if schemas then
    self.config = enrich_schemas(schemas)
  end
end

function M:get_schemas()
  return self.config
end

return wrap(M, apply)
