local rv = ... ---@type Revenant
local rep = string.rep

--[[=============================================================]] --
---Assign a Macro that triggers the Revenant Documentation Mode
---@alias AssignDocToggle MacroInitDefinition|mt<"documentation"|"doc">
--[[=============================================================]] --
---@class DocToggleMacro:MacroDefinition A Macro that triggers the Revenant Documentation Mode
local DocToggleMacro = rv:classImport('MacroDefinition'):new()
DocToggleMacro.lintProperties = { __none = {} }
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = { maxLength = 0 }
DocToggleMacro.terminus = false


function DocToggleMacro:parseInstructions()
    rv.lcd:parseToTextDisplay("Documentation Mode Deactivated", '__doc_0')
    rv.lcd:parseToTextDisplay("Documentation Mode Activated", '__doc_1')
    self:finishInit()
end

function DocToggleMacro:execute()
    rv.scriptStates.docMode = not rv.scriptStates.docMode
    rv.lcd:displayOnLCD((not rv.scriptStates.docMode) and '__doc_0' or '__doc_1', nil, rv.profile.config.LCDMessageDuration)
end

---@param depth? integer
function DocToggleMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Toggle documentation mode'
end

return DocToggleMacro
