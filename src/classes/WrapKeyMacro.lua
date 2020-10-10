local tl = ... ---@type MainLibObject
local BaseKeyMacro = tl:classImport("BaseKeyMacro")

---@class WrapKeyMacro:BaseKeyMacro
local WrapKeyMacro = BaseKeyMacro:new()
WrapKeyMacro.triggerMode = 3;

return WrapKeyMacro
