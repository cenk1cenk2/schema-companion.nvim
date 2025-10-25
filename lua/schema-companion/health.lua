local M = {}

function M.check()
  local deprecated = require("schema-companion.deprecated")

  if deprecated.adapter_setup or deprecated.setup_client then
    local list = {}
    if deprecated.adapter_setup then
      table.insert(list, "adapter.setup()")
    end
    if deprecated.setup_client then
      table.insert(list, "setup_client()")
    end
    vim.health.warn(
      "Deprecated API used: " .. table.concat(list, ", ") .. ". Migrate to direct adapter call: require('schema-companion').adapters.yamlls{ sources = {...}, settings = {...} }"
    )
  else
    vim.health.ok("Using new direct adapter call API")
  end
end

return M
