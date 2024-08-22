local M = {}

local log = require("schema-companion.log")

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
      log.warn("No version provided.")
    end

    M.set_version(version)
  end)
end

local builtin_resource_regex = {
  [[.*k8s.io$]],
  [[^apps$]],
  [[^batch$]],
  [[^autoscaling$]],
}

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
    "Kubernetes matcher matches: bufnr=%d group=%s version=%s kind=%s",
    bufnr or "unknown",
    resource.group or "unknown",
    resource.version or "unknown",
    resource.kind or "unknown"
  )

  if not resource.version or #vim.tbl_filter(function(regex)
    return resource.group:match(regex)
  end, builtin_resource_regex) > 0 then
    local _, _, resource_group = resource.group:find([[^([^.]*)]])

    if resource.version then
      return {
        name = ("Kubernetes [%s] [%s@%s/%s]"):format(M.config.version, resource.kind, resource.group, resource.version),
        uri = ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s-%s.json"):format(
          M.config.version,
          resource.kind:lower(),
          resource_group:lower(),
          resource.version:lower()
        ),
      }
    end

    return {
      name = ("Kubernetes [%s] [%s@%s]"):format(M.config.version, resource.kind, resource.group),
      uri = ("https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/%s-%s.json"):format(
        M.config.version,
        resource.kind:lower(),
        resource_group:lower()
      ),
    }
  end

  return {
    name = ("Kubernetes [CRD] [%s@%s/%s]"):format(resource.kind, resource.group, resource.version),
    uri = ("https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/%s/%s_%s.json"):format(resource.group:lower(), resource.kind:lower(), resource.version:lower()),
  }
end

return M
