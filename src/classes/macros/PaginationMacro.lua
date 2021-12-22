local tl = ...---@type MainLibObject
--=============================================================
---@class PaginationMacro:MacroDefinition
local PaginationMacro = tl:classImport('MacroDefinition'):new()
PaginationMacro.lintProperties = { __none = {} }
PaginationMacro.lintCommand={maxLength = 0}
PaginationMacro.singleTrigger = true

---@protected
function PaginationMacro:execute()
    tl.lcd:refresh(true)
end

return PaginationMacro