---@class schema_companion.Source
local M = {}

M.name = "schemas"

M.config = {}

---
---@param config schema_companion.Schema[]
---@return schema_companion.Source
function M.setup(config)
  setmetatable(M, {})
  M.config = config

  return M
end

function M:get_schemas()
  return self.config
end

return M
