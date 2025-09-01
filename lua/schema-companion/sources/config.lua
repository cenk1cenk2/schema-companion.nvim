---@class schema_companion.Source
local M = {}

local log = require("schema-companion.log")

M.name = "config"

function M.setup()
  return M
end

function M.get_schemas(ctx)
  return ctx.adapter:get_schemas_from_config() or {}
end

function M.match()
  log.debug("source does not implement an match mechanism: source_name=%s", M.name)

  return {}
end

return M
