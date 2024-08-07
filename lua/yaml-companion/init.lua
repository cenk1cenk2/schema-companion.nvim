local M = {}

local _matchers = require("yaml-companion._matchers")

M.ctx = {}

M.setup = function(opts)
  local config = require("yaml-companion.config")
  config.setup(opts, function(client, bufnr)
    require("yaml-companion.context").setup(bufnr, client)
  end)
  require("yaml-companion.log").new({ level = config.options.log_level }, true)

  M.ctx = require("yaml-companion.context")

  return config.options.lspconfig
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param schema SchemaResult | Schema
M.set_buf_schema = function(bufnr, schema)
  M.ctx.schema(bufnr, schema)
end

--- Get the schema used for a buffer.
---@param bufnr number: Buffer number
M.get_buf_schema = function(bufnr)
  return { result = { M.ctx.schema(bufnr) } }
end

--- Loads a matcher.
---@param name string: Name of the matcher
M.load_matcher = function(name)
  return _matchers.load(name)
end

--- Opens a vim.ui.select menu to choose a schema
M.open_ui_select = function()
  require("yaml-companion.select.ui").open_ui_select()
end

M.get_matcher_parameters = function(name)
  return require("yaml-companion.config").options.matcher_parameters[name]
end

M.set_matcher_parameters = function(name, params)
  require("yaml-companion.config").options.matcher_parameters[name] = params
end

return M
