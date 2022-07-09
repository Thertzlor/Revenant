local rv = ... ---@type Revenant
local rep = string.rep

--[[=============================================================]] --
---@class _KeyBufferOptions:MacroOptions
---@field scope "family"|"global"
--[[=============================================================]] --
---@alias KeyBufferDefinition _KeyBufferOptions | MacroInitDefinition
--[[=============================================================]] --
---@class KeyBufferMacro:MacroDefinition
---@field command string
---@field options _KeyBufferOptions
local KeyBufferMacro = rv:classImport('MacroDefinition'):new()
KeyBufferMacro.singleTrigger = true
KeyBufferMacro.lintProperties = { scope = { type = "string", values = { "family", "global" } } }
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

---@param depth? integer
function KeyBufferMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Input buffer "' .. self.command .. '"'
end

return KeyBufferMacro
