local tl = ...---@type MainLibObject
local MoveMouseWheel = MoveMouseWheel
local MacroDefinition = tl:classImport('MacroDefinition')

local MouseWheelMacro = MacroDefinition:new()---@class MouseWheelMacro:MacroDefinition
MouseWheelMacro.singleTrigger = true
MouseWheelMacro.lintProperties = { __none = {} }
MouseWheelMacro.lintCommand = { type = "string", maxLength = 1 }

function MouseWheelMacro:execute()
    MoveMouseWheel(self.command)
end

return MouseWheelMacro