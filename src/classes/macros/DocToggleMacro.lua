local rv = ...---@type MainLibObject
local rep = string.rep
---@class DocToggleMacro:MacroDefinition
local DocToggleMacro = rv:classImport('MacroDefinition'):new()
DocToggleMacro.lintProperties = { __none = {} }
DocToggleMacro.singleTrigger = true
DocToggleMacro.lintCommand = { maxLength = 0 }

function DocToggleMacro:execute()
    rv.scriptStates.docMode = not rv.scriptStates.docMode
    rv:put((not rv.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

---@param depth number
function DocToggleMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Toggle documentation mode'
end

return DocToggleMacro