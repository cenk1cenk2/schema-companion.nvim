local M = {}

local log = require("yaml-companion.log")

local sync_timeout = 5000

---@param bufnr number
---@param method string
---@return table | nil
function M.request_sync(bufnr, method)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  local result = {}

  for _, client in pairs(clients) do
    local response, error =
      client.request_sync(method, { vim.uri_from_bufnr(bufnr) }, sync_timeout, bufnr)

    if error then
      log.error("bufnr=%d error=%s", bufnr, error)
    elseif response and response.err then
      log.error("bufnr=%d error=%s", bufnr, response.err)
    elseif response and response.result then
      vim.list_extend(result, response.result)
    end
  end

  return result
end

return M
