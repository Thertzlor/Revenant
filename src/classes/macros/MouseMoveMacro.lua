local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local MouseMoveMacro = MacroDefinition:new()---@class MouseMoveMacro:MacroDefinition
MouseMoveMacro.singleTrigger = true

MouseMoveMacro.lintProperties={
  screen={type="number"},
  relative={type="boolean"},
  time={type="number"}
}

--MoveMouseToVirtual,MoveMouseTo,GetMousePosition
---@param event Event
function MouseMoveMacro:execute(event)
  local playMode = self.options.play or "normal"
  local dir = event.direction
  if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") 
  and self.direction ~= "up") or (self.direction == "up" and dir == "down") then return end
  tl.mouseMonitorUtils:mouseMoveWrapper(self.command,self.options,dir,self.pID)
end

return MouseMoveMacro