local M = {}

local api = vim.api
local resources = require("yaml-companion.builtin.kubernetes.resources")

M.get_schema = function()
  local uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/"
    .. require("yaml-companion.config").options.versions.kubernetes
    .. "-standalone-strict/all.json"

  local schema = {
    name = "Kubernetes",
    uri = uri,
  }

  return schema
end

M.match = function(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for _, line in ipairs(lines) do
    for _, resource in ipairs(resources) do
      if vim.regex("^kind: " .. resource .. "$"):match_str(line) then
        return M.get_schema()
      end
    end
  end
end

M.handles = function()
  return { M.get_schema() }
end

return M
