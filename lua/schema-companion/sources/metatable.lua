local log = require("schema-companion.log")
local deprecated = require("schema-companion.deprecated")

--- Wrap a source table to be callable, providing legacy setup() with deprecation warning.
--- apply(self, config) is invoked when calling the source.
---@param source schema_companion.Source
---@param apply fun(self: schema_companion.Source, config?: table)|nil
---@return schema_companion.Source
return function(source, apply)
  apply = apply or function() end

  local mt = {}
  mt.__call = function(self, config)
    apply(self, config)
    return self
  end

  setmetatable(source, mt)

  source.setup = function(config)
    log.warn("schema-companion source.setup() is deprecated; call source directly instead: source_name=%s", source.name)
    deprecated.source_setup = true
    return mt.__call(source, config)
  end

  return source
end
