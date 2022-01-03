local rv = ...---@type MainLibObject
local type, rep, concat = type, string.rep, table.concat
--=============================================================
---@class BaseControlMacro:MacroDefinition
---@field controlTargets string[]
---@field command string[]|string
local BaseControlMacro = rv:classImport('MacroDefinition'):new()
BaseControlMacro.lintProperties = { __none = {} }
BaseControlMacro.singleTrigger = true

---@protected
function BaseControlMacro:parseInstructions()
    local subList = self.command[1]
    self.controlTargets = {}
    local extender = { p = "pause", c = "cancel", r = "resume", t = "toggle" }
    self.controlArguments = extender[self.command[2]] or self.command[2]
    self.targetGroup = (self.type == "cyclecontrol" and "cycle") or (self.type == "sequenceControl" and "sequence")
    self.targetFunction = (self.type == "sequenceResume" and "resume") or "control"
    if subList == "all" or subList == "" then return self:finishInit() end
    local cmd = (type(subList) ~= "table" and { subList }) or subList
    local function setSub(name)
        local foundId = self:awaitId(name, true)
        if foundId then self.controlTargets[#self.controlTargets + 1] = foundId end
    end
    for i = 1, #cmd do self:async(setSub, cmd[i]) end
    self:finishInit()
end

---@param event Event
function BaseControlMacro:execute(event)
    if #self.controlTargets ~= 0 then
        for i = 1, #self.controlTargets do
            local target = self.profile.macroIndex[self.controlTargets[i]] ---@type SequenceMacro|CycleMacro
            if target then target:control(self.controlArguments) end
        end
    else
        local allMacs = self.profile:findMacros(self.targetGroup)
        for i = 1, #allMacs do
            local target = self.profile.macroIndex[allMacs[i]]
            if target then target[self.targetFunction](target, self.controlArguments, event) end
        end
    end
end

---@param depth number
function BaseControlMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (self.controlArguments) .. (#self.controlTargets == 0 and ' all ' or ' ') .. self.targetGroup .. 's' .. (#self.controlTargets == 0 and '.' or ': ' .. concat(self.controlTargets, ', '))
end

return BaseControlMacro