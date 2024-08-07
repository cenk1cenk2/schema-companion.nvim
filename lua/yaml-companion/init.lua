local M = {}

---@type ConfigOptions
M.config = {
  log_level = "info",
  formatting = true,
  matchers = {},
  schemas = {},
}

---
---@param config ConfigOptions
---@return ConfigOptions
function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  local log = require("yaml-companion.log").new({ level = M.config.log_level })

  log.debug("yaml-companion has been setup: %s", M.config)

  for _, matcher in ipairs(M.config.matchers) do
    require("yaml-companion.matchers").register(matcher)
  end

  return M.config
end

function M.setup_client(config)
  local add_hook_after = require("lspconfig.util").add_hook_after

  return vim.tbl_deep_extend("force", {}, config, {
    on_attach = add_hook_after(config.on_attach, function(client, bufnr)
      require("yaml-companion.context").setup(bufnr, client)
    end),

    on_init = add_hook_after(config.on_init, function(client)
      client.notify("yaml/supportSchemaSelection", { {} })

      return true
    end),

    handlers = vim.tbl_extend("force", config.handlers or {}, {
      ["yaml/schema/store/initialized"] = require("yaml-companion.lsp.handler").store_initialized,
    }),
  })
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param schema SchemaResult | Schema
function M.set_buffer_schema(bufnr, schema)
  return require("yaml-companion.context").schema(bufnr, schema)
end

--- Get the schema used for a buffer.
---@param bufnr number: Buffer number
function M.get_buffer_schema(bufnr)
  return require("yaml-companion.context").schema(bufnr)
end

--- Opens a vim.ui.select menu to choose a schema
function M.open_ui_select()
  require("yaml-companion.select.ui").open_ui_select()
end

return M
