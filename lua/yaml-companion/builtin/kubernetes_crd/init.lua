local M = {}

local api = vim.api
local uri = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main"
local builtInVersion = require("yaml-companion.builtin.kubernetes.version")
local builtInResources = require("yaml-companion.builtin.kubernetes.resources")
local builtInSchemaURI = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/" ..
builtInVersion .. "-standalone-strict/all.json"

-- extractGroupVersionKind extracts the group, version, and kind from the buffer.
-- @param bufnr The buffer number.
-- @returns The group, version, and kind.
M.extractGroupVersionKind = function(bufnr)
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local group = ""
    local version = ""
    local kind = ""
    local groupVersionRegex = vim.regex("^apiVersion:\\s\\+")
    local kindRegex = vim.regex("^kind:\\s\\+")

    for _, line in ipairs(lines) do
        if groupVersionRegex:match_str(line) then
            local _,e = groupVersionRegex:match_str(line)
            local groupVersion = line:sub(e+1)
            local parts = vim.split(groupVersion, "/")
            if #parts == 2 then
                group = parts[1]
                version = parts[2]
            end
        end
        if kindRegex:match_str(line) then
            local _,e = kindRegex:match_str(line)
            kind = line:sub(e+1)
        end
        if group ~= "" and version ~= "" and kind ~= "" then
            break
        end
    end
    return group, version, kind
end

-- isBuiltInResource checks if the resource is a built-in resource.
-- @param kind The kind.
-- @returns True if the resource is a built-in resource, false otherwise.
local function isBuiltInResource(kind)
    for _, resource in ipairs(builtInResources) do
        if kind == resource then
            return true
        end
    end
    return false
end

M.match = function(bufnr)
    local group, version, kind = M.extractGroupVersionKind(bufnr)
    if group == "" or version == "" or kind == "" then
        return nil
    end


    if isBuiltInResource(kind) then
        local schema = {
            name = "Kubernetes",
            uri = builtInSchemaURI,
        }
        return schema
    end

    local schema = {
        name = "KubernetesCRD",
        uri = uri .. "/" .. group:lower() .. "/" .. kind:lower() .. "_" .. version:lower() .. ".json",
    }
    return schema
end

return M
