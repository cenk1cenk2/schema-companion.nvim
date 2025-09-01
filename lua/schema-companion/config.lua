local M = {}

---@class schema_companion.Config
---@field log_level? number
---@field enable_telescope? boolean

---@type schema_companion.Config
local defaults = {
  log_level = vim.log.levels.INFO,
  enable_telescope = false,
}

---@type schema_companion.Config
---@diagnostic disable-next-line: missing-fields
M.options = {}

---@param config schema_companion.Config
---@return schema_companion.Config
function M.setup(config)
  M.options = vim.tbl_deep_extend("force", {}, defaults, config or {})

  return M.options
end

return M
