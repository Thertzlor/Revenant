local rv = ... ---@type Revenant
local type, super = type, rv.importer:classImport("MacroDefinition")
---@class (exact) _MousePositionOptions:ThreadedMacroOptions
---@field screen? integer #the number of the screen to move to. Main screen by default.
---@field relative? boolean #If true the mouse moves relative to its current position
---@field velocity? number #speed of the mouse movements in pixels per second
---@field duration? integer #the total duration of the mouse movement
--[[=============================================================]] --
---@class __MousePositionShorthands
---@field s? integer #Shorthand for "screen"
---@field d? integer #Shorthand for "duration"
---@field r? boolean #Shorthand for "relative"
---@field v? number #Shorthand for "velocity"
---@field p? string #Shorthand for "play"
--[[=============================================================]] --

---Assign a macro to move your mouse across the screen, instantly, or continuously.
---@alias AssignMousePosition MacroInitDefinition<"mouseposition","p",_MousePositionOptions|__MousePositionShorthands,(string|integer|UserCoordinates)[]>
--[[=============================================================]] --
---A macro to move your mouse across the screen, instantly, or continuously.
---@class (exact) MousePositionMacro:MacroDefinition
---@field options _MousePositionOptions
---@field unstable boolean
---@field command l<(string|integer)>[]
local MousePositionMacro = super:new()
MousePositionMacro.type = "mouseposition"
MousePositionMacro.lintProperties = { --
   screen = {type = "number"},
   relative = {type = "boolean"},
   duration = {type = "number"},
   velocity = {type = "number"},
   play = {type = "string", values = {"hold", "toggle", "normal", "phold", "ptoggle"}},
   cancel = {type = "boolean"},
   stack = {type = "number", range = {0, 3}},
   interrupts = {type = {"boolean", "string"}, values = {"exclusive", "exclusivePause"}}
}

MousePositionMacro.shorthands = {s = "screen", d = "duration", v = "velocity", r = "relative", p = "play"}

MousePositionMacro.lintCommand = {type = {"string", "number", "table"}, tableKeys = "number", tableTypes = {"number", "string"}}

---@async
function MousePositionMacro:parseInstructions()
   local dur = self.options.duration
   self.options.screen = (rv.profile.config.restrictToMainScreen and rv.mouseMonitorUtils.mainScreen) or self.options.screen or rv.mouseMonitorUtils.mainScreen
   local multiMove = type(self.command[1]) == "table"
   local moves = multiMove and self.command or {self.command} ---@cast moves (string|integer)[][]
   for i = 1, #moves do
      local cmd = moves[i]
      cmd[2] = cmd[2] or 0
   end
   local screen = rv.mouseMonitorUtils.screens[self.options.screen]
   screen:genPoints(moves, self.options.relative, self.pID)
   self.continuous = (dur and dur ~= 0)
   self.singleTrigger = not self.continuous
   if self.continuous then
      if self.options.interrupts == nil then self.options.interrupts = rv.profile.config.defaultThreadInterrupt end
      self.unstable = rv.profile.config.defaultThreadCancel
      if self.options.cancel ~= nil then self.unstable = self.options.cancel end
   end
   self:finishInit()
end

-- MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@async
function MousePositionMacro:execute()
   rv.mouseMonitorUtils:mouseMoveWrapper(self.options, self.pID) -- the actual movement takes place here.
end

---@param depth? integer
function MousePositionMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. (self.options.relative and "Shift mouse by " or "Move mouse to [") .. (rv.tbl:prettyTab(self.rawCommand, nil, true)) .. "]" end

return MousePositionMacro
