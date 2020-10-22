local tl = ...---@type MainLibObject
local type = type
local BaseMacro = tl:classImport('BaseMacro')

---@class DocToggleMacro:BaseMacro
local DocToggleMacro = BaseMacro:new()
DocToggleMacro.singleTrigger=true

function DocToggleMacro:execute()
  tl.scriptStates.docMode = not tl.scriptStates.docMode
  tl:put((not tl.scriptStates.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end


return DocToggleMacro