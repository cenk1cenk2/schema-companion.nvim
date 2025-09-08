---@class schema_companion.Adapter
local M = {}

M.name = "taplo"

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

---@param schemas table
---@return schema_companion.EnrichedSchema[]
local function parse_schemas(schemas)
  return vim.tbl_map(function(schema)
    return {
      name = schema.meta.name,
      uri = schema.url,
      description = schema.description,
      source = schema.meta.source,
    }
  end, schemas)
end

function M:on_setup_client(config)
  return vim.tbl_deep_extend(
    "force",
    {},
    config,
    ---@type vim.lsp.ClientConfig
    {
      on_attach = utils.add_hook_after(config.on_attach, function(client, bufnr)
        self:set_client(client)

        require("schema-companion.context").setup(bufnr, self)

        require("schema-companion.lsp").on_store_initialized(client.id, self)
      end),
    }
  )
end

function M:on_update_schemas(bufnr, schemas)
  local client = self:get_client()
  local bufuri = vim.uri_from_bufnr(bufnr)

  local override = vim.tbl_map(function(schema)
    return {
      ["document_uri"] = bufuri,
      ["schema_uri"] = schema.uri,
      ["rule"] = {
        url = bufuri,
      },
    }
  end, schemas)

  log.debug("set new override: file=%s schemas=%s adapter=%s", bufuri, override, M.name)

  ---@diagnostic disable-next-line: param-type-mismatch
  client:notify("taplo/associateSchema", { override })

  log.debug("notified client of configuration changes: file=%s adapter=%s client_id=%d schemas=%s", bufuri, M.name, client.id, override)
end

function M:get_schemas_from_lsp(bufnr)
  local client = self:get_client()
  local bufuri = vim.uri_from_bufnr(bufnr)

  local schemas = require("schema-companion.lsp").request_sync(client, "taplo/listSchemas", { ["documentUri"] = bufuri }) or {}
  schemas = schemas.schemas

  schemas = parse_schemas(schemas)

  log.debug("get schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

function M:match_schema_from_lsp(bufnr)
  local client = self:get_client()

  local schemas = require("schema-companion.lsp").request_sync(client, "taplo/associatedSchema", { ["documentUri"] = vim.uri_from_bufnr(bufnr) }, bufnr) or {}

  schemas = { schemas.schema }
  schemas = parse_schemas(schemas)

  log.debug("match schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

M.setup = require("schema-companion.adapters.metatable").new(M)

return M
