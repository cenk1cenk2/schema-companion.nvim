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

---@class schema_companion.Adapter: table
---@field setup fun(self: schema_companion.Adapter, config: vim.lsp.ClientConfig): vim.lsp.ClientConfig
---@field update_schema fun(self: schema_companion.Adapter, client: vim.lsp.Client, bufnr: number, schema: schema_companion.Schema | schema_companion.Schema[]): vim.lsp.Client
