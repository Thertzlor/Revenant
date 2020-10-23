local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')

---@class BacklightMacro:BaseMacro
local BacklightMacro = BaseMacro:new()
BacklightMacro.singleTrigger = true

---@param event Event
function BacklightMacro:execute(event)
  tl.logitech:backLightControl(self.command, event.family or event.virtualFamily)
end

return BacklightMacro