local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport("BaseMacro")

---@class ModeChangeMacro:BaseMacro
local ModeChangeMacro = BaseMacro:new()

function ModeChangeMacro:execute(event)
 tl.logitech:modeWrapper(self.command[1], self.command[2], event.family)
end

return ModeChangeMacro
