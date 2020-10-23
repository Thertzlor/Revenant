local tl = ... ---@type MainLibObject
local BaseKeyMacro = tl:classImport("BaseKeyMacro")

---@class UpKeyMacro:BaseKeyMacro
local UpKeyMacro = BaseKeyMacro:new()
UpKeyMacro.triggerMode = 2;

return UpKeyMacro