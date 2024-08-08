local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local select_schema = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local results = require("schema-companion.schema").all()

  if #results == 0 then
    return
  end

  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Schema",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local schema = { name = selection.value.name, uri = selection.value.uri }
          require("schema-companion.context").schema(bufnr, schema)
        end)
        return true
      end,
    })
    :find()
end

local select_buffer_matching_schema = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local results = require("schema-companion.schema").matching(bufnr)

  if #results == 0 then
    return
  end

  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Matching Schemas",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local schema = { name = selection.value.name, uri = selection.value.uri }
          require("schema-companion.context").schema(bufnr, schema)
        end)
        return true
      end,
    })
    :find()
end

function M.select_schema(opts)
  select_schema(require("telescope.themes").get_dropdown(opts))
end

function M.select_buffer_matching_schema(opts)
  select_buffer_matching_schema(require("telescope.themes").get_dropdown(opts))
end

return M
