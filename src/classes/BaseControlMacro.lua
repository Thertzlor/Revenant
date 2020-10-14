local tl = ...---@type MainLibObject
local type = type
local BaseMacro = tl:classImport('BaseMacro')

---@class BaseControlMacro:BaseMacro
local BaseControlMacro = BaseMacro:new()

function BaseControlMacro:parseSubMacros()
  local processed = 0
  local subList = self.command[1]
  
  local cmd = (type(subList) ~= "table" and {subList}) or subList
  local function setSub(name)
    local foundId = self:awaitId(name)
    if foundId then self.subMacros[#self.subMacros+1]=foundId end
    processed = processed +1
    if processed == #cmd then self:finishInit() end
  end
  for i = 1, #cmd do self:async(setSub,cmd[i]) end
end

function BaseControlMacro:execute()
  for i = 1, #self.subMacros do
    local target = self.profile.macroIndex[self.subMacros[i]]
    target[self.controlName](target,self.controlArguments)
  end
end


return BaseControlMacro