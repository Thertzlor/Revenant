local rv = ... ---@type Revenant

--[[=============================================================]] --
---Assign a Macro that triggers the Revenant Documentation Mode
---@alias AssignDocToggle MacroInitDefinition|mt<"documentation","doc">
--[[=============================================================]] --
---@class DocToggleMacro:MacroDefinition #A Macro that triggers the Revenant Documentation Mode
local DocToggleMacro = rv.importer:classImport("MacroDefinition"):new()
DocToggleMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {}
}
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = {maxLength = 0}
DocToggleMacro.terminus = false

---@async
function DocToggleMacro:parseInstructions()
   rv.lcd:parseToTextDisplay("Documentation Mode Deactivated", "__doc_0")
   rv.lcd:parseToTextDisplay("Documentation Mode Activated", "__doc_1")
   self:finishInit() -- all we need for this macro is the text to display
end

---@async
function DocToggleMacro:execute()
   rv.states.scriptStates.docMode = not rv.states.scriptStates.docMode -- setting the script into documentation mode, or back
   rv.lcd:displayOnLCD((not rv.states.scriptStates.docMode) and "__doc_0" or "__doc_1", nil, rv.profile.config.LCDMessageDuration)
end

---@param depth? integer
function DocToggleMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Toggle documentation mode" end

return DocToggleMacro
