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
  get_sources = function(self)
    return self.ctx.sources
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

local function initialize_sources(self, config)
  config = config or {}
  self.ctx = self.ctx or {}
  self.ctx.sources = utils.evaluate_property(config.sources) or {
    require("schema-companion.sources").lsp(),
  }
  log.debug(
    "adapter sources loaded: adapter_name=%s sources=%s",
    self.name,
    vim.tbl_map(function(source)
      return source.name
    end, self.ctx.sources)
  )
end

return {
  new = function(self)
    self = setmetatable(self, {
      __call = function(_, config)
        initialize_sources(self, config)
        if config then
          config.sources = nil
        end
        return self:on_setup_client(config or {})
      end,
    })
    self = vim.tbl_extend("keep", self, adapter)

    -- legacy setup function for backward compatibility
    self.setup = function(config)
      log.warn("schema-companion adapter.setup is deprecated; call adapter directly instead: adapter_name=%s", self.name)
      require("schema-companion.deprecated").adapter_setup = true
      initialize_sources(self, config)
      return self
    end

    return self
  end,
}
