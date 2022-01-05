local rv = ...---@type Revenant
local rawset, type, setmetatable, pairs, next, insert, loadfile, xpcall, sub, concat, gsub, sort, error = rawset, type, setmetatable, pairs, next, table.insert, loadfile, xpcall, string.sub, table.concat, string.gsub, table.sort, error
local ConfigDefinition = rv:classImport("ConfigDefinition") ---@type ConfigDefinition
--=============================================================
---@alias MacroTable table<string,GenericMacro>
---@alias MacroArray table<number,GenericMacro>
---@alias Assignment GenericMacro|MacroArray|MacroTable
--=============================================================
---@class MacroAssignment
---@field key table<string,Assignment>
---@field documentation table<string,string>
---@field config OptionsCollection
---@field exit Assignment
---@field library table<string,Assignment>
---@field scopeDefaults Assignment
---@field scopeOverride Assignment
---@field start Assignment
--=============================================================
---@class GlobalState 
---@field maxMode number
---@field sKey boolean
---@field maxKeys number
---@field singleDevice string
--=============================================================
---@class MacroQueue
---@field waiting string[]
---@field queue any
--=============================================================
---@class ProfileDefinition:BaseClass
---@field deviceState table<string,HardwareDefinition>
---@field config OptionsCollection
---@field globalState GlobalState
---@field nameMap table<string,string>
---@field macroIndex table<string,MacroDefinition>
---@field typedIndex table<string,string[]>
---@field awaiting table<string,MacroQueue>
---@field assign MacroAssignment
---@field assignFlattened table<string,Assignment>
local ProfileDefinition = rv.baseClass:new()

---Yaes
---@param path string
---@param init boolean
---@param stack string[]
function ProfileDefinition:constructor(path, name, stack, init)
    self.stack = stack or {}---@private
    for i = 1, #self.stack do if self.stack[i] == path then error("Circular inheritance detected: " .. concat(stack, '->') .. '->' .. path) end end
    self.path = path or "origin"
    self.subPath = rv.helperUtils.parentPath(self.path)
    self.init = false
    self.first = init
    self.libMacros = {}
    self.raw = {}
    self.libInit = false
    self.autoKeys = true---@private
    self.awaiting = {}
    self.nameMap = {}
    self.macroIndex = self:indexTable()
    self.config = {}
    self.documentation = {}
    self.toggledKeys = {}---@private
    self.deviceState = {}
    self.globalState = {}
    self.unRename = {}---@private
    self.typedIndex = {}
    local baseTable = { library = {} }
    self.logiSet = rv.paths.profile---@private
    self.assign = self:autoTable(baseTable)
    if path then self:profileImport() end
    if init then self.logiSet(self.assign) end
    self.autoKeys = false
    self.name = (init and rv.paths.profileName) or name
    self:fetchConfigs()
    self:fetchDocs()
    if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
    self.stack[#self.stack + 1] = self.path
    rv.hardware:defineDevices(self)
    self:compileAssignments()
    local ext = self.config.extends
    if ext and ext ~= '' then
        if type(ext) ~= "table" then ext = { ext } end
        for i = 1, #ext do local x = ext[i]
            if x ~= '' then
                local extPath = (rv.paths.absoluteParentPaths and '' or self.subPath) .. x
                local parent = ProfileDefinition:new(extPath, x, self.stack, false)
                self:extendParent(parent)
            end
        end
    end
    if self.first and self.config.defaultKeys then for k, v in pairs(self.config.defaultKeys) do self.assignFlattened[k] = self.assignFlattened[k] or v end end
end

---Generic import function for config and documentatation files
---@param importType "'doc'"|"'config'"
---@return string[] path to the external file for documentation or configuration
function ProfileDefinition:getDefaultPath(importType)
    if rv.paths.fileLocation == 0 then return false end
    local term = ({ doc = "defaultDocPath", config = "defaultConfigPath" })[importType] ---@type string
    local def = rv.paths[term]
    local path = ''
    if def then
        path = gsub(((rv.paths.absoluteProfilePaths and "") or self.subPath) .. (def.prefix or "") .. (self.name or "") .. (def.suffix or ""), "//", "/")
    end
    return path
end

---@protected
---@param msg any
function ProfileDefinition:errorHandler(msg) rv.scriptStates.errors[#rv.scriptStates.errors + 1] = "profile " .. self.name .. " failed to initialize:\n  " .. msg end

function ProfileDefinition:libNamed(tab, short)
    if type(tab) ~= "table" then return end
    local lib = self.assign.library
    local t1 = (short and "n") or "name"
    local t2 = (short and "name") or "n"
    local nameIndex = {}
    local currentName = tab[t1] or tab[t2]
    if currentName then
        if (not tab.__autoName) and not lib[currentName] then lib[currentName] = tab end
        nameIndex[#nameIndex + 1] = currentName
    else
        for k, v in pairs(tab) do if type(v) == "table" then self:libNamed(v, short) end end
        for i = 1, #tab do local v = tab[i] if type(v) == "table" then self:libNamed(v, short) end end
    end
    tab.__autoName = nil
end

function ProfileDefinition:indexTable()
    return setmetatable({}, {
        __index = function(_, key)
            if not self.init then return nil end
            return { run = function() rv:put("macro " .. key .. " does not exist.") end } end
    })
end

function ProfileDefinition:findMacros(group, id)
    if id then
        if type(id) ~= "table" then
            local mac = self.macroIndex[id]
            return mac and { mac } or {}
        end
        local res = {}
        for i = 1, #id do local mac = self.macroIndex[id[i]] if mac then res[#res + 1] = mac end end
        return res
    end
    return self.typedIndex[group] or {}
end
---Fetches one or more external config files for the current profile
function ProfileDefinition:fetchConfigs()
    local extConfig = self:getDefaultPath('config')
    local cfg = self.assign.config.externalConfigs
    if extConfig ~= '' then
        local defConf = rv:import(extConfig, function() end)
        if defConf then
            if cfg then
                if type(cfg) ~= "table" then self.assign.config.externalConfigs = { cfg } end
                insert(self.assign.config.externalConfigs, 1, defConf)
            else self.assign.config.externalConfigs = { defConf } end
        end
    end
    self.config = ConfigDefinition:new(self.assign.config, nil, rv.helperUtils.parentPath(self.path), true):output()
end

---Fetches one or more external documentation file for the current profile
function ProfileDefinition:fetchDocs()
    local doc = self.assign.documentation or {}
    local exConf = self.config.externalDocs
    local defPath = self:getDefaultPath("doc")
    local defDoc = defPath and rv:import(defPath, function() end)
    local docTable = defDoc and { defDoc } or {}
    if exConf then
        if type(exConf) == "string" then exConf = { exConf } end
        for i = 1, #exConf do docTable[#docTable + 1] = exConf[i] end
    end
    for i = 1, #docTable do local path = docTable[i]
        local imported = (type(path) == "table" and path) or rv:import(((rv.paths.absoluteDocPaths and '') or self.subPath) .. path, function() rv:put("could not load " .. path) end)
        if imported then doc = rv.tbl:intersectSimple(doc, imported, self.config.handleDocumentationConflicts == "replaceExisting") end
    end
    self.documentation = doc
end

---@param parent ProfileDefinition
function ProfileDefinition:extendParent(parent)
    local selfResolve = rv.tbl:optionResolver(self)
    local parentResolve = rv.tbl:optionResolver(parent)
    local determinants = rv.stringPresets.determinants
    local function sameTrigger(m1, m2)
        local same = true
        for i = 1, #determinants do local d = determinants[i]
            if same and selfResolve(m1, d) ~= parentResolve(m2, d) then same = false end
        end
        return same
    end
    for key, bindings in pairs(parent.assignFlattened) do
        local currentButton = self.assignFlattened[key]
        local parentGroup = rv.tbl:isActualGroup(bindings)
        local shorty = self.config.preferShorthand
        if currentButton then
            local buttonAdded = false
            local currentGroup = rv.tbl:isActualGroup(currentButton)
            if not parentGroup then
                for i = 1, #bindings do local parentBinding = bindings[i]
                    if currentGroup then
                        if sameTrigger(parentBinding, currentButton) then self:libNamed(parentBinding, shorty)
                        else
                            if not buttonAdded then
                                self.assignFlattened[key] = { currentButton }
                                if currentButton.__autoName then
                                    currentButton.__autoName = nil
                                    self.assignFlattened[key].name = currentButton.name
                                    currentButton.name = nil
                                end
                                buttonAdded = true
                            end
                            self.assignFlattened[key][#self.assignFlattened[key] + 1] = parentBinding
                        end
                    else
                        for i = 1, #currentButton do local currentBinding = currentButton[i]
                            if sameTrigger(parentBinding, currentBinding) then self:libNamed(parentBinding, shorty)
                            else currentButton[#currentButton + 1] = parentBinding end
                        end
                    end
                end
            else
                if currentGroup then
                    if sameTrigger(currentButton, bindings) then self:libNamed(bindings, shorty)
                    else
                        self.assignFlattened[key] = { currentButton, bindings }
                        if currentButton.__autoName then
                            currentButton.__autoName = nil
                            self.assignFlattened[key] = { currentButton, bindings, name = currentButton.name }
                            currentButton.name = nil
                        end
                    end
                else
                    for i = 1, #currentButton do local currentBinding = currentButton[i]
                        if sameTrigger(bindings, currentBinding) then self:libNamed(bindings, shorty)
                        else currentButton[#currentButton + 1] = bindings end
                    end
                end
            end
        else self.assignFlattened[key] = bindings end
    end
    for k, v in pairs(parent.assign.library) do if not self.assign.library[k] then self.assign.library[k] = v end end
end

function ProfileDefinition:profileImport()
    local p = self.path:gsub("%.lua$", ""):gsub("$", ".lua")
    rv:put('importing ' .. p)
    xpcall(function() return (loadfile(p) or error("File not found/syntax error"))(self.assign, rv) end, function(err) self:errorHandler(err) end)
end

---@private
function ProfileDefinition:compileAssignments()
    local collector = self.assign.key or {}

    local function extractFromTable(currentTable, presets, subType) --Extract button functionality and put it into the main table
        local stackM = self.config[subType .. "Stack"]
        local mergedResult = {}
        local tablePresets = rv.tbl:intersect({}, presets or {})
        for key, value in pairs(currentTable) do
            if type(key) == "string" and self.unRename[key] ~= nil then
                if type(value) ~= "table" then value = { value } end
                local identValue = rv.tbl:identifyTableType(value, self)
                if collector[key] == nil then
                    if identValue == "macro" then value._inherit = tablePresets
                    else value = rv.tbl:intersectSimple(value, tablePresets) end
                    collector[key] = value
                else
                    if type(collector[key]) ~= "table" then collector[key] = { collector[key] } end
                    if rv.tbl:hasProperties(collector[key]) then collector[key] = { collector[key] } end
                    if identValue == "macro" or (identValue == "group" and rv.tbl:hasProperties(value)) then
                        if identValue == "macro" then value._inherit = tablePresets
                        else value = rv.tbl:intersectSimple(value, tablePresets) end
                        if stackM == "prepend" then insert(collector[key], 1, value)
                        else collector[key][#collector[key] + 1] = value end
                    elseif identValue ~= "empty" then -- Here we handle groups without properties
                        for w = 1, #value do
                            if type(value[w]) ~= "table" then value[w] = { value[w] } end
                            value[w] = rv.tbl:intersectSimple(value[w], tablePresets) end
                        for u = 1, #value do local h = u
                            if stackM == "prepend" then
                                if self.config.stackAutoReverse then h = #value - u + 1 end
                                insert(collector[key], 1, value[h])
                            else collector[key][#collector[key] + 1] = value[h] end
                        end
                    end
                end
                currentTable[key] = nil
            elseif type(currentTable[key]) == "table" and key ~= "key" then
                mergedResult[key] = value
                currentTable[key] = nil
            end
        end
        return { mergedResult, tablePresets }
    end

    local function resolveHierachy(currentTable, previousTableState) --recursively retrieve key definitions from array
        local nextWave = {}
        previousTableState = previousTableState or {}
        local newTableState = rv.tbl:intersect({}, previousTableState)

        local function setMode()
            local returnValue = {}
            for k = 0, self.globalState.maxMode do local j = k
                if self.config.modeSort == "reverse" then j = self.globalState.maxMode - k
                elseif type(self.config.modeSort) == "table" and #self.config.modeSort == self.globalState.maxMode + 1 then
                    j = self.config.modeSort[k + 1]
                end
                if currentTable["mode" .. j] ~= nil then
                    local modeTable = currentTable["mode" .. j]
                    newTableState.mode = j
                    returnValue[#returnValue + 1] = extractFromTable(modeTable, newTableState, "mode")
                    currentTable["mode" .. j] = nil
                end
                newTableState.mode = previousTableState.mode
            end
            return returnValue
        end

        local function setShift()
            local returnValue = {}
            if self.globalState.sKey then
                for h = 0, 2 do local j = h
                    if self.config.shiftSort == "reverse" then j = self.globalState.maxMode - h
                    elseif type(self.config.shiftSort) == "table" and #self.config.shiftSort == 3 then
                        j = self.config.shiftSort[h + 1]
                    end
                    if currentTable["s" .. j] ~= nil then
                        local shiftTable = currentTable["s" .. j]
                        newTableState.gshift = j
                        returnValue[#returnValue + 1] = extractFromTable(shiftTable, newTableState, "shift")
                        currentTable["s" .. j] = nil
                    end
                    newTableState.gshift = previousTableState.gshift
                end
            end
            return returnValue
        end

        local function setCustom()
            local returnValue = {}
            for r = 1, #self.config.customSort do
                local customGroupName = self.config.customSort[r]
                local customGroupTableState = {}
                if currentTable[customGroupName] and currentTable[customGroupName] == "table" then
                    for d, m in pairs(currentTable[customGroupName]) do
                        if type(d) == "string" and not self.unRename[d] then customGroupTableState[d] = m end
                    end
                    returnValue[#returnValue + 1] = extractFromTable(currentTable[customGroupName], rv.tbl:intersect(previousTableState, customGroupTableState, 1), "custom")
                    currentTable[customGroupName] = nil
                end
            end
            for h, p in pairs(currentTable) do
                local privs = {}
                if sub(h, 1, 2) == "_c" and type(p) == "table" then
                    for d, m in pairs(p) do if type(d) == "string" and self.unRename[d] == nil then privs[d] = m end end
                    returnValue[#returnValue + 1] = extractFromTable(p, rv.tbl:intersect(previousTableState, privs, 1), "custom")
                    currentTable[h] = nil
                end
            end
            return returnValue
        end

        local orderTable = { custom = setCustom, mode = setMode, shift = setShift }
        for g = 1, #self.config.stackOrder do local l = g
            if self.config.stackAutoReverse and self.config.modeStack == "prepend" and self.config.shiftStack == "prepend"
            and self.config.customStack == "prepend" then l = #self.config.stackOrder - g + 1 end
            nextWave[#nextWave + 1] = orderTable[self.config.stackOrder[l]]()
        end

        if rv.tbl:hasContent(nextWave) then
            for u = 1, #nextWave do local wave = nextWave[u]
                for o = 1, #wave do local x = wave[o]
                    resolveHierachy(x[1], x[2])
                end
            end
        end
    end
    resolveHierachy(self.assign.key)
    for k, v in pairs(collector) do
        if type(v) ~= "table" then v = { v } end
        v.name = v.name or v.n
        if not v.name and k then
            v.__autoName = true
            v.name = k
        end
        collector[k] = v
    end
    for k, v in pairs(self.unRename) do
        if k ~= v then
            local valV, valK = collector[v], collector[k]
            collector[v] = valK
            collector[k] = valV
        end
    end
    self.assignFlattened = collector
end

function ProfileDefinition:buildTree()
    local extable = {}
    for _, v in pairs(self.bindings) do extable[#extable + 1] = self.macroIndex[v]:export() end
    return concat(rv.helperUtils.simpleSort(extable), "\n\n")
end

function ProfileDefinition:parseBindings()
    self.bindings = {}
    local processed = (0 + ((self.assign.exit and 1) or 0) + ((self.assign.start and 1) or 0))
    local total = 0
    for _ in pairs(self.assignFlattened) do total = total + 1 end
    for _ in pairs(self.assign.library) do total = total + 1 end
    ---@param class MacroDefinition
    local function getBinding(class, key)
        local classID = class:awaitOwnId()
        if classID and key then self.bindings[key] = classID end
        processed = processed + 1
        if processed == total then
            for k, v in pairs(self.macroIndex) do
                if v.type then local typeIndex = self.typedIndex[v.type]
                    if typeIndex then typeIndex[#typeIndex + 1] = k
                    else self.typedIndex[v.type] = { k } end
                end
            end
            self.init = true
        end
    end

    for key, bindingTable in pairs(self.assignFlattened) do
        local bindingClass = rv.tbl:getMacroClass(bindingTable, self)---@type MacroDefinition
        if bindingClass then
            local fam
            if self.deviceState[rv.str:token(key) or "null"] then fam = rv.str:token(key) end
            local bindingInstance = bindingClass:new(bindingTable, self, self.assign.scopeDefaults, self.assign.scopeOverride, nil, fam)
            self:async(getBinding, bindingInstance, key)
        end
    end

    for name, libraryBinding in pairs(self.assign.library) do
        local bindingClass = rv.tbl:getMacroClass(libraryBinding, self)---@type MacroDefinition
        if bindingClass then
            if type(bindingClass) ~= "table" then bindingClass = { bindingClass } end
            bindingClass.n = nil
            bindingClass.name = name
            local bindingInstance = bindingClass:new(libraryBinding, self, self.assign.scopeDefaults, self.assign.scopeOverride)
            self:async(getBinding, bindingInstance)
        end
    end

    if self.assign.exit then
        local exitClass = rv.tbl:getMacroClass(self.assign.exit, self)
        if exitClass then self:async(getBinding, exitClass:new(self.assign.exit, self, self.assign.scopeDefaults, self.assign.scopeOverride), "exit") end
    end

    if self.assign.start then
        local startClass = rv.tbl:getMacroClass(self.assign.start, self)
        if startClass then self:async(getBinding, startClass:new(self.assign.exit, self, self.assign.scopeDefaults, self.assign.scopeOverride), "start") end
    end
end

return ProfileDefinition