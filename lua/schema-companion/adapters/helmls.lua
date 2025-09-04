---@class schema_companion.Adapter
local M = {}

M.name = "helmls"

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

function M:on_setup_client(config)
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

      on_attach = utils.add_hook_after(config.on_attach, function(client, bufnr)
        self:set_client(client)
        require("schema-companion.context").setup(bufnr, self)

        --- HACK: this does not proxy the yaml rpc.receive through yaml-language-server therefore we hack the handler
        require("schema-companion.lsp").on_store_initialized(client.id, self)
      end),

      on_init = utils.add_hook_after(config.on_init, function(client)
        client:notify("yaml/supportSchemaSelection", { {} })

        return true
      end),
    }
  )
end

function M:on_update_schemas(bufnr, schemas)
  local bufuri = vim.uri_from_bufnr(bufnr)
  local client = self:get_client()

  local override = {}

  local current_schemas = {}
  if vim.tbl_get(client, "settings", "helm-ls", "yamlls", "config", "schemas") then
    ---@diagnostic disable-next-line: undefined-field
    current_schemas = client.settings["helm-ls"].yamlls.config.schemas
  end

  for u, b in pairs(current_schemas) do
    if b == bufuri then
      override[u] = false
      log.debug("removed override: file=%s schema=%s adapter=%s", b, u, M.name)
    end
  end

  for _, schema in pairs(schemas) do
    override[schema.uri] = bufuri

    log.debug("set new override: file=%s schema=%s adapter=%s", bufuri, schema.uri, M.name)
  end

  client.settings = vim.tbl_deep_extend("force", client.settings, { ["helm-ls"] = { yamlls = { config = { schemas = override } } } })
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })

  log.debug("notified client of configuration changes: file=%s adapter=%s client_id=%d schemas=%s", bufuri, M.name, client.id, override)

  return client
end

M.setup = require("schema-companion.adapters.metatable").new(M)

return M
