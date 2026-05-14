---@class schema_companion.Adapter
local M = {}

M.name = "tombi"

local log = require("schema-companion.log")
local utils = require("schema-companion.utils")

---@param schemas table
---@return schema_companion.EnrichedSchema[]
local function parse_schemas(schemas)
  return vim.tbl_map(function(schema)
    return {
      name = schema.title,
      uri = schema.uri,
      description = schema.description,
      source = schema.catalogUri,
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

  for _, schema in ipairs(schemas) do
    local params = {
      uri = schema.uri,
      fileMatch = { bufuri },
      force = true,
    }

    log.debug("set new override: file=%s schema=%s adapter=%s", bufuri, params, M.name)

    ---@diagnostic disable-next-line: param-type-mismatch
    client:notify("tombi/associateSchema", params)
  end

  log.debug("notified client of configuration changes: file=%s adapter=%s client_id=%d #schemas=%d", bufuri, M.name, client.id, #schemas)
end

function M:get_schemas_from_lsp()
  local client = self:get_client()

  local response = require("schema-companion.lsp").request_sync(client, "tombi/listSchemas", {}) or {}
  local schemas = parse_schemas(response.schemas or {})

  log.debug("get schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

function M:match_schema_from_lsp(bufnr)
  local client = self:get_client()

  local response = require("schema-companion.lsp").request_sync(client, "tombi/getStatus", { uri = vim.uri_from_bufnr(bufnr) }, bufnr) or {}

  local schemas = {}
  if response.schema then
    schemas = parse_schemas({ response.schema })
  end

  log.debug("match schemas from lsp: adapter_name=%s client_id=%d #schemas=%d", self.name, client.id, #schemas)

  return schemas
end

M.setup = require("schema-companion.adapters.metatable").new(M)

return M
