local M = {}

local log = require("schema-companion.log")

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
    description = "No schema that matches",
    uri = nil,
  }
end

function M.get_default_schemas()
  return { M.get_default_schema() }
end

---@param schemas schema_companion.EnrichedSchema[]
function M.set_schemas(schemas)
  for _, schema in ipairs(schemas) do
    assert(schema.bufnr, "Schema is missing 'bufnr' field")
    assert(schema.client_id, "Schema is missing 'client_id' field")

    require("schema-companion.context").set_schemas(schema.bufnr, schema.client_id, { schema })
  end
end

--- Matches a schema to the given buffer.
---@param bufnr number?
---@return schema_companion.Schema[] | nil
function M.match(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local context = require("schema-companion.context")

  local ctxs = context.read_buffer_context(bufnr)

  local all = {}
  for client_id, ctx in pairs(ctxs) do
    local schemas = {}

    for _, source in pairs(ctx.adapter:get_sources()) do
      if type(source.match) == "function" then
        local matches = source:match(ctx, bufnr)

        log.debug("schema matched: bufnr=%d client_id=%d adapter_name=%s #matches=%d", bufnr, client_id, ctx.adapter.name, #matches)

        schemas = vim.list_extend(schemas, matches)
      end
    end

    context.set_schemas(bufnr, client_id, schemas)
    all = vim.list_extend(all, schemas)
  end

  return all
end

---@param bufnr number
---@return schema_companion.EnrichedSchema[] | nil
function M.get_schemas(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local buffer_context = require("schema-companion.context").read_buffer_context(bufnr)

  local schemas = {}
  for client_id, ctx in pairs(buffer_context) do
    local sources = ctx.adapter:get_sources()

    for _, source in pairs(sources) do
      if type(source.get_schemas) == "function" then
        schemas = vim.list_extend(schemas, M.enrich_schemas(source:get_schemas(ctx) or {}, bufnr, client_id))
      end
    end
  end

  return schemas
end

---@param bufnr? number
---@return schema_companion.EnrichedSchema[] | nil
function M.get_matching_schemas(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local buffer_context = require("schema-companion.context").read_buffer_context(bufnr)

  local schemas = {}
  for client_id, ctx in pairs(buffer_context) do
    schemas = vim.list_extend(schemas, M.enrich_schemas(ctx.schemas or {}, bufnr, client_id))
  end

  return schemas
end

---
---@param schemas schema_companion.Schema[]
---@param bufnr number
---@param client_id number
---@return schema_companion.EnrichedSchema[]
function M.enrich_schemas(schemas, bufnr, client_id)
  return vim.tbl_map(function(schema)
    schema.client_id = client_id
    schema.bufnr = bufnr

    return schema
  end, schemas)
end

---@param bufnr? number
---@return string | nil
function M.get_current_schemas(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local schemas = M.get_matching_schemas(bufnr)

  if schemas == nil or #schemas == 0 then
    return nil
  end

  local first = schemas[1]

  return ("%s (%s)%s"):format(first.name or first.description or first.uri, first.source or "unknown", #schemas > 1 and (" (and +%d)"):format(#schemas - 1) or "")
end

return M
