---@meta

error("Can not source metafile.")

---@class schema_companion.Schema
---@field name? string
---@field uri? string
---@field description? string

---@class schema_companion.Matcher: table
---@field match schema_companion.MatcherMatchFn
---@field handles schema_companion.MatcherHandlesFn
---@field health schema_companion.MatcherHealthFn
---@field name string
---@field config? table
---@field setup? schema_companion.MatcherSetupFn

---@alias schema_companion.MatcherMatchFn fun(bufnr: number): schema_companion.Schema | nil
---@alias schema_companion.MatcherHandlesFn fun(): schema_companion.Schema[]
---@alias schema_companion.MatcherHealthFn fun()
---@alias schema_companion.MatcherSetupFn fun(table?): schema_companion.Matcher

---@class schema_companion.Config
---@field enable_telescope boolean
---@field schemas schema_companion.Schema[]
---@field matchers schema_companion.Matcher[]

---@class schema_companion.Logger
---@field new schema_companion.LoggerNew
---@field config schema_companion.LoggerConfig
---@field trace fun(fmt: string, ...: any)
---@field debug fun(fmt: string, ...: any)
---@field info fun(fmt: string, ...: any)
---@field warn fun(fmt: string, ...: any)
---@field error fun(fmt: string, ...: any)
---@field fatal fun(fmt: string, ...: any)
