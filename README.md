# schema-companion.nvim

**Forked from the original repository [someone-stole-my-name/yaml-companion.nvim](https://github.com/someone-stole-my-name/yaml-companion.nvim) and expanded for a bit more modularity.**

> [!IMPORTANT]
> This plugin has been rewritten to be more modular and extendable. All the setup and configuration of the repository has changed. You can use the `legacy` branch if you want to use the old version while migrating.

## Features

- Works and intended to work with multiple language servers. Adapter based system, where you can define different configurations per language server.
- Can match multiple schemas at the same time, where the user can narrow down between the candidates.
- Supports arbitrary matchers to detect schema based on content.
  - Kubernetes resources can be matched utilizing the repository [yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema). ![kubernetes](./media/kubernetes.png)
  - Kubernetes CRD definitions can be matched utilizing the repository [datreeio/CRDs-catalog](https://github.com/datreeio/crds-catalog). ![kubernetes-crd](./media/kubernetes-crd.png)

## Installation

### lazy.nvim

```lua
return {
  "cenk1cenk2/schema-companion.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
}
```

## Configuration

Plugin has to be configured once, and the language servers can be added by extending the LSP configuration.

**If you do not configure the language server with the adapter, the plugin will not work for the given language server.**

> [!WARNING]
> Legacy `schema-companion.setup_client()` and `adapter.setup()` are deprecated and will emit warnings.
> Call adapters directly; they are now callable and return the finalized LSP configuration. 

> [!IMPORTANT]
> THIS PLUGIN IS A LITTLE BIT MORE INVOLVED THAN AVERAGE PLUGIN, PLEASE FOLLOW THE INSTRUCTIONS CAREFULLY.

### Setup

The default plugin configuration for the setup function is as below.

```lua
require("schema-companion").setup({
  log_level = vim.log.levels.INFO,
})
```

### Language Server Configuration

The plugin has an adapter based system, where you can define different configurations per language server.

#### LSP Overlay Method

> [!WARNING]
> Please make sure to use the `./after/lsp` directory to load your language server configurations, because in some cases like this [issue](https://github.com/cenk1cenk2/schema-companion.nvim/issues/24), something else might overwrite it and the plugin will not function correctly.

##### Yaml Language Server

```lua
-- ./after/lsp/yamlls.lua
local sc = require("schema-companion")
return sc.adapters.yamlls({
  sources = {
    sc.sources.matchers.kubernetes.setup({ version = "master" }),
    sc.sources.lsp.setup(),
    sc.sources.schemas.setup({
      {
        name = "Kubernetes master",
        uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json",
      },
    }),
  },
  --- your language server configuration (settings, init_options, capabilities...)
  settings = {},
})
```

##### Helm Language Server

```lua
-- ./after/lsp/helm_ls.lua
local sc = require("schema-companion")
return sc.adapters.helmls({
  sources = {
    sc.sources.matchers.kubernetes.setup({ version = "master" }),
  },
  --- your language server configuration (settings, init_options, capabilities...)
  settings = {},
})
```

##### Json Language Server

```lua
-- ./after/lsp/jsonls.lua
local sc = require("schema-companion")
return sc.adapters.jsonls({
  sources = {
    sc.sources.lsp.setup(),
    sc.sources.none.setup(),
  },
  --- your language server configuration (settings, init_options, capabilities...)
  settings = {},
})
```

##### Taplo

```lua
-- ./after/lsp/taplo.lua
local sc = require("schema-companion")
return sc.adapters.taplo({
  sources = {
    sc.sources.lsp.setup(),
    sc.sources.none.setup(),
  },
  --- your language server configuration (settings, init_options, capabilities...)
  settings = {},
})
```

#### `vim.lsp.config()` Method

##### Yaml Language Server

```lua
local sc = require("schema-companion")
vim.lsp.comfig("yamlls", sc.adapters.yamlls({
  sources = {
    sc.sources.matchers.kubernetes.setup({ version = "master" }),
    sc.sources.lsp.setup(),
    sc.sources.schemas.setup({
      {
        name = "Kubernetes master",
        uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json",
      },
    }),
  },
  --- your language server configuration (settings, init_options, capabilities...)
}))
```

##### Helm Language Server

```lua
local sc = require("schema-companion")
vim.lsp.config("helm_ls", sc.adapters.helmls({
  sources = {
    sc.sources.matchers.kubernetes.setup({ version = "master" }),
  },
  --- your language server configuration (settings, init_options, capabilities...)
}))
```

##### Json Language Server

```lua
local sc = require("schema-companion")
vim.lsp.config("jsonls", sc.adapters.jsonls({
  sources = {
    sc.sources.lsp.setup(),
    sc.sources.none.setup(),
  },
  --- your language server configuration (settings, init_options, capabilities...)
}))
```

##### Taplo

```lua
local sc = require("schema-companion")
vim.lsp.config("taplo", sc.adapters.taplo({
  sources = {
    sc.sources.lsp.setup(),
    sc.sources.none.setup(),
  },
  --- your language server configuration (settings, init_options, capabilities...)
}))
```

#### LSP Config Method (deprecated)

You can also use the `lspconfig` method to setup the language server, where the same methodology applies.

```lua
require("lspconfig").yamlls.setup(require("schema-companion").adapters.yamlls({
  -- your yaml language server configuration
}))
```

### Adapters

You can use specific adapters or bring your own adapter to implement schema support for a given language server.

Adapter is responsible for following.

- Hooking the LSP for schema companion to initiate it.
- Communicating with the LSP to get available or current schemas.
- Updating the configuration of LSP on schema changes.

**Every language server is supposed to have its own adapter to function properly.**

Available adapters for the plugin is as follows.

- `require("schema-companion").adapters.yamlls()`
- `require("schema-companion").adapters.helmls()`
- `require("schema-companion").adapters.jsonls()`
- `require("schema-companion").adapters.taplo()`

### Migration

Old:
```lua
return require("schema-companion").setup_client(
  require("schema-companion").adapters.yamlls.setup({
    sources = {...}
  }),
  {
    settings = {...}, 
    init_options = {...},
    ...
  }
)
```
New:
```lua
local sc = require("schema-companion")
return sc.adapters.yamlls({
  sources = { ... },
  settings = { ... },
  init_options = { ... },
  ...
})
```
Health check warns only if old API used.

> [!NOTE]
> WITH THE CURRENT MODULAR ARCHITECTURE REALLY REALLY WILL APPRECIATE ANY CONTRIBITIONS.

### Sources

Sources can be added into adapters which implies that for a given adapter they are provider of schemas. Therefore sources can be configured per language server.

Whenever you call the setup function of the adapter, you can pass the source provider to given language server configuration.

Available sources for the plugin is as follows.

#### LSP

To enable language server implicitly using schemas provided by the language server you have to load the given source.

```lua
sources = {
  -- your sources for the language server
  require("schema-companion").sources.lsp.setup()
},
```

#### Schemas

You can provide static set of schemas where you do want to only manual selection with it, you can use the schemas source.

```lua
sources = {
  -- your sources for the language server
  require("schema-companion").sources.schemas.setup({
    {
      name = "Kubernetes v1.29",
      uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.7-standalone-strict/all.json",
    },
    {
      name = "Kubernetes v1.30",
      uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.3-standalone-strict/all.json",
    },
  })
},
```

#### Matchers

Matchers are custom functionality that behaves and matches a schema depending on the content of the file.

Available matchers for the plugin is as follows.

##### Kubernetes

```lua
sources = {
  -- your sources for the language server
  require("schema-companion").sources.matchers.kubernetes.setup({
    version = "master"
  })
},
```

#### None

None source provides a way to reset the current schema to `none`.

```lua
sources = {
  -- your sources for the language server
  require("schema-companion").sources.none.setup()
},
```

## Usage

### Select From All Available Schemas

You can select the schema of your desired choice from a list of schemas and apply it to the current buffer.

```lua
require("schema-companion").select_schema()
```

### Select From Matching Schemas

If there are multiple matches for the buffer, you can select the schema manually from the ones that matches.

```lua
require("schema-companion").select_from_matching_schema()
```

### Current Schema

```lua
local schema = require("schema-companion").get_current_schemas()
```

This can be further utilized in `lualine` as follows.

```lua
-- your lualine configuration
require("lualine").setup({
  sections = {
    lualine_c = {
      {
        function()
          return ("%s %s"):format(nvim.ui.icons.ui.Table, require("schema-companion").get_current_schemas() or "none"):sub(0, 128)
        end,
        cond = function()
          return package.loaded["schema-companion"]
        end,
      },
    },
  },
})
```

### Rematch for Buffer

In some cases you want to create your yaml file from scratch, instead of reloading the buffer you can also trigger match process again.

```lua
--- force the match to not use the current schema
require("schema-companion").match()
```
