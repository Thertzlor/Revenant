local rv = ...---@type Revenant
local type, rep, concat = type, string.rep, table.concat
--=============================================================
---@class _BaseControlOptions:MacroOptions
---@field targetGroup string The type of macro to control
---@field lcd number|boolean
--=============================================================
---@alias ControlDefinition _BaseControlOptions|MacroInitDefinition
--=============================================================
---@class BaseControlMacro:MacroDefinition
---@field controlTargets string[]
---@field command string[]|string
---@field options _BaseControlOptions
---@field controlArguments '"resume"'|'"cancel"'|'"toggle"'|'"pause"'
local BaseControlMacro = rv:classImport('MacroDefinition'):new()
BaseControlMacro.lintProperties = { lcd = { type = { "number", "boolean" } }, targetGroup = { type = "string" } }
BaseControlMacro.singleTrigger = true

---@protected
function BaseControlMacro:parseInstructions()
    local subList = self.command[1]
    if self.options.lcd == nil then self.options.lcd = true end
    self.controlTargets = {}
    local extender = { p = "pause", c = "cancel", r = "resume", t = "toggle" }
    self.controlArguments = extender[self.command[2]] or self.command[2]
    local cycleTarget = self.type == "cyclecontrol"
    self.targetGroup = (cycleTarget and "cycle") or (self.type == "macrocontrol" and self.options.targetGroup or "__continuous") or "__continuous"
    self.targetFunction = "control"
    if self.type == "cyclecontrol" then
        local arg = self.controlArguments
        local argType = type(arg)
        assert(argType == "number" or (argType == "table" and (not arg[1] or type(arg[1] == "number")) and (not arg[2] or type(arg[2] == "number"))),
        "A Cycle control needs to be either a number or a table containing two numbers.")
    end
    if subList == "all" or subList == "" or not subList then return self:finishInit() end
    local cmd = (type(subList) ~= "table" and { subList }) or subList
    local function setSub(name)
        local foundId = self:awaitId(name, true)
        if foundId then
            local conMac = rv.profile.macroIndex[foundId]
            if cycleTarget then
                if not conMac.type == "cycle" then error("The macro '" .. name .. "' is not a cycle macro") end
                if self.options.lcd then
                    local controlText = ''
                    if type(arg) ~= "table" then arg = { arg } end
                    if arg[1] then controlText = arg[1] == 0 and "Cycling to next mode" or "Setting mode to " .. arg[1] end
                    if arg[2] then controlText = controlText .. (controlText == '' and 'S' or ' and s') .. 'etting the number of complete cycles to ' .. arg[2] end
                    conMac:parseControls(controlText, self.pID)
                end
            else
                if not conMac.continuous then error("The macro '" .. name .. "' is not continuos") end
                if self.options.lcd then conMac:parseControls() end
            end
            self.controlTargets[#self.controlTargets + 1] = foundId
        end
    end
    for i = 1, #cmd do self:async(setSub, cmd[i]) end
    self:finishInit()
end

function BaseControlMacro:execute()
    if #self.controlTargets ~= 0 then
        for i = 1, #self.controlTargets do
            local target = rv.profile.macroIndex[self.controlTargets[i]] ---@type SequenceMacro|CycleMacro
            if target then target:control(self.controlArguments, self.options.lcd, self.msgDuration) end
        end
    else
        local allMacs = rv.profile:macrosByType(self.targetGroup)
        for i = 1, #allMacs do
            local target = rv.profile.macroIndex[allMacs[i]]
            if target then target[self.targetFunction](target, self.controlArguments, self.options.lcd, self.msgDuration) end
        end
    end
end

---@param depth number
function BaseControlMacro:export(depth)
    local cmd = self.command[1]
    if type(cmd) ~= "table" then cmd = { cmd } end
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (self.controlArguments) .. (#self.controlTargets == 0 and ' all ' or ' ') .. self.targetGroup .. 's' .. (#self.controlTargets == 0 and '.' or ': ' .. concat(cmd, ', '))
end

return BaseControlMacro