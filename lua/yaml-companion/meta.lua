---@meta

---@class vim.lsp.client
---@field id number
---@field name string
---@field server_capabilities table
---@field config table
---@field workspace_did_change_configuration fun(settings: table)
---@field request_sync fun(method: string, params: table | nil, timeout_ms: number | nil, bufnr: number): { err: string, result: string} | nil, string

---@class Schema
---@field name string | nil
---@field uri string

---@alias SchemaResult { result: Schema[] }

---@class Matcher
---@field match fun(bufnr: number): Schema | nil
---@field handles fun(): Schema[]
---@field health fun()
---@field name string
---@field config? table
---@field setup? fun(table): Matcher

---@class ConfigOptions
---@field log_level "debug" | "trace" | "info" | "warn" | "error" | "fatal"
---@field formatting boolean
---@field schemas Schema[] | SchemaResult
---@field matchers Matcher[]

---@class Logger
---@field debug fun(fmt: string, ...: any)
---@field error fun(fmt: string, ...: any)
---@field warn fun(message: string)
