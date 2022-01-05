local rv = ...---@type MainLibObject
local next, type, concat, error, gsub, pairs = next, type, table.concat, error, string.gsub, pairs
---@class ConfigDefinition:BaseClass
---@field finalConfig OptionsCollection
local ConfigDefinition = rv.baseClass:new()
local function _extractOptions(key, a, b)
    local propA = a[key]
    local propB = b[key]
    a[key] = nil
    b[key] = nil
    return propA, propB
end

---@param a OptionsCollection
---@param b OptionsCollection
---@param isDefault boolean
function ConfigDefinition:mergeConfigs(a, b, isDefault)
    local replace = a.handleOptionConflicts == "replaceDuplicates"
    if isDefault then replace = false end
    self.finalConfig = rv.tbl:intersectSimple(a, b, replace)
end

---@protected
---@param baseData OptionsCollection|string
---@param stack string[]
---@param basePath string
---@param init boolean
function ConfigDefinition:constructor(baseData, stack, basePath, init)
    if baseData == nil then
        self.finalConfig = rv.defaultConfig
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
            self.parents[#self.parents + 1] = ConfigDefinition:new((type(p) == "table" and p) or ((abs and '' or basePath) .. p), stack, (abs and gsub(p, "[^\\/]+$", "") or basePath)):output()
        end
    end
    for i = 1, #self.parents do
        self:mergeConfigs(self.finalConfig, self.parents[i])
    end
    if init then
        self:mergeConfigs(self.finalConfig, rv.defaultConfig, true)
    end
end

function ConfigDefinition:output()
    if next(self.finalConfig) then return self.finalConfig end
    return false
end

return ConfigDefinition