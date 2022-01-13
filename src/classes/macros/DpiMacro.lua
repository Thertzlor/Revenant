local rv = ...---@type Revenant
local rep, SetMouseDPITableIndex, SetMouseDPITable, type, concat = string.rep, SetMouseDPITableIndex, SetMouseDPITable, type, table.concat
--=============================================================
---@class _DpiMacroOptions:MacroOptions
---@field lcd boolean|number
--=============================================================
---@alias DpiDefinition MacroInitDefinition|_DpiMacroOptions
--=============================================================
---@class DpiMacro:MacroDefinition
---@field command table<number,number|number[]>
---@field options _DpiMacroOptions
local DpiMacro = rv:classImport('MacroDefinition'):new()
DpiMacro.lintProperties = { __none = {}, lcd = { type = { "boolean", "number" } } }
DpiMacro.lintCommand = { maxLength = 2, type = { "number", "table" }, tableKeys = "number", tableTypes = "number" }
DpiMacro.singleTrigger = true

function DpiMacro:parseInstructions()
    if self.options.lcd == nil then self.options.lcd = true end
    local outText = ''
    local cmd = self.command
    if type(cmd[1]) == "table" then
        outText = "Setting DPI values to " .. concat(cmd[1], ', ') .. ((cmd[2] and ' and indexing to ' .. cmd[2]) or '')
    else outText = "Setting DPI index to " .. cmd[1] end
    if self.options.lcd then rv.lcd:parseToDisplayDefinition(outText, self.pID .. '_out', 1) end
    self:finishInit()
end

---@protected
function DpiMacro:execute()
    local cmd = self.command[1]
    if type(cmd) == "number" then SetMouseDPITableIndex(cmd)
    else SetMouseDPITable(cmd, self.command[2] or 1) end
    if self.options.lcd then rv.lcd:displayOnLCD(self.pID .. '_out', 1, self.msgDuration) end
end

---@param depth number
function DpiMacro:export(depth)
    local cmd = self.command
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (type(cmd[1]) == "number" and "DPI index " .. cmd[1]
    or ("DPI table [" .. concat(cmd[1], ',') .. ']' .. (cmd[2] and ' index ' .. cmd[2] or '')))
end

return DpiMacro