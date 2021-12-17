local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local type = type

---@class MouseMoveOptions:MacroOptions
---@field screen number
---@field relative boolean
---@field velocity number
---@field play string
---@field duration number
--=============================================================
---@class MouseMoveMacro:MacroDefinition
---@field options MouseMoveOptions
---@field command (string|number)[]
local MouseMoveMacro = MacroDefinition:new()
MouseMoveMacro.singleTrigger = true


MouseMoveMacro.lintProperties = {
    screen = { type = "number" },
    relative = { type = "boolean" },
    duration = { type = "number" },
    velocity = { type = "number" },
    play = { type = "string" }
}

MouseMoveMacro.shortHands = {
    s = "screen",
    d = "curation",
    v = "velocity",
    r = "relative",
    p = "play"
}

function MouseMoveMacro:parseInstructions()
    self.options.screen = (tl.profile.config.restrictToMainScreen and tl.mouseMonitorUtils.mainScreen) or self.options.screen or tl.mouseMonitorUtils.mainScreen
    self.command[2] = self.command[2] or 0
    if type(self.command[1]) ~= "number" or type(self.command[2]) ~= "number" then
        self.command[1], self.command[2] = tl.mouseMonitorUtils.screens[self.options.screen]:convertToPixel(self.command[1], self.command[2], self.options.relative)
    end
    self:finishInit()
end

--MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@param event Event
function MouseMoveMacro:execute(event)
    local playMode = self.options.play or "normal"
    local dir = event.direction
    local options = self.options ---@type MouseMoveOptions
    local pID = self.pID
    if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down")
    and self.direction ~= "up") or (self.direction == "up" and dir == "down") then return end
    if tl.coroutines.taskList[pID] == nil then
        tl.mouseMonitorUtils:mouseMoveWrapper(self.command, options, dir, pID)
    elseif (dir == "up" and options.play == "hold") or (dir == "down" and options.play == "toggle") then tl.coroutines:taskAbort(pID) end
end

return MouseMoveMacro