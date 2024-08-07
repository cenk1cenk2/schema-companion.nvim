local M = {}

local config = require("yaml-companion.config").config
local matchers = require("yaml-companion.matchers")
local lsp = require("yaml-companion.lsp.requests")

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
    r = vim.tbl_extend("keep", r, matcher.handles())
  end
  return r
end

--- Matcher defined schemas
---@return Schema[]
function M.from_store()
  local schemas = lsp.get_all_jsonschemas(0)
  if schemas == nil or vim.tbl_count(schemas or {}) == 0 then
    return {}
  end
  return schemas
end

---@return Schema[]
function M.all()
  local r = {}

  r = vim.tbl_extend("keep", r, M.from_store())
  r = vim.tbl_extend("keep", r, M.from_options())
  r = vim.tbl_extend("keep", r, M.from_matchers())
  return r
end

---@return Schema
---@param bufnr number
function M.current(bufnr)
  local schema = lsp.get_jsonschema(bufnr)
  if not schema then
    return M.default_schema()
  end

  return schema
end

return M
