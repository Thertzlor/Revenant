local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local KeyBufferMacro = MacroDefinition:new()---@class KeyBufferMacro:MacroDefinition
KeyBufferMacro.singleTrigger = true

---@param event Event
function KeyBufferMacro:execute(event)
  tl.str:addStringBuffer(self.command,event.family,event.keyNum,event.mode,self.options.scope)
end

return KeyBufferMacro