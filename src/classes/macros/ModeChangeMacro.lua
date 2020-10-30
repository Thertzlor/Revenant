local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport("MacroDefinition")

local ModeChangeMacro = MacroDefinition:new()---@class ModeChangeMacro:MacroDefinition



function ModeChangeMacro:execute(event)
  tl.logitech:modeWrapper(self.command[1], self.command[2], event.family,(self.state.matchDown or self.state.matchUp))
end

return ModeChangeMacro