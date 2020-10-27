local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

---@class BacklightMacro:MacroDefinition
local BacklightMacro = MacroDefinition:new()
BacklightMacro.singleTrigger = true

---@param event Event
function BacklightMacro:execute(event)
  tl.logitech:backLightControl(self.command, event.family or event.virtualFamily)
end

return BacklightMacro