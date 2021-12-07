local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local MouseMoveMacro = MacroDefinition:new()---@class MouseMoveMacro:MacroDefinition
MouseMoveMacro.singleTrigger = true
--MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@param event Event
function MouseMoveMacro:execute(event)
  tl.mouseMonitorUtils:mouseMove(self.command,self.options,event.direction,self.pID)
end

return MouseMoveMacro