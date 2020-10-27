local tl = ...---@type MainLibObject
local MoveMouseWheel = MoveMouseWheel
local MacroDefinition = tl:classImport('MacroDefinition')

---@class MouseWheelMacro:MacroDefinition
local MouseWheelMacro = MacroDefinition:new()
MouseWheelMacro.singleTrigger = true
function MouseWheelMacro:execute()
  MoveMouseWheel(self.command)
end

return MouseWheelMacro