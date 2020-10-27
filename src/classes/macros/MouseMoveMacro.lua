local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
---@class MouseMoveMacro:MacroDefinition
local MouseMoveMacro = MacroDefinition:new()
MouseMoveMacro.singleTrigger = true

---@param event Event
function MouseMoveMacro:execute(event)
  tl.mouseMonitorUtils:mouseMove(self.command,self.options,event.direction,self.pID)
end

return MouseMoveMacro