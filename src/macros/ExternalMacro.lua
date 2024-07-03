local rv = ... ---@type Revenant
local super = rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _ExternalMacroOptions:MacroOptions
---Should the macro play normally, only while held or toggle it on and off?<br> analogous to the play options in the lua GUI
---@field play?
---|"normal" # Play once when the button is pressed.
---|"hold" #Play while the button is held down.
---|"toggle" #toggle macro on and off. Restarts from the beginning every time.
---If the value isn't 1 the macro will abort all other macros before playing
---@field macroBlocking? boolean
---@field lcd? integer|boolean #If and how long the output of this macro should be shown on the lcd
--[[=============================================================]] --
---@class __ExternalMacroShorthands
---Shorthand for "play"
---@field p?
---|"normal" # Play once when the button is pressed.
---|"hold" #Play while the button is held down.
---|"toggle" #toggle macro on and off. Restarts from the beginning every time.
--[[=============================================================]] --
---Assign a macro for playing external Logitech Macros defined in LGS.
---@alias AssignExternalMacro MacroInitDefinition<"externalmacro","e",_ExternalMacroOptions|__ExternalMacroShorthands,string[]>
--[[=============================================================]] --
---A macro for playing external Logitech Macros defined in LGS.
---@class ExternalMacro:MacroDefinition
---@field options _ExternalMacroOptions
local ExternalMacro = super:new()
ExternalMacro.type = "externalmacro"
ExternalMacro.lintProperties = { ---@type OptionsLintPreset
   play = {type = "string", values = {"hold", "toggle", "normal"}},
   macroBlocking = {type = "boolean"},
   lcd = {type = {"number", "boolean"}}
}
ExternalMacro.shorthands = {p = "play"}
ExternalMacro.lintCommand = {type = "string"}

---@param event Event
---@async
function ExternalMacro:execute(event)
   ---LGS can only run a single macro at once, so there can only be a single name.
   local run = rv.logitech:externalMacroWrapper(self.command, self.options, event.direction)
   if self.options.lcd then rv.lcd:displayOnLCD(self.pID .. "_" .. (run and 1 or 2), 1, self.msgDuration) end
end

---@private
---@async
function ExternalMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self.singleTrigger = self.options.play ~= "hold" -- this cancels macro on key up
   if self.options.lcd == nil then self.options.lcd = true end
   if self.options.macroBlocking == nil then self.options.macroBlocking = true end
   if self.options.lcd then -- if we won't display anything we don't parse.
      for i = 1, 2 do rv.lcd:parseToTextDisplay((i == 1 and "Playing" or "Stopping") .. " LGS macro \"" .. self.command .. "\"", self.pID .. "_" .. i, 1) end
   end
   self:finishInit()
end

---@param depth? integer
function ExternalMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Play LGS macro \"" .. self.command .. "\"" end

return ExternalMacro
