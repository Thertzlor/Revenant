local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
---@class MouseMoveMacro:BaseMacro
local MouseMoveMacro = BaseMacro:new()
MouseMoveMacro.singleTrigger = true

---@param event Event
function MouseMoveMacro:execute(event)
  tl.mouseMonitorUtils:mouseMove(self.command,self.options,event.direction,self.pID)
end

return MouseMoveMacro