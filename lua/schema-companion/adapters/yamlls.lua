---@class schema_companion.Adapter
local M = {}

M.name = "yamlls"

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
      end),

      on_init = utils.add_hook_after(config.on_init, function(client)
        client:notify("yaml/supportSchemaSelection", { {} })

        return true
      end),

      handlers = vim.tbl_extend("force", config.handlers or {}, {
        ["yaml/schema/store/initialized"] = function(_, _, req, _)
          return require("schema-companion.lsp").on_store_initialized(req.client_id, self)
        end,
      }),
    }
  )
end

function M:on_update_schemas(bufnr, schemas)
  local bufuri = vim.uri_from_bufnr(bufnr)
  local client = self:get_client()

  local override = {}

  local current_schemas = {}
  if vim.tbl_get(client, "settings", "yaml", "schemas") then
    ---@diagnostic disable-next-line: undefined-field
    current_schemas = client.settings.yaml.schemas
  end

  for u, b in pairs(current_schemas) do
    if b == bufuri then
      override[u] = false
      log.debug("removed override: file=%s schema=%s adapter=%s", b, u, M.name)
    end
  end

  for _, schema in ipairs(schemas) do
    override[schema.uri] = bufuri

    log.debug("set new override: file=%s schema=%s adapter=%s", bufuri, schema.uri, M.name)
  end

  client.settings = vim.tbl_deep_extend("force", client.settings, { yaml = { schemas = override } })
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })

  log.debug("notified client of configuration changes: file=%s adapter=%s client_id=%d schemas=%s", bufuri, M.name, client.id, override)
end

function M:get_schemas_from_lsp()
  local client = self:get_client()

  local schemas = require("schema-companion.lsp").request_sync(client, "yaml/get/all/jsonSchemas") or {}

  log.debug("get schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

function M:match_schema_from_lsp(bufnr)
  local client = self:get_client()

  local schemas = require("schema-companion.lsp").request_sync(client, "yaml/get/jsonSchema", { vim.uri_from_bufnr(bufnr) }, bufnr) or {}

  log.debug("match schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

M.setup = require("schema-companion.adapters.metatable").new(M)

return M
