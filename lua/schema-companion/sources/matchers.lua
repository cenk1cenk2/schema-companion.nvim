---@class schema_companion.Source
local M = {}

local log = require("schema-companion.log")

M.name = "matchers"

function M.setup()
  return M
end

function M.get_schemas(ctx)
  local schemas = {}
  for _, matcher in pairs(ctx.adapter:get_matchers()) do
    if type(matcher.get_schemas) == "function" then
      local matches = matcher.get_schemas()

      log.debug("get schemas: adapter=%s matcher=%s matches_count=%d", M.name, matcher.name, #matches)

      schemas = vim.list_extend(schemas, matches or {})
    end
  end

  return schemas
end

function M.match(ctx, bufnr)
  local schemas = {}

  for _, matcher in pairs(ctx.adapter:get_matchers()) do
    local matches = matcher.match(bufnr)

    log.debug("match schemas: adapter=%s matcher=%s matches_count=%d", M.name, matcher.name, #matches)

    schemas = vim.list_extend(schemas, matches or {})
  end

  return schemas
end

return M
