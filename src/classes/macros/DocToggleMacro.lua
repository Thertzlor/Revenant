local tl = ...---@type MainLibObject
local rep = string.rep
---@class DocToggleMacro:MacroDefinition
local DocToggleMacro = tl:classImport('MacroDefinition'):new()
DocToggleMacro.lintProperties = { __none = {} }
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = { maxLength = 0 }

function DocToggleMacro:execute()
    tl.scriptStates.docMode = not tl.scriptStates.docMode
    tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

function DocToggleMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Toggle documentation mode'
end

return DocToggleMacro