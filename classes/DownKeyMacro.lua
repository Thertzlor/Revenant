local tl = ... ---@type MainLibObject
local BaseKeyMacro = tl:classImport("BaseKeyMacro")

---@class DownKeyMacro:BaseKeyMacro
local DownKeyMacro = BaseKeyMacro:new()
DownKeyMacro.triggerMode = 1;

return DownKeyMacro
