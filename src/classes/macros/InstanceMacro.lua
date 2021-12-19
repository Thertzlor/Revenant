local tl = ...---@type MainLibObject
local remove, type, insert, next, abs, pairs, error = table.remove, type, table.insert, next, math.abs, pairs, error
local MacroDefinition = tl:classImport('MacroDefinition')

---@class InstanceOptions:MacroOptions
---@field update table<number,any>
---@field newType string
--=============================================================
---@class InstanceMacro:MacroDefinition
---@field options InstanceOptions
local InstanceMacro = MacroDefinition:new()

InstanceMacro.lintProperties = {
    update = { type = "table" },
    newType = { type = "string" },
    __all = true
}

InstanceMacro.lintCommand ={type="string"}

InstanceMacro.shortHands = { u = "update" }

local numericMethods = tl.tbl:propsFrom { "insert", "listinsert", "listreplace" }
local updateTypes = { r = "replace", i = "insert", d = "delete", lr = "listreplace", li = "listinsert" };
for k, v in pairs(updateTypes) do updateTypes[v] = v end

---@param selector table<number,string|number>
---@param target table
---@return table<number,any>,number
local function _walkTable(selector, target)
    local current = target
    local function getIndex(dex) return ((type(dex) ~= "number" or dex > 0) and dex) or #current + dex end
    local key = remove(selector)
    for i = 1, #selector do current = current[getIndex(selector[i])] end
    return current, getIndex(key)
end

---@private
function InstanceMacro:updateMain(update, target)
    local total = #update
    local processed = 0

    ---@param subject table<string,any>
    ---@param selector table<number,string|number>
    ---@param method string
    local function processContent(method, selector, subject)
        if type(selector[#selector]) == "string" then
            if numericMethods[method] then error("update method " .. method .. " can only be applied to numeric keys. Current target is property key " .. selector[#selector])
            elseif method == "delete" and subject then error("positional deletions are only valid for numeric keys.") end
        end
        local table, key = _walkTable(selector, target) ---@type any
        if method == nil or method == "replace" then table[key] = subject
        elseif method == "insert" then insert(table, key, subject)
        elseif method == "listinsert" then for i = 1, #subject do insert(table, key, subject[#subject - i + 1]) end
        elseif method == "listreplace" then remove(table, key) for i = 1, #subject do insert(table, key, subject[#subject - i + 1]) end
        elseif method == "delete" then
            if type(key) == "string" then table[key] = nil
            else
                subject = subject or 0
                remove(table, key)
                for i = 1, abs(subject) do remove(table, (key - ((subject > 0 and 1) or 0))) end
            end
        end
    end

    ---@param updateInput table<number,table<string,any>>|{method:string,selector:table<number, string|number>,s:table<number, string|number>}
    local function advancedUpdate(updateInput)
        local method = updateInput.method
        local rawSelector = updateInput.selector and updateInput.selector or updateInput.s
        local selector = type(rawSelector) == "table" and rawSelector or { rawSelector } ---@type any
        local subject = updateInput[1]
        local source = updateInput.source
        if subject and type(source) == "string" and type(subject) ~= "table" then subject = { subject }
        else source = nil end
        if source then
            local referencedMacro = self.profile.macroIndex[self:awaitId(source)]
            local tab, dex = _walkTable(subject, referencedMacro.raw)
            subject = tab[dex]
        end
        if tl.tbl:isSingleTypeTable(selector, "table") then for i = 1, #selector do processContent(method, selector[i], subject) end
        else processContent(method, selector, subject) end
        processed = processed + 1
        if processed == total then self:finalize(target) end
    end
    self:async(advancedUpdate, update)
end

---@private
function InstanceMacro:finalize(newRaw)
    if self.init then return end
    local subClass = self.profile:getMacroClass(newRaw)---@type MacroDefinition
    local subId = subClass:new(newRaw, self.profile, self.options, self.overrides, self.stack, self.sourceDevice):awaitOwnId()
    self.subMacros[#self.subMacros + 1] = subId
    self.pID = subId;
    self:finishInit(true)
end

---@protected
function InstanceMacro:parseInstructions()
    self.command = self.rawCommand[1]
    self.titleExport = tl.classMap[self.type or "key"][1] .. " (" .. self.command .. ")"
    local target = self.profile.macroIndex[self:awaitId(self.command)]
    if not next(self.options) then self:finalize(tl.helperUtils.deepCopy(tl.tbl:intersect({}, target.raw)))
    else
        local myUpdate = self.options.update
        local newType = self.options.newType
        self.options.newType = nil
        self.options.update = nil
        local newRaw = tl.helperUtils.deepCopy(tl.tbl:intersect({}, target.raw))
        if newType then newRaw.type = newType end
        if myUpdate then
            local updates = myUpdate.selector ~= nil and { myUpdate } or myUpdate
            self:updateMain(updates, newRaw)
        else self:finalize(newRaw) end
    end
end

---@param event Event
function InstanceMacro:execute(event)
    local entries = self.subMacros
    for i = 1, #entries do local entry = entries[i]
 self.profile.macroIndex[entry]:run(event)
    end
end

return InstanceMacro