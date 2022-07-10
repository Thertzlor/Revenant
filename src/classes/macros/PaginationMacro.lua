local rv = ... ---@type Revenant
local rep = string.rep

--[[=============================================================]] --
---Assign a macro to display the next page of text on the LCD display
---@alias AssignPagination  MacroInitDefinition | mt<"page"|"pg">
--[[=============================================================]] --
---A macro to display the next page of text on the LCD display
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

---@param depth? integer
function PaginationMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Next LCD page"
end

return PaginationMacro
