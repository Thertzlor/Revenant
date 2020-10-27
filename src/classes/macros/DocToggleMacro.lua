local tl = ...---@type MainLibObject
local type = type
local MacroDefinition = tl:classImport('MacroDefinition')

---@class DocToggleMacro:MacroDefinition
local DocToggleMacro = MacroDefinition:new()
DocToggleMacro.singleTrigger=true

function DocToggleMacro:execute()
  tl.scriptStates.docMode = not tl.scriptStates.docMode
  tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end


return DocToggleMacro