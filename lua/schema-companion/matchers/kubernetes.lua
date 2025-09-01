---@class schema_companion.Matcher
local M = {}

-- TODO: REFACTOR ME AFTER

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

M.name = "Kubernetes"

M.config = {
  version = "master",
}

function M.setup(config)
  M.config = vim.tbl_deep_extend("force", {}, M.config, config)

  return M
end

function M.set_version(version)
  M.config.version = version

  return version
end

function M.get_version()
  return M.config.version
end

function M.change_version()
  vim.ui.input({
    prompt = "Kubernetes version",
    default = M.get_version(),
  }, function(version)
    if not version then
      log.warn("no version provided: matcher=%s", M.name)
    end

    M.set_version(version)
  end)
end

local builtin_resource_regex = {
  [[.*k8s.io$]],
  [[^apps$]],
  [[^batch$]],
  [[^autoscaling$]],
  [[^policy$]],
}

local builtin_ignore_resource = {
  "gateway.networking.k8s.io",
}

local match_resource = function(bufnr, resource)
  if not resource.kind or not resource.group then
    return nil
  end

  log.debug(
    "matches: matcher=%s bufnr=%d group=%s version=%s kind=%s",
    M.name,
    bufnr or "unknown",
    resource.group or "unknown",
    resource.version or "unknown",
    resource.kind or "unknown"
  )

  local is_builtin = false
  if not vim.tbl_contains(builtin_ignore_resource, resource.group, nil) then
    is_builtin = (not resource.version or #vim.tbl_filter(function(regex)
      return resource.group:match(regex)
    end, builtin_resource_regex) > 0)
  end

  if is_builtin then
    local _, _, resource_group = resource.group:find([[^([^.]*)]])

    if resource.version then
      return {
        utils.ensure_and_return(
          ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s-%s.json"):format(
            M.config.version,
            resource.kind:lower(),
            resource_group:lower(),
            resource.version:lower()
          ),
          {
            name = ("Kubernetes [%s] [%s@%s/%s]"):format(M.config.version, resource.kind, resource.group, resource.version),
          }
        ),
      }
    end

    return {
      utils.ensure_and_return(
        ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s.json"):format(
          M.config.version,
          resource.kind:lower(),
          resource_group:lower()
        ),
        {
          name = ("Kubernetes [%s] [%s@%s]"):format(M.config.version, resource.kind, resource.group),
        }
      ),
    }
  end

  return {
    utils.ensure_and_return(
      ("https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/%s/%s_%s.json"):format(resource.group:lower(), resource.kind:lower(), resource.version:lower()),
      {
        name = ("Kubernetes [CRD] [%s@%s/%s]"):format(resource.kind, resource.group, resource.version),
      }
    ),
  }
end

function M.match(bufnr)
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
