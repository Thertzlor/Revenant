local rv = ... ---@type Revenant
local type, super = type, rv.importer:classImport("MacroDefinition")
---@class _MouseMoveOptions:MacroOptions
---@field screen integer #the number of the screen to move to. Main screen by default.
---@field relative boolean #If true the mouse moves relative to its current position
---@field velocity number #speed of the mouse movements in pixels per second
---@field play string "hold"|"normal"|"toggle" #`hold` only moves while the key is held, `toggle` cancels the movement on the second click
---@field duration integer #the total duration of the mouse movement
--[[=============================================================]] --
---@class __MouseMoveShorthands
---@field s integer #Shorthand for "screen"
---@field d integer #Shorthand for "duration"
---@field r boolean #Shorthand for "relative"
---@field v number #Shorthand for "velocity"
---@field p string #Shorthand for "play"
--[[=============================================================]] --
---Assign a macro to move your mouse across the screen, instantly, or continuously.
---@alias AssignMouseMove MacroInitDefinition<"mouseposition","p",_MouseMoveOptions|__MouseMoveShorthands,(string|integer)[]>
--[[=============================================================]] --
---A macro to move your mouse across the screen, instantly, or continuously.
---@class MouseMoveMacro:MacroDefinition
---@field options _MouseMoveOptions
---@field command (string|integer)[]
local MouseMoveMacro = super:new()
MouseMoveMacro.type = "mouseposition"
MouseMoveMacro.lintProperties = { ---@type OptionsLintPreset
   screen = {type = "number"},
   relative = {type = "boolean"},
   duration = {type = "number"},
   velocity = {type = "number"},
   play = {type = "string"}
}

MouseMoveMacro.shorthands = {s = "screen", d = "duration", v = "velocity", r = "relative", p = "play"}

MouseMoveMacro.lintCommand = {type = {"string", "number"}}

MouseMoveMacro.singleTrigger = true

---@async
function MouseMoveMacro:parseInstructions()
   local dur = self.options.duration
   self.options.screen = (rv.profile.config.restrictToMainScreen and rv.mouseMonitorUtils.mainScreen) or self.options.screen or rv.mouseMonitorUtils.mainScreen
   self.command[2] = self.command[2] or 0
   if type(self.command[1]) ~= "number" or type(self.command[2]) ~= "number" then self.command[1], self.command[2] = rv.mouseMonitorUtils.screens[self.options.screen]:convertToPixel(self.command[1], self.command[2], self.options.relative) end -- conversion to normalized Logitech coordinates.
   self.continuous = dur and dur ~= 0
   self:finishInit()
end

-- MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@param event Event
---@async
function MouseMoveMacro:execute(event)
   local playMode = self.options.play or "normal"
   local dir = event.direction
   local options = self.options
   local pID = self.pID
   if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") and self.direction ~= "up") or (self.direction == "up" and dir == "down") then return end
   if rv.threading:taskStatus(pID) == 0 then
      rv.mouseMonitorUtils:mouseMoveWrapper(self.command, options, dir, pID) -- the actual movement takes place here.
   elseif (dir == "up" and options.play == "hold") or (dir == "down" and options.play == "toggle") then
      rv.threading:taskAbort(pID) -- cancelling the movement macro, if it's already running.
   end
end

---@param depth? integer
function MouseMoveMacro:export(depth) return self:indent(depth) .. self.titleExport .. (self.options.relative and "Shift mouse by " or "Move mouse to [") .. self.rawCommand[1] .. (self.rawCommand[2] and ("," .. self.rawCommand[2] .. "]") or "]") end

return MouseMoveMacro
