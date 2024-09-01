local M = {}

---@type schema_companion.Config
M.config = {
  enable_telescope = false,
  matchers = {},
  schemas = {},
}

--- Configures the schema-companion plugin.
---@param config schema_companion.Config
---@return schema_companion.Config
function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  local log = require("schema-companion.log").setup()

  if M.config.enable_telescope then
    xpcall(function()
      return require("telescope").load_extension("yaml_schema")
    end, debug.traceback)
  end

  log.debug("schema-companion has been setup: %s", M.config)

  for _, matcher in ipairs(M.config.matchers) do
    require("schema-companion.matchers").register(matcher)
  end

  return M.config
end

--- Configures a LSP client with the schema-companion handlers.
---@param config any
---@returns any
function M.setup_client(config)
  -- taken from require("lspconfig.util").add_hook_after to drop dependency
  local add_hook_after = function(func, new_fn)
    if func then
      return function(...)
        func(...)
        return new_fn(...)
      end
    else
      return new_fn
    end
  end

  return vim.tbl_deep_extend("force", {}, config, {
    on_attach = add_hook_after(config.on_attach, function(client, bufnr)
      require("schema-companion.context").setup(bufnr, client)
    end),

    on_init = add_hook_after(config.on_init, function(client)
      client.notify("yaml/supportSchemaSelection", { {} })

      return true
    end),

    handlers = vim.tbl_extend("force", config.handlers or {}, {
      ["yaml/schema/store/initialized"] = require("schema-companion.lsp").store_initialized,
    }),
  })
end

return M
