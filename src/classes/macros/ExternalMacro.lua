local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

---@class ExternalMacro:MacroDefinition
local ExternalMacro = MacroDefinition:new()

function ExternalMacro:execute(event)
   tl.logitech.externalMacroWrapper(self.command,event.dir,event.dirMatch)
end

return ExternalMacro