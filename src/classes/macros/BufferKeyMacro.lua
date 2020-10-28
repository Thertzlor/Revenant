local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

local BufferKeyMacro = MacroDefinition:new()---@class BufferKeyMacro:MacroDefinition
BufferKeyMacro.singleTrigger = true

---@param event Event
function BufferKeyMacro:execute(event)
  tl.str:addStringBuffer(self.command,event.family,event.keyNum,event.mode,self.options.scope)
end

return BufferKeyMacro