local tl = ...---@type MainLibObject
local pairs, rep, concat = pairs, string.rep, table.concat

local GroupMacro = tl:classImport('MacroDefinition'):new()---@class GroupMacro:MacroDefinition

function GroupMacro:parseInstructions()
    self.titleExport = "{"
    self.endExport = "}"
    local processed = 0
    ---@param class MacroDefinition
    local function subFetch(class)
        local classID = class:awaitOwnId()
        if classID then self.subMacros[#self.subMacros + 1] = classID end
        processed = processed + 1
        if processed == #self.command then if self:checkNecessity() then self.pID = self:genId() end self:finishInit() end
    end
    for i = 1, #self.command do local entry = self.command[i]
        local macroClass = self.profile:getMacroClass(entry)
        if macroClass then
            ---@type MacroDefinition|GroupMacro
            local subClass = macroClass:new(entry, self.profile, self.options, self.overrides, self.stack, self.sourceDevice)
            self:async(subFetch, subClass)
        end
    end
end

---@private
function GroupMacro:checkNecessity()
    if #self.subMacros > 1 then return true
    elseif #self.subMacros == 0 then return false end
    local entry = self.subMacros[1]
    if self.name and self.profile.macroIndex[entry].name then return self.name ~= entry.name end
    tl:put('group not neccesary')
    return false
end

---@param event Event
function GroupMacro:run(event) if not self.disabled then self:execute(event) end end

---@param event Event
function GroupMacro:execute(event)
    local entries = self.subMacros
    for i = 1, #entries do local entry = entries[i] self.profile.macroIndex[entry]:run(event) end
end

return GroupMacro