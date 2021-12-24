local tl = ...---@type MainLibObject
local rep = string.rep
--=============================================================
---@class PaginationMacro:MacroDefinition
local PaginationMacro = tl:classImport('MacroDefinition'):new()
PaginationMacro.lintProperties = { __none = {} }
PaginationMacro.lintCommand = { maxLength = 0 }
PaginationMacro.singleTrigger = true

---@protected
function PaginationMacro:execute()
    tl.lcd:refresh(true)
end

function PaginationMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Next LCD page"
end

return PaginationMacro