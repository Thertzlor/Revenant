local tl = ...---@type MainLibObject
local rep, SetMouseDPITableIndex, SetMouseDPITable, type, concat = string.rep, SetMouseDPITableIndex, SetMouseDPITable, type, table.concat
--=============================================================
---@class DpiMacro:MacroDefinition
---@field command (number|number[])[]
local DpiMacro = tl:classImport('MacroDefinition'):new()
DpiMacro.lintProperties = { __none = {} }
DpiMacro.lintCommand = { maxLength = 2, type = { "number", "table" }, tableKeys = "number", tableTypes = "number" }
DpiMacro.singleTrigger = true

---@protected
function DpiMacro:execute()
    local cmd = self.command[1]
    if type(cmd) == "number" then SetMouseDPITableIndex(cmd)
    else SetMouseDPITable(cmd, self.command[2]) end
end

function DpiMacro:export(depth)
    local cmd = self.command
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (type(cmd[1]) == "number" and "DPI index " .. cmd[1]
    or ("DPI table [" .. concat(cmd[1], ',') .. ']' .. (cmd[2] and ' index ' .. cmd[2] or '')))
end

return DpiMacro