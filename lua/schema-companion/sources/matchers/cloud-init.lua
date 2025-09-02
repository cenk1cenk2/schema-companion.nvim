---@class schema_companion.Matcher
local M = {}

M.name = "Cloud-Init"

M.config = {}

---
---@param config table
---@return schema_companion.Matcher
function M.setup(config)
  setmetatable(M, {})
  M.config = vim.tbl_deep_extend("force", {}, M.config, config)

  return M
end

function M:match(_, bufnr)
  if vim.regex("^#cloud-config"):match_str(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]) then
    return {
      {
        name = "cloud-init",
        uri = "https://raw.githubusercontent.com/canonical/cloud-init/main/cloudinit/config/schemas/versions.schema.cloud-config.json",
      },
    }
  end
end

return M
