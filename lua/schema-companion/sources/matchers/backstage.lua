---@class schema_companion.Source
local M = {}

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

M.name = "Backstage"

M.config = {
  version = "latest",
}

---
---@param config { version: string }
---@return schema_companion.Source
function M.setup(config)
  setmetatable(M, {})
  M.config = vim.tbl_deep_extend("force", {}, M.config, config)

  return M
end

local match_resource = function(bufnr, resource)
  if not resource.kind or not resource.group or not resource.version then
    return nil
  end

  log.debug(
    "matches: matcher=%s bufnr=%d group=%s version=%s kind=%s",
    M.name,
    bufnr or "unknown",
    resource.group,
    resource.version,
    resource.kind
  )

  return {
    utils.ensure_and_return(
      ("https://raw.githubusercontent.com/nyyakko/backstage-json-schema/master/%s/%s.%s.schema.json"):format(
        M.config.version,
        resource.kind:lower(),
        resource.version:lower()
        ),
      {
        name = ("%s@%s/%s [%s]"):format(resource.kind, resource.group, resource.version, M.config.version),
        source = M.name,
      }
    ),
  }
end

function M:match(_, bufnr)
  local resources = {}

  local current = {}
  for _, line in pairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local _, _, group, version = line:find([[^apiVersion:%s*["']?([^%s"'/]*)/?([^%s"']*)]])
    local _, _, kind = line:find([[^kind:%s*["']?([^%s"'/]*)]])

    if group and group ~= "" then
      current.group = group
    end
    if version and version ~= "" then
      current.version = version
    end
    if kind and kind ~= "" then
      current.kind = kind
    end

    if current.group and current.kind then
      table.insert(resources, current)
      current = {}
    end
  end

  local schemas = {}
  for _, resource in pairs(resources) do
    local schema = match_resource(bufnr, resource)
    if schema then
      vim.list_extend(schemas, schema)
    end
  end

  return schemas
end

return M
