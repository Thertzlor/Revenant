local tl = ... ---@type MainLibObject
local BaseKeyMacro = tl:classImport("BaseKeyMacro")

---@class ToggleKeyMacro:BaseKeyMacro
local ToggleKeyMacro = BaseKeyMacro:new()
ToggleKeyMacro.triggerMode = 3;
ToggleKeyMacro.singleTrigger=true
return ToggleKeyMacro
