local rv = ... ---@type Revenant
local type, gsub, next = type, string.gsub, next
---A class for loading and containing the Revenant configuration of a profile
---@class ConfigDefinition:BaseClass
---@field finalConfig OptionsCollection
---@field base OptionsCollection
---@field parents OptionsCollection[]
local ConfigDefinition = rv.baseClass:new()

---Combine two Configurations into one.
---@param a OptionsCollection The first OptionsCollection
---@param b OptionsCollection The second OptionsCollection
---@param isDefault? boolean If true, preventOptionOverride is ignored on collection a
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
        local p = baseData:gsub("%.lua$", ""):gsub("$", ".lua")
        rv:put('Importing', p)
        self.stack[#self.stack + 1] = p
        local suc, ret = pcall(function() return rv.utils.lenientLoad(p) end)
        self.base = suc and ret or {} ---@cast baseData OptionsCollection
    else self.base = baseData end
    self.finalConfig = self.base
    self.parents = {}
    local parentData = self.base and self.base.externalConfigs
    local extensions = self.base.extends
    if extensions then
        if type(extensions) == "string" then extensions = { extensions } end
        for i = 1, #extensions do
            local fakeMacs = rv.utils.fakeProfileImport(basePath .. extensions[i])
            if fakeMacs and fakeMacs.config and next(fakeMacs.config) then
                if not parentData then parentData = {} end
                parentData[#parentData + 1] = fakeMacs.config
            end
        end
    end
    if parentData then
        if basePath == "origin" and not abs then rv:put("INVALID ERROR ERROR ERROR") end
        if type(parentData) == "string" then parentData = { parentData } end
        for i = 1, #parentData do local p = parentData[i]
            self.parents[#self.parents + 1] = ConfigDefinition:new((type(p) == "table" and p) or ((abs and '' or basePath) .. p), stack, (abs and type(p) == "string" and gsub(p, "[^\\/]+$", "") or basePath)).finalConfig
        end
    end
    for i = 1, #self.parents do
        self.finalConfig = self:mergeConfigs(self.finalConfig, self.parents[i])
    end
end

---@return OptionsCollection
function ConfigDefinition:outputFinalized()
    return self:mergeConfigs(self.finalConfig, rv.defaultConfig, true)
end

return ConfigDefinition
