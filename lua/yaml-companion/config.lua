local M = {}

---@type ConfigOptions
M.config = {
  log_level = "info",
  formatting = true,
  matchers = {},
  schemas = {},
}

---
---@param config ConfigOptions
---@return ConfigOptions
function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  local log = require("yaml-companion.log").new({ level = M.config.log_level }, true)

  for _, matcher in ipairs(M.config.matchers) do
    require("yaml-companion.matchers").register(matcher)
  end

  log.debug("Registered initial configuration: %s", M.config)

  return M.config
end

return M
