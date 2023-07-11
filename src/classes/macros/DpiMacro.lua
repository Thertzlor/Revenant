local rv = ... ---@type Revenant
local SetMouseDPITableIndex, SetMouseDPITable, type, concat, super = SetMouseDPITableIndex, SetMouseDPITable, type, table.concat, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _DpiMacroOptions:MacroOptions
---@field lcd boolean|number #If and how long to show the LCD output for this macro
--[[=============================================================]] --
---Assign a macro used to change dpi settings on your mouse.
---@alias AssignDpi MacroInitDefinition<"setdpi","dpi",_DpiMacroOptions,(l<integer>)[]>
--[[=============================================================]] --
---A macro used to change dpi settings on your mouse.
---@class DpiMacro:MacroDefinition
---@field command {[1]:integer|integer[],[2]:integer}
---@field options _DpiMacroOptions
local DpiMacro = super:new()
DpiMacro.type = "setdpi"
DpiMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {},
   lcd = {type = {"boolean", "number"}}
}
DpiMacro.lintCommand = {maxLength = 2, type = {"number", "table"}, tableKeys = "number", tableTypes = "number"}
DpiMacro.singleTrigger = true

---@async
function DpiMacro:parseInstructions()
   if self.options.lcd == nil then self.options.lcd = true end
   local outText = ""
   local cmd = self.command
   if type(cmd[1]) == "table" then
      outText = "Setting DPI values to " .. concat(cmd[1] --[[@as (number[])]] , ", ") .. ((cmd[2] and " and indexing to " .. cmd[2]) or "")
   else
      outText = "Setting DPI index to " .. cmd[1]
   end
   if self.options.lcd then rv.lcd:parseToTextDisplay(outText, self.pID .. "_out", 1) end
   self:finishInit()
end

---@protected
---@async
function DpiMacro:execute()
   local cmd = self.command[1] -- depending on the number of entries we set the index or the whole table.
   if type(cmd) == "number" then
      SetMouseDPITableIndex(cmd)
   else
      SetMouseDPITable(cmd --[[@as (integer[])]] , self.command[2] or 1)
   end
   if self.options.lcd then rv.lcd:displayOnLCD(self.pID .. "_out", 1, self.msgDuration) end
end

---@param depth? integer
function DpiMacro:export(depth)
   local cmd = self.command
   return self:indent(depth) .. self.titleExport .. (type(cmd[1]) == "number" and "DPI index " .. cmd[1] ---@cast cmd number[][]
   or ("DPI table [" .. concat(cmd[1], ",") .. "]" .. (cmd[2] and " index " .. cmd[2] or "")))
end

return DpiMacro
