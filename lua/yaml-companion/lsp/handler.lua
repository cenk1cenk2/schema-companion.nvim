local M = {}

local log = require("yaml-companion.log")

function M.store_initialized(_, _, req, _)
  local client_id = req.client_id

  require("yaml-companion.context").initialized_client_ids[client_id] = true

  local client = vim.lsp.get_client_by_id(client_id)
  local buffers = vim.lsp.get_buffers_by_client_id(client_id)

  for _, bufnr in ipairs(buffers) do
    log.debug("client_id=%s bufnr=%d running autodiscover", client_id, bufnr)

    require("yaml-companion.context").autodiscover(bufnr, client)
  end
end

return M
