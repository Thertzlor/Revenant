local rv = ...---@type MainLibObject
local next, type, concat, error, gsub, pairs = next, type, table.concat, error, string.gsub, pairs

local ConfigDefinition = rv.baseClass:new()---@class ConfigDefinition:BaseClass

local function _extractOptions(key, a, b)
    local propA = a[key]
    local propB = b[key]
    a[key] = nil
    b[key] = nil
    return propA, propB
end

---@param a OptionsCollection
---@param b OptionsCollection
function ConfigDefinition:mergeConfigs(a, b)
    --TODO actual in-depth merge
    local replace = a.handleOptionConflicts == "replaceDuplicates"
    rv:put(replace, ' hork')
    local accumulator = a.accumulateDefinitions
    local merged = {}
    if accumulator and #accumulator ~= 0 then
        for i = 1, #accumulator do local prop = accumulator[i]
            if prop == "MonitorConfigs" then
                local monA, monB = _extractOptions("resolutions", a, b)
                if monA and monB then
                    if not (rv.tbl:isSingleTypeTable(monA, "table") and rv.tbl:isSingleTypeTable(monA[1], "table")) then monA = { monA } end
                    if not (rv.tbl:isSingleTypeTable(monB, "table") and rv.tbl:isSingleTypeTable(monB[1], "table")) then monB = { monB } end
                    merged.resolutions = rv.tbl:intersectSimple(monA, monB)
                else merged.resolutions = monA or monB end
            elseif prop == "ModeNames" then

            elseif prop == "keyNames" then
                local namA, namB = _extractOptions("rename", a, b)
                if namA and namB then
                    for k, v in pairs(namA) do local alt = namB[k]
                        if alt then
                            if type(v) == "string" then v = { v } end
                            if type(alt) == "string" then alt = { alt } end
                            for m = 1, #alt do
                                if not rv.tbl:find(v, alt[m]) then v[#v + 1] = alt[m] end
                            end
                            if #v ~= 1 then namA[k] = v end
                        end
                    end
                    merged.rename = rv.tbl:intersectSimple(namA, namB, false)
                else merged.rename = namA or namB end
            end
        end
    end
    local argMerge = rv.tbl:intersectSimple(a, b, replace)
    return rv.tbl:intersectSimple(argMerge, merged)
end

---@param profile ProfileDefinition
function ConfigDefinition:constructor(baseData, stack, profile)
    self.stack = stack or {}
    self.base = baseData
    self.tempConfigs = { rv.defaultConfig }---@private
    self.finalConfig = {}
    local function singleImport(base)
        if type(base) == "table" then
            self.tempConfigs[#self.tempConfigs + 1] = base
            return
        end
        local stack = self.stack
        for i = 1, #stack do
            if stack[i] == base then
                stack[#stack + 1] = base
                error("Circular dependency while loading configuration files: " .. concat(stack, '->'))
            end
        end
        self.stack[#self.stack + 1] = base
        local tempImport = base and rv:import(base, function() end) ---@type OptionsCollection
        if tempImport then
            local basePath = gsub(base, "[^\\/]+$", "")
            rv:put("importing " .. base)
            local parent = tempImport.externalConfigs
            if parent then
                local subDef = ConfigDefinition:new(basePath .. parent, stack, profile):output()
                if subDef then tempImport = self:mergeConfigs(tempImport, subDef) end
            end
            self.tempConfigs[#self.tempConfigs + 1] = tempImport
        end
    end

    self:multiArg(singleImport, self.base)
    for i = 1, #self.tempConfigs do local temp = self.tempConfigs[i] self.finalConfig = self:mergeConfigs(self.finalConfig, temp) end
end

function ConfigDefinition:output()
    if next(self.finalConfig) then return self.finalConfig end
    return false
end

return ConfigDefinition