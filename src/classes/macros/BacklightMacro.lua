local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local BacklightMacro = MacroDefinition:new()---@class BacklightMacro:MacroDefinition
BacklightMacro.singleTrigger = true
BacklightMacro.lintProperties={__none={}}
---@param event Event
function BacklightMacro:execute(event)
  tl.logitech:backLightControl(self.command, event.family)
end

return BacklightMacro