---@diagnostic disable: missing-fields
local utils = require("schema-companion.utils")
local log = require("schema-companion.log")

---@type schema_companion.Adapter
---@diagnostic disable-next-line: missing-fields
local adapter = {
  set_client = function(self, client)
    self.client = client
    log.debug("adapter client set: adapter_name=%s client_id=%d", self.name, self.client.id)

    return self
  end,
  get_client = function(self)
    if not self.client then
      error(("adapter client not set: adapter_name=%s"):format(self.name))
    end

    return self.client
  end,
  get_matchers = function(self)
    return self.ctx.matchers
  end,
  get_sources = function(self)
    return self.ctx.sources
  end,
  get_schemas_from_config = function(self)
    return self.ctx.schemas
  end,
  get_schemas_from_matchers = function(self)
    local bufnr = vim.api.nvim_get_current_buf()
    local schemas = {}

    for _, matcher in pairs(self:get_matchers()) do
      local matched = matcher.get_schemas() or {}

      log.debug("adapter matcher matched: adapter_name=%s matcher_name=%s bufnr=%d schema_count=%d", self.name, matcher.name, bufnr, #matched)

      vim.list_extend(schemas, matched)
    end

    return schemas
  end,
  get_schemas_from_lsp = function(self)
    log.debug("adapter get schemas from lsp, not implemented by default: adapter_name=%s", self.name)

    return {}
  end,
  match_schema_from_lsp = function(self)
    log.debug("adapter match schema from lsp, not implemented by default: adapter_name=%s", self.name)

    return {}
  end,
}

return {
  new = function(self)
    self = setmetatable(self, {})
    self = vim.tbl_extend("keep", self, adapter)

    return function(config)
      self.ctx = {}

      self.ctx.sources = utils.evaluate_property(config.sources) or {}
      log.debug(
        "adapter sources loaded: adapter_name=%s sources=%s",
        self.name,
        vim.tbl_map(function(source)
          return source.name
        end, self.ctx.sources)
      )
      self.ctx.matchers = utils.evaluate_property(config.matchers) or {}
      log.debug(
        "adapter matchers loaded: adapter_name=%s matchers=%s",
        self.name,
        vim.tbl_map(function(matcher)
          return matcher.name
        end, self.ctx.matchers)
      )
      self.ctx.schemas = utils.evaluate_property(config.schemas) or {}
      log.debug("adapter schemas loaded: adapter_name=%s schema_count=%d", self.name, #self.ctx.schemas)

      log.debug("adapter setup completed: adapter_name=%s", self.name)

      return self
    end
  end,
}
