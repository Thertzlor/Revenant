local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local ExternalMacro = MacroDefinition:new()---@class ExternalMacro:MacroDefinition

ExternalMacro.lintProperties={
  play = {type = "string",values = {"hold", "toggle", "normal"}}
}

ExternalMacro.shortHands = {p="play"}

function ExternalMacro:execute(event)
  tl.logitech.externalMacroWrapper(self.command,event.dir,event.dirMatch)
end

return ExternalMacro