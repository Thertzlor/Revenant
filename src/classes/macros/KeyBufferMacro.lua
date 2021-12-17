local tl = ...---@type MainLibObject
local MacroDefinition, type = tl:classImport('MacroDefinition'), type
local KeyBufferMacro = MacroDefinition:new()---@class KeyBufferMacro:MacroDefinition

KeyBufferMacro.lintProperties = { __none = {} }
---@protected
function KeyBufferMacro:parseInstructions()
    self.command = self.rawCommand[1]
    self.titleExport = "buffer: " .. (type(self.command) == "table" and tl.tbl:prettyTab(self.command, nil, true) or self.command)
    self:finishInit()
end

--
---@param event Event
function KeyBufferMacro:execute(event)
    tl.str:addStringBuffer(self.command, event.family, event.keyNum, event.mode, self.options.scope)
end

return KeyBufferMacro