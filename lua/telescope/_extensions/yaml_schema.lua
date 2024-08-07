local yaml_schema_builtin = require("telescope._extensions.yaml_schema_builtin")

return require("telescope").register_extension({
  exports = {
    select_schema = yaml_schema_builtin.select_schema,
  },
})
