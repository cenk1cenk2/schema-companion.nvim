-- Inspired by rxi/log.lua
-- Modified by tjdevries and can be found at github.com/tjdevries/vlog.nvim
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.

local defaults = {
  plugin = "yaml.nvim",
  use_console = true,
  highlights = true,
  use_file = false,
  level = "info",
  modes = {
    { name = "trace", hl = "Comment" },
    { name = "debug", hl = "Comment" },
    { name = "info", hl = "None" },
    { name = "warn", hl = "WarningMsg" },
    { name = "error", hl = "ErrorMsg" },
    { name = "fatal", hl = "ErrorMsg" },
  },
  float_precision = 0.01,
}

---@class schema_companion.Logger
local M = {}

function M.new(config)
  config = vim.tbl_deep_extend("force", defaults, config)

  local levels = {}
  for i, v in ipairs(config.modes) do
    levels[v.name] = i
  end

  local log_at_level = function(level, level_config, message_maker, ...)
    -- Return early if we're below the config.level
    if level < levels[config.level] then
      return
    end
    local nameupper = level_config.name:upper()

    local msg = message_maker(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    if config.use_console then
      local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, msg)

      if config.highlights and level_config.hl then
        vim.cmd(string.format("echohl %s", level_config.hl))
      end

      local split_console = vim.split(console_string, "\n")
      for _, v in ipairs(split_console) do
        vim.cmd(string.format([[echom "[%s] %s"]], config.plugin, vim.fn.escape(v, '"')))
      end

      if config.highlights and level_config.hl then
        vim.cmd("echohl NONE")
      end
    end
  end

  for i, mode in pairs(config.modes) do
    M[mode.name] = function(...)
      return log_at_level(i, mode, function(...)
        local passed = { ... }
        local fmt = table.remove(passed, 1)
        local inspected = {}

        for _, v in ipairs(passed) do
          table.insert(inspected, vim.inspect(v))
        end

        return string.format(fmt, unpack(inspected))
      end, ...)
    end
  end

  return M
end

return M
