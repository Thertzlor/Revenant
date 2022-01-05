local rv = ...---@type MainLibObject
local rep = string.rep
--=============================================================
---@class PaginationMacro:MacroDefinition
local PaginationMacro = rv:classImport('MacroDefinition'):new()
PaginationMacro.lintProperties = { __none = {} }
PaginationMacro.lintCommand = { maxLength = 0 }
PaginationMacro.singleTrigger = true
PaginationMacro.terminus = false

---@protected
function PaginationMacro:execute()
    rv.lcd:refresh(true)
end

---@param depth number

function PaginationMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Next LCD page"
end

return PaginationMacro