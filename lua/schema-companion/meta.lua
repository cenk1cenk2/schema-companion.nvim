---@meta

---@class Schema
---@field name? string
---@field uri string
---@field description? string

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
---@field enable_telescope boolean
---@field schemas Schema[]
---@field matchers Matcher[]

---@class Logger
---@field trace fun(fmt: string, ...: any)
---@field debug fun(fmt: string, ...: any)
---@field info fun(fmt: string, ...: any)
---@field warn fun(fmt: string, ...: any)
---@field error fun(fmt: string, ...: any)
---@field fatal fun(fmt: string, ...: any)
