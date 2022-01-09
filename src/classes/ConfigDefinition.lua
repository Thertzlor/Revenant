local rv = ...---@type Revenant
local next, type, gsub = next, type, string.gsub
---@class ConfigDefinition:BaseClass
---@field finalConfig OptionsCollection
local ConfigDefinition = rv.baseClass:new()

---@param a OptionsCollection
---@param b OptionsCollection
---@param isDefault boolean
function ConfigDefinition:mergeConfigs(a, b, isDefault)
    local replace = a.preventOptionOverride ~= nil and a.preventOptionOverride
    if isDefault then replace = false end
    return rv.tbl:intersectSimple(a, b, replace)
end

---@protected
---@param baseData OptionsCollection|string
---@param stack string[]
---@param basePath string
function ConfigDefinition:constructor(baseData, stack, basePath)
    if baseData == nil then
        self.finalConfig = {}
        return
    end
    local abs = rv.paths.absoluteConfigPaths
    self.stack = stack or {}
    self.external = type(baseData) == "string"
    if self.external then
        rv:put('importing', baseData)
        self.stack[#self.stack + 1] = baseData
        self.base = rv:import(baseData, function() rv:put("could not import" .. baseData) end)
    else self.base = baseData end
    self.finalConfig = self.base
    
    self.parents = {}
    local parentData = self.base and self.base.externalConfigs
    if parentData then
        if basePath == "origin" and not abs then rv:put("INVALID ERROR ERROR ERROR") end
        if type(parentData) == "string" then parentData = { parentData } end
        for i = 1, #parentData do local p = parentData[i]
            self.parents[#self.parents + 1] = ConfigDefinition:new((type(p) == "table" and p) or ((abs and '' or basePath) .. p), stack, (abs and gsub(p, "[^\\/]+$", "") or basePath)).finalConfig
        end
    end
    for i = 1, #self.parents do
        self.finalConfig = self:mergeConfigs(self.finalConfig, self.parents[i])
    end
end

---@return OptionsCollection
function ConfigDefinition:outputFinalized()
    return self:mergeConfigs(self.finalConfig,rv.defaultConfig,true)
end

return ConfigDefinition