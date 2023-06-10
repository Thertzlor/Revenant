local rv = ... ---@type Revenant
local rep = string.rep

--[[=============================================================]] --
---@class _KeyBufferOptions:MacroOptions
---@field scope "family"|"global" #should the key be buffered for a specific type of device or globally?
--[[=============================================================]] --
---Assign macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@alias AssignKeyBuffer _KeyBufferOptions | MacroInitDefinition | mt<"bufferkey"|"kb">
--[[=============================================================]] --
---A macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@class KeyBufferMacro:MacroDefinition
---@field command string
---@field options _KeyBufferOptions
local KeyBufferMacro = rv.importer:classImport("MacroDefinition"):new()
KeyBufferMacro.singleTrigger = true
KeyBufferMacro.lintProperties = { ---@type OptionsLintPreset
   scope = {type = "string", values = {"family", "global"}}
}
KeyBufferMacro.lintCommand = {type = "string"}
---@protected
function KeyBufferMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self:finishInit()
end

--
---@param event Event
function KeyBufferMacro:execute(event) rv.str:addStringBuffer(self.command, event.family, event.keyNum, event.mode, self.options.scope) end

---@param depth? integer
function KeyBufferMacro:export(depth)
   depth = depth or 0
   local indent = rep("  ", depth) or ""
   return indent .. self.titleExport .. "Input buffer \"" .. self.command .. "\""
end

return KeyBufferMacro
