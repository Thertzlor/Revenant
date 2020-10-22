local tl = ...---@type MainLibObject
local remove,type = remove,type
local FlagMacro = tl:classImport('FlagMacro')

---@class FlagToggleMacro:FlagMacro
local FlagToggleMacro = FlagMacro:new()
FlagToggleMacro.singleTrigger = true

return FlagToggleMacro