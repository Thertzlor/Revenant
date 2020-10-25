local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')

---@class BufferKeyMacro:BaseMacro
local BufferKeyMacro = BaseMacro:new()
BufferKeyMacro.singleTrigger = true

---@param event Event
function BufferKeyMacro:execute(event)
  tl.str:addStringBuffer(self.command,event.family,event.keyNum,event.mode,self.options.scope)
end

return BufferKeyMacro