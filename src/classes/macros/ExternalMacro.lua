local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local ExternalMacro = MacroDefinition:new()---@class ExternalMacro:MacroDefinition

function ExternalMacro:execute(event)
   tl.logitech.externalMacroWrapper(self.command,event.dir,event.dirMatch)
end

return ExternalMacro