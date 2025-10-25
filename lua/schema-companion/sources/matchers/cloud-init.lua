---@class schema_companion.Source
local M = {}

local wrap = require("schema-companion.sources.metatable")

M.name = "Cloud-Init"

M.config = {}

local function apply(self, config)
  if config then
    self.config = vim.tbl_deep_extend("force", {}, self.config, config)
  end
end

function M:match(_, bufnr)
  if vim.regex("^#cloud-config"):match_str(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]) then
    return {
      {
        name = "cloud-init",
        uri = "https://raw.githubusercontent.com/canonical/cloud-init/main/cloudinit/config/schemas/versions.schema.cloud-config.json",
        source = M.name,
      },
    }
  end
end

return wrap(M, apply)
