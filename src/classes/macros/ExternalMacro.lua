local rv = ... ---@type Revenant

--[[=============================================================]] --
---@class _ExternalMacroOptions:MacroOptions
---@field play "hold"|"toggle"|"normal" #Should the macro play normally, only while held or toggle it on and off?
---@field macroBlocking 1|2|3 #If the value isn't 1 the macro will abort all other macros before playing
---@field lcd integer|boolean #If and how long the outpit of this macro should be shown on the lcd
--[[=============================================================]] --
---@class __ExternalMacroShorthands
---@field p "hold"|"toggle"|"normal" #Shorthand for "play"
--[[=============================================================]] --
---Assign a macro for playing external Logitech Macros defined in LGS.
---@alias AssignExternalMacro MacroInitDefinition|_ExternalMacroOptions|mt<"externalmacro","e">|__ExternalMacroShorthands|string[]
--[[=============================================================]] --
---A macro for playing external Logitech Macros defined in LGS.
---@class ExternalMacro:MacroDefinition
---@field options _ExternalMacroOptions
local ExternalMacro = rv.importer:classImport("MacroDefinition"):new()
ExternalMacro.lintProperties = { ---@type OptionsLintPreset
   play = {type = "string", values = {"hold", "toggle", "normal"}},
   macroBlocking = {type = "number", range = {1, 3}},
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
   if self.options.lcd then -- if we won't display anything we don't parse.
      for i = 1, 2 do rv.lcd:parseToTextDisplay((i == 1 and "Playing" or "Stopping") .. " LGS macro \"" .. self.command .. "\"", self.pID .. "_" .. i, 1) end
   end
   self:finishInit()
end

---@param depth? integer
function ExternalMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Play LGS macro \"" .. self.command .. "\"" end

return ExternalMacro
