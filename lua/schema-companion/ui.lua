local M = {}

function M.select_schema()
  local schemas = require("schema-companion.schema").all()

  -- Don't open selection if there are no available schemas
  if #schemas == 0 then
    return
  end

  vim.ui.select(schemas, {
    format_item = function(schema)
      return schema.name or schema.uri
    end,
    prompt = "Select YAML Schema",
  }, function(schema)
    if not schema then
      return
    end
    local selected_schema = { name = schema.name, uri = schema.uri }
    require("schema-companion.context").schema(0, selected_schema)
  end)
end

return M
