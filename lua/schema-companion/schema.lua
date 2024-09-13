local M = {}

local setup = require("schema-companion.setup")
local matchers = require("schema-companion.matchers")
local lsp = require("schema-companion.lsp")

---@param schema schema_companion.Schema
---@return boolean
local valid_schema = function(schema)
  if schema and schema.uri then
    return true
  end
  return false
end

---@return schema_companion.Schema
function M.default_schema()
  return {
    name = "none",
    uri = "none",
  }
end

--- User defined schemas
---@return schema_companion.Schema[]
function M.from_options()
  local r = {}
  if setup.config and setup.config.schemas then
    for _, schema in ipairs(setup.config.schemas) do
      if valid_schema(schema) then
        table.insert(r, schema)
      end
    end
  end

  return r
end

--- Matcher defined schemas
---@return schema_companion.Schema[]
function M.from_matchers()
  ---@type schema_companion.Schema[]
  local r = {}
  for _, matcher in ipairs(matchers.get()) do
    r = vim.list_extend(r, matcher.handles())
  end
  return r
end

--- Matcher defined schemas
---@return schema_companion.Schema[]
function M.from_store()
  local schemas = lsp.get_all_schemas(0)
  if schemas == nil or vim.tbl_count(schemas or {}) == 0 then
    return {}
  end

  return schemas
end

---@return schema_companion.Schema[]
function M.all()
  local r = {}

  r = vim.list_extend(r, M.from_store())
  r = vim.list_extend(r, M.from_matchers())
  r = vim.list_extend(r, M.from_options())

  return r
end

---@return schema_companion.Schema | nil
---@param bufnr number
function M.current(bufnr)
  local schema = lsp.get_schema(bufnr)

  if not schema then
    return M.default_schema()
  end

  return schema
end

---@return schema_companion.Schema[] | nil
---@param bufnr number
function M.matching(bufnr)
  local schemas = lsp.get_schemas(bufnr)

  return schemas
end

return M
