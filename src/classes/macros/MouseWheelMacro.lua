local rv = ...---@type MainLibObject
local MoveMouseWheel = MoveMouseWheel
---@class MouseWheelMacro:MacroDefinition
---@field command number
local MouseWheelMacro = rv:classImport('MacroDefinition'):new()
MouseWheelMacro.singleTrigger = true
MouseWheelMacro.lintProperties = { __none = {} }
MouseWheelMacro.lintCommand = { type = "number", maxLength = 1 }

function MouseWheelMacro:execute()
    MoveMouseWheel(self.command)
end

return MouseWheelMacro