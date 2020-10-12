local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')

---@class ExternalMacro:BaseMacro
local ExternalMacro = BaseMacro:new()

function ExternalMacro:execute(event) 
   tl.logitech.externalMacroWrapper(self.command,event.dir,event.dirMatch)
end

return ExternalMacro