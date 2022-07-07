local rv = ... ---@type Revenant
local rep, concat = string.rep, table.concat
---@class GroupMacro:MacroDefinition
local GroupMacro = rv:classImport('MacroDefinition'):new()
GroupMacro.lintProperties = { __all = true }
function GroupMacro:parseInstructions()
    local processed = 0
    ---@param class MacroDefinition
    local function subFetch(class)
        local classID = class:awaitOwnId()
        if classID then self.subMacros[#self.subMacros + 1] = classID end
        processed = processed + 1
        if processed == #self.command then if self:checkNecessity() then self.pID = self:genId() end self:finishInit() end
    end

    for i = 1, #self.command do local entry = self.command[i]
        local macroClass = rv.tbl:getMacroClass(entry)
        if macroClass then
            local subClass = macroClass:new(entry, self.options, self.stack, self.sourceDevice)
            self:async(subFetch, subClass)
        end
    end
end

---@param depth? integer
function GroupMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    local subTable = {}
    for i = 1, #self.subMacros do subTable[#subTable + 1] = rv.profile.macroIndex[self.subMacros[i]]:export(depth + 1) end
    local content = #subTable == 0 and false or "\n" .. concat(subTable, ",\n")
    return indent .. self.titleExport .. ' {' .. (content or "") .. "\n" .. indent .. "}"
end

---@private
function GroupMacro:checkNecessity()
    if #self.subMacros > 1 then return true
    elseif #self.subMacros == 0 then return false end
    local entry = rv.profile.macroIndex[self.subMacros[1]]
    if self.name and entry.name then return self.name ~= entry.name end
    return false
end

---@param event Event
function GroupMacro:run(event)
    if self.disabled then return end
    if rv.scriptStates.docMode and self.manualDocumentation then return rv.lcd:displayOnLCD(self.pID, 1) end
    local linked = event.linked
    event.linked = nil
    self:execute(event)
    self:blockNext(event, linked)
end

---@param event Event
function GroupMacro:runFree(event) self:run(event) end

---@param event Event
function GroupMacro:execute(event)
    local entries = self.subMacros
    for i = 1, #entries do
        if self.blocked then break end
        local entry = entries[i]
        rv.profile.macroIndex[entry]:run(event)
    end
    self.blocked = false
end

return GroupMacro
