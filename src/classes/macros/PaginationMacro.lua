local rv = ... ---@type Revenant
local super = rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---Assign a macro to display the next page of text on the LCD display
---@alias AssignPagination  MacroInitDefinition | mt<"page","pg">
--[[=============================================================]] --
---A macro to display the next page of text on the LCD display
---@class PaginationMacro:MacroDefinition
local PaginationMacro = super:new()
PaginationMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {}
}
PaginationMacro.lintCommand = {maxLength = 0}
PaginationMacro.singleTrigger = true
PaginationMacro.terminus = false

---@protected
---@async
function PaginationMacro:execute()
   rv.lcd:refresh(true) -- calling the refresh LCD function with the advance parameter
end

---@param depth? integer
function PaginationMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Next LCD page" end

return PaginationMacro
