local tl = ...---@type MainLibObject

local DocToggleMacro = tl:classImport('MacroDefinition'):new()---@class DocToggleMacro:MacroDefinition
DocToggleMacro.lintProperties = { __none = {} }
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = { maxLength = 0 }

function DocToggleMacro:execute()
    tl.scriptStates.docMode = not tl.scriptStates.docMode
    tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

return DocToggleMacro