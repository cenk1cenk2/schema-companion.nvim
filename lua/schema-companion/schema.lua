local M = {}

local config = require("schema-companion").config
local matchers = require("schema-companion.matchers")
local lsp = require("schema-companion.lsp")

---@param schema Schema
---@return boolean
local valid_schema = function(schema)
  if schema and schema.uri then
    return true
  end
  return false
end

---@return Schema
function M.default_schema()
  return { name = "none", uri = "none" }
end

--- User defined schemas
---@return Schema[]
function M.from_options()
  local r = {}
  if config and config.schemas then
    for _, schema in ipairs(config.schemas) do
      if valid_schema(schema) then
        table.insert(r, schema)
      end
    end
  end

  return r
end

--- Matcher defined schemas
---@return Schema[]
function M.from_matchers()
  ---@type Schema[]
  local r = {}
  for _, matcher in ipairs(matchers.get()) do
    r = vim.list_extend(r, matcher.handles())
  end
  return r
end

--- Matcher defined schemas
---@return Schema[]
function M.from_store()
  local schemas = lsp.get_all_schemas(0)
  if schemas == nil or vim.tbl_count(schemas or {}) == 0 then
    return {}
  end

  return schemas
end

---@return Schema[]
function M.all()
  local r = {}

  r = vim.list_extend(r, M.from_store())
  r = vim.list_extend(r, M.from_matchers())
  r = vim.list_extend(r, M.from_options())

  return r
end

---@return Schema
---@param bufnr number
function M.current(bufnr)
  local schema = lsp.get_schema(bufnr)

  if not schema then
    return M.default_schema()
  end

  return schema
end

---@return Schema
---@param bufnr number
function M.matching(bufnr)
  local schema = lsp.get_matching_schemas(bufnr)

  if not schema then
    return M.default_schema()
  end

  return schema
end

return M
