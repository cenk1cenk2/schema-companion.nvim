local health = vim.health

local M = {}

local plugins = {
  { lib = "plenary", optional = false },
  { lib = "telescope", optional = true, info = "Install to use the telescope schema picker" },
  { lib = "lspconfig", optional = false },
}

local binaries = {
  { bin = "yaml-language-server", optional = false },
}

local binary_installed = function(binary)
  return vim.fn.executable(binary)
end

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

function M.check()
  for _, binary in ipairs(binaries) do
    if not binary_installed(binary.bin) then
      local bin_not_installed = binary.bin .. " not found"
      if binary.optional then
        health.warn(("%s %s"):format(bin_not_installed, binary.info))
      else
        health.error(binary.bin .. " not found")
      end
    else
      health.ok(binary.bin .. " found")
    end
  end

  health.start("Checking for plugins")
  for _, plugin in ipairs(plugins) do
    if lualib_installed(plugin.lib) then
      health.ok(plugin.lib .. " installed")
    else
      local lib_not_installed = plugin.lib .. " not found"
      if plugin.optional then
        health.warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
        health.error(lib_not_installed)
      end
    end
  end

  for _, matcher in ipairs(require("schema-companion.matchers").get()) do
    health.start(string.format("Matcher: %s", matcher.name))
    matcher.health()
  end
end

return M
