local rv = ...---@type MainLibObject
local MoveMouseWheel,rep = MoveMouseWheel, string.rep
---@class MouseWheelMacro:MacroDefinition
---@field command number
local MouseWheelMacro = rv:classImport('MacroDefinition'):new()
MouseWheelMacro.singleTrigger = true
MouseWheelMacro.lintProperties = { __none = {} }
MouseWheelMacro.lintCommand = { type = "number", maxLength = 1 }

function MouseWheelMacro:execute()
    MoveMouseWheel(self.command)
end

---@param depth number
function MouseWheelMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Move the mouse wheel by "..self.command
end

return MouseWheelMacro