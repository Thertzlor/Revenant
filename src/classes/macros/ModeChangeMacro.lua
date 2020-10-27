local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport("MacroDefinition")

---@class ModeChangeMacro:MacroDefinition
local ModeChangeMacro = MacroDefinition:new()

function ModeChangeMacro:execute(event)
  tl.logitech:modeWrapper(self.command[1], self.command[2], event.family)
end

return ModeChangeMacro