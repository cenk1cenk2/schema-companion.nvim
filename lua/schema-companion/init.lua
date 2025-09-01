local M = {}

--- Configures the schema-companion plugin.
---@param config schema_companion.Config
function M.setup(config)
  local c = require("schema-companion.config").setup(config)

  require("schema-companion.log").setup({ level = c.log_level })

  if c.enable_telescope then
    xpcall(function()
      return require("telescope").load_extension("schema_companion")
    end, debug.traceback)
  end
end

--- Configures a LSP client with the schema-companion handlers.
---@param adapter schema_companion.Adapter --- Adapter for the language server.
---@param config? vim.lsp.ClientConfig --- User configuration for the language server.
---@returns vim.lsp.ClientConfig
function M.setup_client(adapter, config)
  config = config or {}

  return adapter:on_setup_client(config)
end

return M
