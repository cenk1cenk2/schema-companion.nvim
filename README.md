# schema-companion.nvim

**Forked from the original repository [someone-stole-my-name/yaml-companion.nvim](https://github.com/someone-stole-my-name/yaml-companion.nvim) and expanded for a bit more modularity.**

## IMPORTANT NOTICE

**This plugin has been rewritten to be more modular and extendable. All the setup and configuration of the repository has changed. You can use the `legacy` branch if you want to use the old version while migrating.**

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
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  config = function()
    -- PLEASE FOLLOW THE CONFIGURATION INSTRUCTIONS BELOW SINCE THERE IS AN ADDITIONAL STEP NEEDED FOR EACH LANGUAGE SERVER
    require("schema-companion").setup({})
  end,
}
```

## Configuration

Plugin has to be configured once, and the language servers can be added by extending the LSP configuration.

**If you do not configure the language server with the `setup_client` function, the plugin will not work for the given language server.**

**THIS PLUGIN IS A LITTLE BIT MORE INVOLVED THAN AVERAGE PLUGIN, PLEASE FOLLOW THE INSTRUCTIONS CAREFULLY.**

### Setup

The default plugin configuration for the setup function is as below.

```lua
require("schema-companion").setup({
  log_level = vim.log.levels.INFO,
})
```

### Language Server Configuration

You can automatically extend your configuration of the language server by wrapping it with `schema-companion.setup_client` function.

Plugin has an adapter based system, where you can define different configurations per language server.

#### LSP Overlay Method

##### YAMLLS

```lua
-- your LSP file: ./after/lsp/yamlls.lua
return require("schema-companion").setup_client(
  require("schema-companion").adapters.yamlls.setup({
    sources = {
      -- your sources for the language server
      require("schema-companion").sources.matchers.kubernetes.setup({ version = "master" }),
      require("schema-companion").sources.lsp.setup(),
      require("schema-companion").sources.schemas.setup({
        {
          name = "Kubernetes master",
          uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json",
        },
      }),
    },
  }),
  {
    --- your yaml language server configuration
  }
)
```

##### HELMLS

```lua
-- your LSP file: ./after/lsp/helm_ls.lua
return require("schema-companion").setup_client(
  require("schema-companion").adapters.helmls.setup({
    sources = {
      -- your sources for the language server
      require("schema-companion").sources.matchers.kubernetes.setup({ version = "master" }),
    },
  }),
  {
    --- your language server configuration
  }
)
```

##### JSONLS

```lua
-- your LSP file: ./after/lsp/jsonls.lua
return require("schema-companion").setup_client(
  require("schema-companion").adapters.jsonls.setup({
    sources = {
      require("schema-companion").sources.lsp.setup(),
    },
  }),
  {
    --- your language server configuration
  }
)
```

#### LSP Config Method (deprecated)

You can also use the `lspconfig` method to setup the language server, where the same methodology applies.

```lua
require("lspconfig").yamlls.setup(require("schema-companion").setup_client(adapter, {
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

- `require("schema-companion").adapters.yamlls.setup()`
- `require("schema-companion").adapters.helmls.setup()`
- `require("schema-companion").adapters.jsonls.setup()`

### Sources

Sources can be added into adapters which implies that for a given adapter they are provider of schemas. Therefore sources can be configured per language server.

Whenever you call the setup function of the adapter, you can pass the source provider to given language server configuration.

Available sources for the plugin is as follows.

#### LSP

To enable language server implicilitly using schemas provided by the language server you have to load the given source.

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
