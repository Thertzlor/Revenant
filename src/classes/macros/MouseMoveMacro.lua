local rv = ...---@type Revenant
local type, rep = type, string.rep
---@class _MouseMoveOptions:MacroOptions
---@field screen number
---@field relative boolean
---@field velocity number
---@field play string
---@field duration number
--=============================================================
---@class __MouseMoveShorthands
---@field s number Shorthand for "screen"
---@field d number Shorthand for "duration"
---@field r boolean Shorthand for "relative"
---@field v number Shorthand for "velocity"
---@field p string Shorthand for "play"
--=============================================================
---@alias MouseMoveDefinition _MouseMoveOptions | MacroInitDefinition | __MouseMoveShorthands
--=============================================================
---@class MouseMoveMacro:MacroDefinition
---@field options _MouseMoveOptions
---@field command table<number,string|number>
local MouseMoveMacro = rv:classImport('MacroDefinition'):new()

MouseMoveMacro.lintProperties = {
    screen = { type = "number" },
    relative = { type = "boolean" },
    duration = { type = "number" },
    velocity = { type = "number" },
    play = { type = "string" }
}

MouseMoveMacro.shortHands = {
    s = "screen",
    d = "duration",
    v = "velocity",
    r = "relative",
    p = "play"
}

MouseMoveMacro.lintCommand = { type = { "string", "number" } }

MouseMoveMacro.singleTrigger = true

function MouseMoveMacro:parseInstructions()
    local dur = self.options.duration
    self.options.screen = (rv.profile.config.restrictToMainScreen and rv.mouseMonitorUtils.mainScreen) or self.options.screen or rv.mouseMonitorUtils.mainScreen
    self.command[2] = self.command[2] or 0
    if type(self.command[1]) ~= "number" or type(self.command[2]) ~= "number" then
        self.command[1], self.command[2] = rv.mouseMonitorUtils.screens[self.options.screen]:convertToPixel(self.command[1], self.command[2], self.options.relative)
    end
    self.continuous = dur and dur ~= 0
    self:finishInit()
end

--MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@param event Event
function MouseMoveMacro:execute(event)
    local playMode = self.options.play or "normal"
    local dir = event.direction
    local options = self.options ---@type _MouseMoveOptions
    local pID = self.pID
    if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down")
    and self.direction ~= "up") or (self.direction == "up" and dir == "down") then return end
    if rv.threading:taskStatus(pID) == 0 then rv.mouseMonitorUtils:mouseMoveWrapper(self.command, options, dir, pID)
    elseif (dir == "up" and options.play == "hold") or (dir == "down" and options.play == "toggle") then rv.threading:taskAbort(pID) end
end

---@param depth number
function MouseMoveMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (self.options.relative and 'Shift mouse by ' or 'Move mouse to [') .. self.rawCommand[1] .. (self.rawCommand[2] and (',' .. self.rawCommand[2] .. ']') or ']')
end

return MouseMoveMacro