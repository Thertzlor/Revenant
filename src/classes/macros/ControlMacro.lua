local tl = ...---@type MainLibObject
local type = type
local BaseMacro = tl:classImport('BaseMacro')

---@class BaseControlMacro:BaseMacro
local BaseControlMacro = BaseMacro:new()
BaseControlMacro.singleTrigger = true
function BaseControlMacro:parseInstructions()
  local processed = 0
  local subList = self.command[1]
  self.controlTargets={}
  self.controlArguments = self.command[2]
  self.targetGroup = (self.type == "cyclecontrol" and "cycle") or (self.type == "sequenceControl" and "sequence")
  if subList == "all" or subList == "" then
    self:finishInit()
    return 
  end
  local cmd = (type(subList) ~= "table" and {subList}) or subList
  local function setSub(name)
    local foundId = self:awaitId(name)
    if foundId then self.controlTargets[#self.controlTargets+1]=foundId end
    processed = processed +1
    if processed == #cmd then self:finishInit() end
  end
  for i = 1, #cmd do self:async(setSub,cmd[i]) end
end

function BaseControlMacro:execute()
  if #self.controlTargets ~= 0 then
    for i = 1, #self.controlTargets do
      local target = self.profile.macroIndex[self.controlTargets[i]]
      if target then target:control(self.controlArguments) end
    end
  else
    local allMacs = self.profile:findMacros(self.targetGroup)
    for i = 1, #allMacs do
      local target = self.profile.macroIndex[allMacs[i]]
      if target then target:control(self.controlArguments) end
    end
  end
end

return BaseControlMacro