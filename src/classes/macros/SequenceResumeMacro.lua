local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
local type = type
---@class SequenceResumeMacro:BaseMacro
local SequenceResumeMacro = BaseMacro:new()
SequenceResumeMacro.singleTrigger = true

function SequenceResumeMacro:parseInstructions()
  self.command = {}
  local cmd= self.rawCommand
  local processed = 0
  if type(cmd) == "string" and #cmd ~= 0 then cmd = {cmd} 
  elseif type(cmd) == "string" then
    self:finishInit()
    return
  end
  local function getName(string)
    local foundId = self:awaitId(string)
    if foundId then self.command[#self.command+1]=foundId end
    processed = processed +1
    if processed == #cmd then self:finishInit() end
  end
  for i = 1, #cmd do
    self:async(getName,cmd[i])
  end
end
function SequenceResumeMacro:execute()
  tl.coroutines:tRes(self.command)
end

return SequenceResumeMacro