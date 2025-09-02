---@class schema_companion.Source
local M = {}

local log = require("schema-companion.log")

M.name = "lsp"

function M.setup()
  return M
end

function M:get_schemas(ctx)
  return ctx.adapter:get_schemas_from_lsp() or {}
end

function M:match(ctx, bufnr)
  local matches = ctx.adapter:match_schema_from_lsp(bufnr)

  log.debug("matches: source_name=%s, #matches=%d", M.name, #matches)

  return matches
end

return M
