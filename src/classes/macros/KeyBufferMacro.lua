local rv = ...---@type MainLibObject
local type, rep = type, string.rep
---@class KeyBufferMacro:MacroDefinition
---@field command string
local KeyBufferMacro = rv:classImport('MacroDefinition'):new()

KeyBufferMacro.lintProperties = { __none = {} }
KeyBufferMacro.lintCommand = { type = "string" }
---@protected
function KeyBufferMacro:parseInstructions()
    self.command = self.rawCommand[1]
    self:finishInit()
end

--
---@param event Event
function KeyBufferMacro:execute(event)
    rv.str:addStringBuffer(self.command, event.family, event.keyNum, event.mode, self.options.scope)
end

function KeyBufferMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Input buffer "' .. self.command .. '"'
end

return KeyBufferMacro