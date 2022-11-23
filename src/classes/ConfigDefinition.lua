local rv = ... ---@type Revenant
local type, gsub, next = type, string.gsub, next
---A class for loading and containing the Revenant configuration of a profile
---@class ConfigDefinition:BaseClass
---@field finalConfig OptionsCollection Final output once all potential parent configs have been loaded and merged
---@field base OptionsCollection Content of the current Options object
---@field parents OptionsCollection[] All parent profiles loaded before the current one
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
    if baseData == nil then --No data, no options
        self.finalConfig = {}
        return
    end
    local abs = rv.paths.absoluteConfigPaths
    self.stack = stack or {}
    self.external = type(baseData) == "string"
    if self.external then --Here we import the current external config file, if one has been specified
        local p = baseData:gsub("%.lua$", ""):gsub("$", ".lua")
        rv:put('Importing', p)
        self.stack[#self.stack + 1] = p ---Putting path into stack to prevent infinite loops
        local suc, ret = pcall(function() return rv.utils.lenientLoad(p) end)
        self.base = suc and ret or {}
    else self.base = baseData --[[@as OptionsCollection]] end
    self.finalConfig = self.base
    self.parents = {}
    local parentData = self.base and self.base.externalConfigs
    local extensions = self.base.extends
    if extensions then
        if type(extensions) == "string" then extensions = { extensions } end
        for i = 1, #extensions do --loading one or more "fake" profiles to serve as a base for parent imports
            local fakeMacs = rv.utils.fakeProfileImport(basePath .. extensions[i])
            if fakeMacs and fakeMacs.config and next(fakeMacs.config) then
                if not parentData then parentData = { fakeMacs.config }
                elseif type(parentData) == 'string' then parentData = { fakeMacs.config, parentData }
                else parentData[#parentData + 1] = fakeMacs.config end
            end --This needs to be simulated because the actual profile initializes after the config import
        end
    end
    if parentData then
        if basePath == "origin" and not abs then rv:put("INVALID ERROR ERROR ERROR") end
        if type(parentData) == "string" then parentData = { parentData } end
        for i = 1, #parentData do local p = parentData[i] --initializing parent profiles, but only keeping their final output
            self.parents[#self.parents + 1] = ConfigDefinition:new((type(p) == "table" and p) or ((abs and '' or basePath) .. p), stack, (abs and type(p) == "string" and gsub(p, "[^\\/]+$", "") or basePath)).finalConfig
        end
    end
    for i = 1, #self.parents do --overriding parenr configs with own settings
        self.finalConfig = self:mergeConfigs(self.finalConfig, self.parents[i])
    end
end

---Output the
---@return OptionsCollection #Final output once all potential parent configs have been loaded and merged
function ConfigDefinition:outputFinalized()
    return self:mergeConfigs(self.finalConfig, rv.defaultConfig, true)
end

return ConfigDefinition