---@meta

error("Can not source metafile.")

---@class schema_companion.Schema
---@field name? string
---@field uri? string
---@field description? string

---@class schema_companion.EnrichedSchema: schema_companion.Schema
---@field bufnr? number
---@field client_id? number

---@class schema_companion.Source: table
---@field name string
---@field config? table
---@field setup schema_companion.SourceSetupFn
---@field health? schema_companion.HealthFn
---@field match? schema_companion.SourceMatchFn
---@field get_schemas? schema_companion.SourceGetSchemasFn

---@alias schema_companion.SourceSetupFn fun(table?): schema_companion.Source
---@alias schema_companion.SourceMatchFn fun(self: schema_companion.Source, ctx: schema_companion.Context, bufnr?: number): schema_companion.Schema[]
---@alias schema_companion.SourceGetSchemasFn fun(self: schema_companion.Source, ctx: schema_companion.Context): schema_companion.Schema[]

---@class schema_companion.Adapter: table
---@field ctx schema_companion.AdapterCtx
---@field name string
---@field config? table
---@field setup schema_companion.AdapterSetupFn
---@field health? schema_companion.HealthFn
---@field client vim.lsp.Client
---@field set_client fun(self: schema_companion.Adapter, client: vim.lsp.Client): vim.lsp.Client
---@field get_client fun(self: schema_companion.Adapter): vim.lsp.Client
---@field get_schemas_from_lsp schema_companion.AdapterGetSchemasFn
---@field match_schema_from_lsp fun(self: schema_companion.Adapter, bufnr: number): schema_companion.Schema[]
---@field on_setup_client schema_companion.AdapterOnSetupClientFn
---@field on_update_schemas schema_companion.AdapterOnUpdateSchemaFn
---@field get_sources schema_companion.AdapterGetSourcesFn

---@class schema_companion.AdapterConfig
---@field sources? schema_companion.Source[] | fun(): schema_companion.Source[]

---@class schema_companion.AdapterCtx
---@field sources schema_companion.Source[]

---@alias schema_companion.AdapterSetupFn fun(config: schema_companion.AdapterConfig): schema_companion.Adapter
---@alias schema_companion.AdapterOnSetupClientFn fun(self: schema_companion.Adapter, config: vim.lsp.ClientConfig): vim.lsp.ClientConfig
---@alias schema_companion.AdapterOnUpdateSchemaFn fun(self: schema_companion.Adapter, bufnr: number, schemas: schema_companion.Schema[]): vim.lsp.Client
---@alias schema_companion.AdapterGetSourcesFn fun(self: schema_companion.Adapter): schema_companion.Source[]
---@alias schema_companion.AdapterGetSchemasFn fun(self: schema_companion.Adapter): schema_companion.Schema[]

---@class schema_companion.Context
---@field adapter schema_companion.Adapter
---@field schemas schema_companion.Schema[]
---@field _discovered boolean

---@alias schema_companion.HealthFn fun()
