---@meta

error("Can not source metafile.")

---@class schema_companion.Schema
---@field name? string
---@field uri? string
---@field description? string
---@field client_id? number

---@alias schema_companion.HealthFn fun()

---@class schema_companion.Matcher: table
---@field name string
---@field config? table
---@field setup? schema_companion.MatcherSetupFn
---@field health? schema_companion.HealthFn
---@field match schema_companion.MatcherMatchFn
---@field get_schemas schema_companion.MatcherGetSchemasFn

---@alias schema_companion.MatcherSetupFn fun(table?): schema_companion.Matcher
---@alias schema_companion.MatcherMatchFn fun(bufnr: number): schema_companion.Schema[] | nil
---@alias schema_companion.MatcherGetSchemasFn fun(): schema_companion.Schema[]

---@class schema_companion.Adapter: table
---@field ctx schema_companion.AdapterCtx
---@field name string
---@field config? table
---@field setup? schema_companion.AdapterSetupFn
---@field health? schema_companion.HealthFn
---@field on_setup_client schema_companion.AdapterOnSetupClientFn
---@field on_update_schemas schema_companion.AdapterOnUpdateSchemaFn
---@field client vim.lsp.Client
---@field set_client fun(self: schema_companion.Adapter, client: vim.lsp.Client): vim.lsp.Client
---@field get_client fun(self: schema_companion.Adapter): vim.lsp.Client
---@field get_sources schema_companion.AdapterGetSourcesFn
---@field get_matchers schema_companion.AdapterGetMatchersFn
---@field get_schemas_from_config schema_companion.AdapterGetSchemasFn
---@field get_schemas_from_lsp schema_companion.AdapterGetSchemasFn
---@field get_schemas_from_matchers schema_companion.AdapterGetSchemasFn
---@field match_schema_from_lsp fun(self: schema_companion.Adapter, bufnr: number): schema_companion.Schema[]

---@class schema_companion.AdapterConfig
---@field schemas? schema_companion.Schema[] | fun(): schema_companion.Schema[]
---@field matchers? schema_companion.Matcher[] | fun(): schema_companion.Matcher[]
---@field sources? schema_companion.Source[] | fun(): schema_companion.Source[]

---@class schema_companion.AdapterCtx
---@field sources schema_companion.Source[]
---@field matchers schema_companion.Matcher[]
---@field schemas schema_companion.Schema[]

---@alias schema_companion.AdapterSetupFn fun(config: schema_companion.AdapterConfig): schema_companion.Adapter
---@alias schema_companion.AdapterOnSetupClientFn fun(self: schema_companion.Adapter, config: vim.lsp.ClientConfig): vim.lsp.ClientConfig
---@alias schema_companion.AdapterOnUpdateSchemaFn fun(self: schema_companion.Adapter, bufnr: number, schemas: schema_companion.Schema[]): vim.lsp.Client
---@alias schema_companion.AdapterGetSourcesFn fun(self: schema_companion.Adapter): schema_companion.Source[]
---@alias schema_companion.AdapterGetMatchersFn fun(self: schema_companion.Adapter): schema_companion.Matcher[]
---@alias schema_companion.AdapterGetSchemasFn fun(self: schema_companion.Adapter): schema_companion.Schema[]

---@class schema_companion.Source: table
---@field name string
---@field config? table
---@field setup? schema_companion.SourceSetupFn
---@field health? schema_companion.HealthFn
---@field match schema_companion.SourceMatchFn
---@field get_schemas schema_companion.SourceGetSchemasFn

---@alias schema_companion.SourceSetupFn fun(table?): schema_companion.Source
---@alias schema_companion.SourceMatchFn fun(ctx: schema_companion.Context, bufnr?: number): schema_companion.Schema[]
---@alias schema_companion.SourceGetSchemasFn fun(ctx: schema_companion.Context): schema_companion.Schema[]

---@class schema_companion.Context
---@field adapter schema_companion.Adapter
---@field schemas schema_companion.Schema[]
---@field _discovered boolean
