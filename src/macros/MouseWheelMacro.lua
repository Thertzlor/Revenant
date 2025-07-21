local rv = ... ---@type Revenant
local MoveMouseWheel, super = MoveMouseWheel, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---Assign a macro to scroll the mouse wheel by one or more positions.
---@alias AssignMouseWheel MacroInitDefinition<"mousewheel","w",{},integer[]>
--[[=============================================================]] --
---A macro to scroll the mouse wheel by one or more positions.
---@class (exact) MouseWheelMacro:MacroDefinition
---@field command integer
local MouseWheelMacro = super:new()
MouseWheelMacro.type = "mousewheel"
MouseWheelMacro.singleTrigger = true
MouseWheelMacro.lintProperties = { --
   __none = {}
}
MouseWheelMacro.lintCommand = {type = "number", maxLength = 1}

---@async
function MouseWheelMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self:finishInit()
end

function MouseWheelMacro:execute() MoveMouseWheel(self.command) end

---@param depth? integer
function MouseWheelMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Move the mouse wheel by " .. self.command end

return MouseWheelMacro