-- Internal deprecation usage tracking.
-- Flags are toggled when legacy APIs are invoked so health checks can warn.
local M = {
  adapter_setup = false,
  setup_client = false,
}

return M
