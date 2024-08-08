local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local build_select_picker = function(title, results, bufnr, opts)
  opts = opts or {}
  return pickers
    .new(opts, {
      prompt_title = title,
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name or entry.uri,
            ordinal = entry.name or entry.uri,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = action_state.get_selected_entry()
          local schema = { name = selection.value.name or selection.value.uri, uri = selection.value.uri }

          require("schema-companion.context").schema(bufnr, schema)
        end)
        return true
      end,
    })
    :find()
end

function M.select_schema(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local results = require("schema-companion.schema").all()

  if #results == 0 then
    return
  end

  return build_select_picker("Schema", results, bufnr, require("telescope.themes").get_dropdown(opts))
end

function M.select_from_matching_schemas(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local results = require("schema-companion.schema").matching(bufnr)

  if not results then
    return
  end

  return build_select_picker("Buffer Matching Schemas", results, bufnr, require("telescope.themes").get_dropdown(opts))
end

return M
