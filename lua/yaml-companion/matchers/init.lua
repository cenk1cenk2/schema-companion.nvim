local M = {}

M.matchers = {}

local log = require("yaml-companion.log")

function M.get()
  return M.matchers
end

function M.register(matcher)
  local m = vim.tbl_extend("force", {
    name = "unknown",
    config = {},
    health = function()
      vim.health.info("No healthcheck provided.")
    end,
    match = function()
      return nil
    end,
    handles = function()
      return {}
    end,
  }, matcher)

  table.insert(M.matchers, m)
  vim.inspect(M.matchers)

  log.debug("registered matcher: %s", m.name)
end

return M
