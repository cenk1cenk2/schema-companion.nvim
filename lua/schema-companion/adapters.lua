local M = {
  ---@type table<number, schema_companion.Adapter>
  ctx = {},
}

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

---
---@param client_id number
---@return schema_companion.Adapter
function M.get_adapter(client_id)
  local adapter = M.ctx[client_id]

  if not adapter then
    error(("no adapter found for client_id=%d"):format(client_id))
  end

  return adapter
end

---
---@param client_id number
---@param adapter schema_companion.Adapter
function M.set_adapter(client_id, adapter)
  if M.ctx[client_id] then
    log.debug("adapter already set client_id=%d", client_id)

    return M.ctx[client_id]
  end

  M.ctx[client_id] = adapter
end

--- Adapter for the yamlls language server.
---@return schema_companion.Adapter
function M.yamlls_adapter()
  local name = "yamlls"

  ---@type schema_companion.Adapter
  local adapter = {
    setup = function(self, config)
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
            require("schema-companion.context").setup(bufnr, client)
          end),

          on_init = utils.add_hook_after(config.on_init, function(client)
            client:notify("yaml/supportSchemaSelection", { {} })

            return true
          end),

          handlers = vim.tbl_extend("force", config.handlers or {}, {
            ["yaml/schema/store/initialized"] = function(_, _, req, _)
              return require("schema-companion.lsp").store_initialized(req.client_id, self)
            end,
          }),
        }
      )
    end,
    update_schema = function(self, client, bufnr, schema)
      local bufuri = vim.uri_from_bufnr(bufnr)

      local override = {}

      local schemas = {}
      if client.settings and client.settings.yaml and client.settings.yaml.schemas then
        schemas = client.settings.yaml.schemas
      end

      for u, b in pairs(schemas) do
        if b == bufuri then
          override[u] = false
          log.debug("removed override: file=%s schema=%s adapter=%s", b, u, name)
        end
      end

      override[schema.uri] = bufuri

      log.debug("set new override: file=%s schema=%s adapter=%s", bufuri, schema.uri, name)

      client.settings = vim.tbl_deep_extend("force", client.settings, { yaml = { schemas = override } })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })

      log.debug("notified client of configuration changes: file=%s schema=%s adapter=%s client_id=%d", bufuri, schema.uri, name, client.id)
      return client
    end,
  }
  setmetatable({}, adapter)

  return adapter
end

--- Adapter for the helmls language server.
---@return schema_companion.Adapter
function M.helmls_adapter()
  local name = "helmls"

  ---@type schema_companion.Adapter
  local adapter = {
    setup = function(self, config)
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
            require("schema-companion.context").setup(bufnr, client)

            --- HACK: this does not proxy the yaml rpc.receive through yaml-language-server therefore we hack the handler
            require("schema-companion.lsp").store_initialized(client.id, self)
          end),

          on_init = utils.add_hook_after(config.on_init, function(client)
            client:notify("yaml/supportSchemaSelection", { {} })

            return true
          end),
        }
      )
    end,
    update_schema = function(self, client, bufnr, schema)
      local bufuri = vim.uri_from_bufnr(bufnr)

      local override = {}

      local schemas = {}
      if
        client.settings
        and client.settings["helm-ls"]
        and client.settings["helm-ls"].yamlls
        and client.settings["helm-ls"].yamlls.config
        and client.settings["helm-ls"].yamlls.config.schemas
      then
        schemas = client.settings["helm-ls"].yamlls.config.schemas
      end

      for u, b in pairs(schemas) do
        if b == bufuri then
          override[u] = false
          log.debug("removed override: file=%s schema=%s adapter=%s", b, u, name)
        end
      end

      override[schema.uri] = bufuri

      log.debug("set new override: file=%s schema=%s adapter=%s", bufuri, schema.uri, name)

      client.settings = vim.tbl_deep_extend("force", client.settings, { ["helm-ls"] = { yamlls = { config = { schemas = override } } } })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })

      log.debug("notified client of configuration changes: file=%s schema=%s adapter=%s client_id=%d", bufuri, schema.uri, name, client.id)

      return client
    end,
  }
  setmetatable({}, adapter)

  return adapter
end

return M
