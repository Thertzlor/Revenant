local tl = ... ---@type MainLibObject
local BaseKeyMacro = tl:classImport("BaseKeyMacro")

---@class SimpleKeyMacro:BaseKeyMacro
local SimpleKeyMacro = BaseKeyMacro:new()
SimpleKeyMacro.triggerMode = 0;

return SimpleKeyMacro