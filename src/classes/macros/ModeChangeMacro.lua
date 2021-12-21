local tl = ...---@type MainLibObject

local ModeChangeMacro =  tl:classImport("MacroDefinition"):new()---@class ModeChangeMacro:MacroDefinition
ModeChangeMacro.lintProperties = { __none = {} }
ModeChangeMacro.lintCommand = { type = { "number", "string" } }

function ModeChangeMacro:execute(event)
    tl.logitech:modeWrapper(self.command[1], self.command[2], event.family, (self.state.matchDown or self.state.matchUp))
end

return ModeChangeMacro