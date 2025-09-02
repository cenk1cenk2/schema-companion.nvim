local M = {
  adapters = require("schema-companion.adapters"),
  sources = require("schema-companion.sources"),
  match = require("schema-companion.schema").match,
  get_matching_schemas = require("schema-companion.schema").get_matching_schemas,
  get_schemas = require("schema-companion.schema").get_schemas,
  set_schemas = require("schema-companion.schema").set_schemas,
  select_schema = require("schema-companion.select").select_schema,
  select_matching_schema = require("schema-companion.select").select_matching_schema,
  get_current_schemas = require("schema-companion.schema").get_current_schemas,
}

--- Configures the schema-companion plugin.
---@param config schema_companion.Config
function M.setup(config)
  local c = require("schema-companion.config").setup(config)

  require("schema-companion.log").setup({ level = c.log_level })
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
