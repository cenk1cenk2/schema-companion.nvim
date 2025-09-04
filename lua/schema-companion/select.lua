local M = {}

---@param item schema_companion.EnrichedSchema
---@return string
local function format_item(item)
  return ("%s (%s)"):format(item.name or item.description or item.uri, item.source or "unknown")
end

---
---@param bufnr? number
function M.select_schema(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local schema = require("schema-companion.schema")

  vim.ui.select(schema.get_schemas(bufnr) or {}, {
    prompt = "Select a schema:",
    format_item = format_item,
  }, function(item)
    if not item then
      return
    end

    schema.set_schemas({
      item,
    })
  end)
end

function M.select_matching_schema(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local schema = require("schema-companion.schema")

  vim.ui.select(schema.get_matching_schemas(bufnr) or {}, {
    prompt = "Select from matching schemas:",
    format_item = format_item,
  }, function(item)
    if not item then
      return
    end

    schema.set_schemas({
      item,
    })
  end)
end

return M
