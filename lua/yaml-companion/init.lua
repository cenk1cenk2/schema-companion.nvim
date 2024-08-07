local M = {}

function M.setup(opts)
  require("yaml-companion.config").setup(opts)
end

function M.setup_client(config)
  local handlers = require("vim.lsp.handlers")
  local add_hook_after = require("lspconfig.util").add_hook_after

  handlers["yaml/schema/store/initialized"] =
    require("yaml-companion.lsp.handler").store_initialized

  return vim.tbl_deep_extend("force", {}, config, {
    on_attach = add_hook_after(config.on_attach, function(client, bufnr)
      require("yaml-companion.context").setup(bufnr, client)
    end),

    on_init = add_hook_after(config.on_init, function(client)
      client.notify("yaml/supportSchemaSelection", { {} })
      return true
    end),

    handlers = handlers,
  })
end

--- Set the schema used for a buffer.
---@param bufnr number: Buffer number
---@param schema SchemaResult | Schema
function M.set_buf_schema(bufnr, schema)
  M.ctx.schema(bufnr, schema)
end

--- Get the schema used for a buffer.
---@param bufnr number: Buffer number
function M.get_buf_schema(bufnr)
  return { result = { require("yaml-companion.context").schema(bufnr) } }
end

--- Opens a vim.ui.select menu to choose a schema
function M.open_ui_select()
  require("yaml-companion.select.ui").open_ui_select()
end

return M
