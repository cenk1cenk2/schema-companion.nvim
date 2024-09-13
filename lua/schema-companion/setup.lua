local M = {}

---@type schema_companion.Config
M.config = {
  log_level = vim.log.levels.INFO,
  enable_telescope = false,
  schemas = {},
  matchers = {},
}

---@param config schema_companion.Config
---@return schema_companion.Config
function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  return M.config
end

return M
