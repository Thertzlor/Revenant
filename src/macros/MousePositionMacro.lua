local rv = ... ---@type Revenant
local type, super = type, rv.importer:classImport("MacroDefinition")
---@class (exact) _MousePositionOptions:ThreadedMacroOptions
---@field screen? integer #the number of the screen to move to. Main screen by default.
---@field relative? boolean #If true the mouse moves relative to its current position
---@field velocity? integer #speed of the mouse movements in pixels per second
---@field duration? integer #the duration of the mouse movement
---@field durationMode? "total"|"step" #Decide if the value of "duration" refers to one step of the movement or the entire macro.
--[[=============================================================]] --
---@class (exact) ExtendedCoordinates:UserCoordinates
---@field velocity? integer
---@field duration? integer
---@field relative? boolean
---@field r? boolean #shorthand for duration
---@field d? integer #shorthand for duration
---@field v? integer #shorthand for velocity
--[[=============================================================]] --
---@class __MousePositionShorthands
---@field s? integer #Shorthand for "screen"
---@field d? integer #Shorthand for "duration"
---@field r? boolean #Shorthand for "relative"
---@field v? number #Shorthand for "velocity"
---Shorthand for "play"
---@field p?
---|"normal" # Play when the button is pressed
---|"toggle" # Play when the button is pressed, cancel when pressed again.
---|"hold" # Play while the button is held, cancel on keyup
---|"ptoggle" # Play while the button is pressed, pause when pressed again
---|"phold" # play while the button is held, pause on keyup.
--[[=============================================================]] --
---Assign a macro to move your mouse across the screen, instantly, or continuously.
---@alias AssignMousePosition MacroInitDefinition<"mouseposition","p",_MousePositionOptions|__MousePositionShorthands,UserCoordinates|ExtendedCoordinates[]>
--[[=============================================================]] --
---A macro to move your mouse across the screen, instantly, or continuously.
---@class (exact) MousePositionMacro:MacroDefinition
---@field options _MousePositionOptions
---@field unstable boolean
---@field command (UserCoordinates|ExtendedCoordinates)[]
local MousePositionMacro = super:new()
MousePositionMacro.type = "mouseposition"
MousePositionMacro.lintProperties = { --
   screen = {type = "number", range = {0}},
   relative = {type = "boolean"},
   durationMode = {type = "string", values = {"step", "total"}},
   duration = {type = "number", range = {0}},
   velocity = {type = "number", range = {0}}
}

MousePositionMacro.lintCommand = {
   type = {"string", "number", "table"},
   tableOptions = {
      { --
         type = {"string", "number"},
         maxLength = 2,
         minLength = 1
      },
      velocity = {type = "number", range = {0}},
      duration = {type = "number", range = {0}},
      relative = {type = "boolean"},
      v = {type = "number", range = {0}},
      d = {type = "number", range = {0}},
      r = {type = "boolean"}
   }
}

MousePositionMacro.shorthands = {s = "screen", d = "duration", v = "velocity", r = "relative", p = "play"}

---@async
function MousePositionMacro:parseInstructions()
   local dur = self.options.duration
   self.options.durationMode = self.options.durationMode or "total"
   self.options.screen = (rv.profile.config.restrictToMainScreen and rv.mouseMonitorUtils.mainScreen) or self.options.screen or self.options.relative and 0 or rv.mouseMonitorUtils.mainScreen
   if self.options.duration and self.options.velocity then error("Duration and velocity can't be set at the same time.") end
   local multiMove = type(self.command[1]) == "table"
   local moves = multiMove and self.command or {self.command} ---@cast moves ExtendedCoordinates[]
   local subdur = false
   for i = 1, #moves do
      local cmd = moves[i]
      cmd[2] = cmd[2] or 0
      if (cmd.d or cmd.duration) and (cmd.v or cmd.velocity) then error("Duration and velocity can't be set at the same time.") end
      if (cmd.d or cmd.duration or cmd.v or cmd.velocity) then subdur = true end
   end
   local screenTab = self.options.screen == 0 and rv.mouseMonitorUtils.screens or {rv.mouseMonitorUtils.screens[self.options.screen]}
   for i = 1, #screenTab do
      local screen = screenTab[i]
      if not screen then error("Monitor " .. i .. " does not exist in your configuration") end
      screen:genPoints(moves, self.options.relative, self.pID)
   end
   self.continuous = subdur or (dur and dur ~= 0)
   self.singleTrigger = not self.continuous
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
