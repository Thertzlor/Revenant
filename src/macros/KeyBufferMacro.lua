local rv = ... ---@type Revenant
local super = rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _KeyBufferOptions:MacroOptions
---@field scope? "family"|"global"|"key" #should the key be buffered for a specific type of device or globally?
--[[=============================================================]] --
---Assign macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@alias AssignKeyBuffer  MacroInitDefinition<"bufferkey","kb",_KeyBufferOptions,string[]>
--[[=============================================================]] --
---A macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@class KeyBufferMacro:MacroDefinition
---@field command string
---@field options _KeyBufferOptions
local KeyBufferMacro = super:new()
KeyBufferMacro.type = "bufferkey"
KeyBufferMacro.singleTrigger = true
KeyBufferMacro.lintProperties = { ---@type OptionsLintPreset
   scope = {type = "string", values = {"family", "global", "key"}}
}
KeyBufferMacro.lintCommand = {type = "string"}
---@protected
---@async
function KeyBufferMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self.options.scope = self.options.scope or "key"
   self:finishInit()
end

---Adding a string buffer, the actual logic is done in the string module.
---@param event Event
function KeyBufferMacro:execute(event) rv.str:addStringBuffer(self.command, event.family, event.keyNum, self.options.scope) end

---@param depth? integer
function KeyBufferMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Input buffer \"" .. self.command .. "\"" end

return KeyBufferMacro
