---@class schema_companion.Adapter
local M = {}

M.name = "jsonls"

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

---@param schemas table
---@return schema_companion.EnrichedSchema[]
local function parse_schemas(schemas)
  return vim.tbl_map(function(schema)
    return {
      uri = schema.url,
      name = schema.name,
      description = schema.description,
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
      fileMatch = { bufuri },
      uri = schema.uri,
    }
  end, schemas)

  log.debug("set new override: file=%s schemas=%s adapter=%s", bufuri, override, M.name)

  ---@diagnostic disable-next-line: param-type-mismatch
  client:notify("json/schemaAssociations", { override })
  ---@diagnostic disable-next-line: param-type-mismatch
  client:notify("json/schemaContent", {
    vim.tbl_map(function(schema)
      return schema.uri
    end, override),
  })

  log.debug("notified client of configuration changes: file=%s adapter=%s client_id=%d schemas=%s", bufuri, M.name, client.id, override)
end

function M:get_schemas_from_lsp()
  local client = self:get_client()

  local schemas = vim.tbl_get(client, "settings", "json", "schemas")
  schemas = parse_schemas(schemas)

  log.debug("get schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

function M:match_schema_from_lsp(bufnr)
  local client = self:get_client()
  local bufuri = vim.uri_from_bufnr(bufnr)

  local res = require("schema-companion.lsp").request_sync(client, "json/languageStatus", bufuri) or {}
  local schemas = res.schemas or {}

  local current_schemas = {}
  if vim.tbl_get(client, "settings", "json", "schemas") then
    ---@diagnostic disable-next-line: undefined-field
    current_schemas = client.settings.json.schemas
  end

  current_schemas = parse_schemas(schemas)

  schemas = vim.tbl_filter(function(schema)
    return vim.list_contains(schemas, schema.uri)
  end, current_schemas)

  log.debug("match schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

M.setup = require("schema-companion.adapters.metatable").new(M)

return M
