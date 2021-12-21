local tl = ...---@type MainLibObject
local type =  type
---@class KeyBufferMacro:MacroDefinition
---@field command string
local KeyBufferMacro = tl:classImport('MacroDefinition'):new()

KeyBufferMacro.lintProperties = { __none = {} }
KeyBufferMacro.lintCommand = { type = "string" }
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