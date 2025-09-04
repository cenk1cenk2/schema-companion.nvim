---@class schema_companion.Source
local M = {}

local log = require("schema-companion.log")

M.name = "LSP"

function M.setup()
  return M
end

---@param ctx schema_companion.Context
---@param schemas schema_companion.Schema[]
---@return schema_companion.Schema[]
local function enrich_schemas(ctx, schemas)
  local client = ctx.adapter:get_client()
  for _, schema in ipairs(schemas) do
    if schema.source then
      schema.source = ("%s/%s/%s"):format(M.name, client.name or client.id, schema.source)
    else
      schema.source = ("%s/%s"):format(M.name, client.name or client.id)
    end
  end

  return schemas
end

function M:get_schemas(ctx, bufnr)
  return enrich_schemas(ctx, ctx.adapter:get_schemas_from_lsp(bufnr)) or {}
end

function M:match(ctx, bufnr)
  local matches = ctx.adapter:match_schema_from_lsp(bufnr)

  log.debug("matches: source_name=%s, #matches=%d", M.name, #matches)

  return enrich_schemas(ctx, matches)
end

return M
