local tl = ...---@type MainLibObject
local type = type
local MacroDefinition = tl:classImport('MacroDefinition')---@type MacroDefinition

local DocToggleMacro = MacroDefinition:new()---@class DocToggleMacro:MacroDefinition
DocToggleMacro.singleTrigger=true
DocToggleMacro.lintProperties={__none={}}
function DocToggleMacro:execute()
  tl.scriptStates.docMode = not tl.scriptStates.docMode
  tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

return DocToggleMacro