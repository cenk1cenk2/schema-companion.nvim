local schema_companion_builtin = require("telescope._extensions.schema_companion_builtin")

return require("telescope").register_extension({
  exports = {
    select_schema = schema_companion_builtin.select_schema,
  },
})
