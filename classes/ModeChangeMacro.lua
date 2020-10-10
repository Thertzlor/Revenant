local tl = ...
---@type MainLibObject
---@type BaseMacro
local BaseMacro = tl:classImport("BaseMacro")

---@class ModeChangeMacro:BaseMacro
local ModeChangeMacro = BaseMacro:new()

function ModeChangeMacro:execute(Event)
    tl.logitech:modeWrapper(self.command[1], self.command[2], Event.family)
end

return ModeChangeMacro
