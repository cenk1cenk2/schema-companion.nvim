local M = {
  set_buffer_schema = require("yaml-companion.context").set_buffer_schema,
  get_buffer_schema = require("yaml-companion.context").get_buffer_schema,
}

---@type ConfigOptions
M.config = {
  log_level = "info",
  formatting = true,
  enable_telescope = false,
  matchers = {},
  schemas = {},
}

---
---@param config ConfigOptions
---@return ConfigOptions
function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  local log = require("yaml-companion.log").new({ level = M.config.log_level })

  if M.config.enable_telescope then
    pcall(function()
      return require("telescope").load_extension("yaml_schema")
    end, debug.traceback)
  end

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
      ["yaml/schema/store/initialized"] = require("yaml-companion.lsp").store_initialized,
    }),
  })
end

return M
