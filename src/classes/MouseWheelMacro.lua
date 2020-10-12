local tl = ...---@type MainLibObject
local MoveMouseWheel = MoveMouseWheel
local BaseMacro = tl:classImport('BaseMacro')

---@class MouseWheelMacro:BaseMacro
local MouseWheelMacro = BaseMacro:new()

function MouseWheelMacro:execute() MoveMouseWheel(self.command) end

return MouseWheelMacro