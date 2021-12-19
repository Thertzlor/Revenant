local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')---@type MacroDefinition

local DocToggleMacro = MacroDefinition:new()---@class DocToggleMacro:MacroDefinition
DocToggleMacro.lintProperties = { __none = {} }
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = { maxLength = 0 }

--TODO currently doesn't toggle back?
function DocToggleMacro:execute()
    tl.scriptStates.docMode = not tl.scriptStates.docMode
    tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

return DocToggleMacro