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

  for _, matcher in ipairs(c.matchers) do
    require("schema-companion.matchers").register(matcher)
  end
end

--- Configures a LSP client with the schema-companion handlers.
---@param config? vim.lsp.ClientConfig
---@returns any
function M.setup_client(config)
  config = config or {}

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

  -- create capabilities while integrating user-provided capabilities
  local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), config.capabilities or {}, {
    workspace = {
      didChangeConfiguration = {
        dynamicRegistration = true,
      },
    },
  })

  return vim.tbl_deep_extend(
    "force",
    {},
    config,
    ---@type vim.lsp.ClientConfig
    {
      capabilities = capabilities,

      on_attach = add_hook_after(config.on_attach, function(client, bufnr)
        require("schema-companion.context").setup(bufnr, client)
      end),

      on_init = add_hook_after(config.on_init, function(client)
        client:notify("yaml/supportSchemaSelection", { {} })

        return true
      end),

      handlers = vim.tbl_extend("force", config.handlers or {}, {
        ["yaml/schema/store/initialized"] = require("schema-companion.lsp").store_initialized,
      }),
    }
  )
end

return M
