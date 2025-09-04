---@class schema_companion.Source
local M = {}

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

---
---@param schemas schema_companion.Schema[]
---@return schema_companion.Source
function M.setup(schemas)
  setmetatable(M, {})
  M.config = enrich_schemas(schemas)

  return M
end

function M:get_schemas()
  return self.config
end

return M
