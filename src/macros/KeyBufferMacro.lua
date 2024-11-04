local rv = ... ---@type Revenant
local super = rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _KeyBufferOptions:MacroOptions
---@field scope? "family"|"global"|"key" #should the key be buffered for a specific type of device or globally?
---@field exclusive? boolean #Should this buffer override any previously set buffer?
--[[=============================================================]] --
---Assign macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@alias AssignKeyBuffer  MacroInitDefinition<"keybuffer","kb",_KeyBufferOptions,string[]>
--[[=============================================================]] --
---A macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@class (exact) KeyBufferMacro:MacroDefinition
---@field command string
---@field keys KeyObject[]
---@field options _KeyBufferOptions
local KeyBufferMacro = super:new()
KeyBufferMacro.type = "keybuffer"
KeyBufferMacro.singleTrigger = true
KeyBufferMacro.lintProperties = { --
   scope = {type = "string", values = {"family", "global", "key"}},
   exclusive = {type = "boolean"}
}
KeyBufferMacro.lintCommand = {type = "string"}
---@protected
---@async
function KeyBufferMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self.keys = rv.keys:keyParser(self.command, true)
   self.options.scope = self.options.scope or "global"
   self:finishInit()
end

---Adding a string buffer, the actual logic is done in the string module.
---@param event Event
function KeyBufferMacro:execute(event)
   if self.command == "" and not self.options.exclusive then return end
   rv.keys:addKeyBuffer(self.keys, event.family, event.keyNum, self.options.scope, self.options.exclusive)
end

---@param depth? integer
function KeyBufferMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Input buffer \"" .. self.command .. "\"" end

return KeyBufferMacro
