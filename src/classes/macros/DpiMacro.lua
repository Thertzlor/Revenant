local tl = ...---@type MainLibObject
local rep, SetMouseDPITableIndex, SetMouseDPITable, type = string.rep, SetMouseDPITableIndex, SetMouseDPITable, type
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
    local secondaryCmd = self.command[2]
    if type(cmd) == "number" then SetMouseDPITableIndex(cmd)
    else SetMouseDPITable(cmd, secondaryCmd) end
end

--TODO:Finish export method
function DpiMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport
end

return DpiMacro