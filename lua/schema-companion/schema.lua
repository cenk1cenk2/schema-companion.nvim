local M = {}

--- Check if the given schema is valid.
---@param schema schema_companion.Schema
---@return boolean
function M.is_valid_schema(schema)
  if schema and schema.uri then
    return true
  end

  return false
end

--- Get the default schema for a placeholder value.
---@return schema_companion.Schema
function M.get_default_schema()
  return {
    name = "none",
    uri = "none",
  }
end

function M.get_default_schemas()
  return { M.get_default_schema() }
end

---@param bufnr number
---@return schema_companion.Schema[] | nil
function M.get_schemas(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local buffer_context = require("schema-companion.context").read_buffer_context(bufnr)

  local schemas = {}
  for client_id, ctx in pairs(buffer_context) do
    local sources = ctx.adapter:get_sources()

    for _, source in pairs(sources) do
      schemas = vim.list_extend(schemas, M.enrich_schemas(source.get_schemas(ctx) or {}, client_id))
    end
  end

  return schemas
end

---@param bufnr number
---@return schema_companion.Schema[] | nil
function M.get_matching_schemas(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local buffer_context = require("schema-companion.context").read_buffer_context(bufnr)

  local schemas = {}
  for client_id, ctx in pairs(buffer_context) do
    schemas = vim.list_extend(schemas, M.enrich_schemas(ctx.schemas or {}, client_id))
  end

  return schemas
end

---
---@param schemas schema_companion.Schema[]
---@param client_id number
---@return schema_companion.Schema[]
function M.enrich_schemas(schemas, client_id)
  return vim.tbl_map(function(schema)
    schema.client_id = client_id

    return schema
  end, schemas)
end

return M
