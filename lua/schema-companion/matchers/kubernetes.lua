local M = {}

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

M.name = "Kubernetes"

M.config = {
  version = "master",
}

---@type schema_companion.MatcherSetupFn
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
      log.warn("No version provided: matcher=%s", M.name)
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

local not_builtin_api_groups = {
    "gateway.networking.k8s.io"
}

---@type schema_companion.MatcherMatchFn
function M.match(bufnr)
  local resource = {}

  for _, line in pairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local _, _, group, version = line:find([[^apiVersion:%s*["']?([^%s"'/]*)/?([^%s"']*)]])
    local _, _, kind = line:find([[^kind:%s*["']?([^%s"'/]*)]])

    if group and group ~= "" then
      resource.group = group
    end
    if version and version ~= "" then
      resource.version = version
    end
    if kind and kind ~= "" then
      resource.kind = kind
    end

    if resource.group and resource.kind then
      break
    end
  end

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

  local is_builtin = false;
  if not vim.tbl_contains(not_builtin_api_groups, resource.group, nil) then
    is_builtin = (not resource.version or #vim.tbl_filter(function(regex)
      return resource.group:match(regex)
    end, builtin_resource_regex) > 0)
  end

  if is_builtin then
    local _, _, resource_group = resource.group:find([[^([^.]*)]])

    if resource.version then
      return utils.ensure_and_return(
        ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s-%s.json"):format(
          M.config.version,
          resource.kind:lower(),
          resource_group:lower(),
          resource.version:lower()
        ),
        {
          name = ("Kubernetes [%s] [%s@%s/%s]"):format(M.config.version, resource.kind, resource.group, resource.version),
        }
      )
    end

    return utils.ensure_and_return(
      ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s.json"):format(
        M.config.version,
        resource.kind:lower(),
        resource_group:lower()
      ),
      {
        name = ("Kubernetes [%s] [%s@%s]"):format(M.config.version, resource.kind, resource.group),
      }
    )
  end

  return utils.ensure_and_return(
    ("https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/%s/%s_%s.json"):format(resource.group:lower(), resource.kind:lower(), resource.version:lower()),
    {
      name = ("Kubernetes [CRD] [%s@%s/%s]"):format(resource.kind, resource.group, resource.version),
    }
  )
end

---@type schema_companion.Matcher
return M
