local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
local GetRunningTime = GetRunningTime
---@class MultiClickMacro:BaseMacro
local MultiClickMacro = BaseMacro:new()
MultiClickMacro.singleTrigger = true



---Alternate waiting function for multi click keys
---@private
---@param key string
---@param endMoment number
---@param id string
---@param fam string
---@param num number
function MultiClickMacro:altTimer(endMoment, _, __, fam, num)
local state,config = self.state,self.profile.config
state.multiTimer = endMoment
  while GetRunningTime() < endMoment do
    tl.coroutines:wait(config.pollInterval)
  end
  state.multiTimer = nil
  if state.multiClick ~= nil and (self.options.mode ~= "stack" or not self.options.mode) then
    local virtualEvent = {family = fam, keyNum = num, virtualType = 4} ---@type Event
    self.profile.macroIndex[self.command[state.multiClick][1]]:run(virtualEvent)
  end
  state.multiClick = nil
  return -1
end
---@private
function MultiClickMacro:timer(endMoment, interval, curNum, fam, num)
  local cmd,state,options = self.command,self.state,self.options
  if curNum > #cmd then
    curNum = #cmd
  end
  state.multiTimer = endMoment
  while GetRunningTime() < endMoment and state.multiClick == curNum do
    tl.coroutines:wait(self.profile.config.pollInterval)
  end
  if state.multiClick == curNum or curNum == #cmd then
    if options.mode ~= "stack" then
      for i = 1, curNum do
        tl.validator:launchMacro(num, fam, cmd[i], 4)
      end
    else
      tl.validator:launchMacro(num, fam, cmd[curNum], 4)
    end
    state.multiTimer = nil
    state.multiClick = nil
  else
    self:timer((GetRunningTime() + interval), curNum, fam, num)
  end
  return -1
end

function MultiClickMacro:parseInstructions()
  self.options.timer = self.options.timer or self.profile.config.multiClickTime

end

---timing function for multi-click keys
---@param cont GenericMacro
---@param fam string
---@param num number
function MultiClickMacro:execute(fam, num)
  local pID,options,cmd = self.pID,self.options,self.command
  local time = self.options.timer 
  local meta = self.state
  if not meta.multiTimer and not meta.multiClick then
    meta.multiClick = 1
    tl.coroutines:taskRun(pID,fam,num,((options.timer == "absolute" and self.altTimer) or self.timer),self,(GetRunningTime() + time),time,1)
  elseif meta.multiTimer ~= nil then
    meta.multiClick = meta.multiClick + 1
  end
  if options.timer ~= "absolute" then
    return -1
  end

  local timeActive = meta.multiTimer
  local clickNum = meta.multiClick

  if options.mode == nil or options.mode ~= "stack" then
    if timeActive == nil and cmd[clickNum] ~= nil then
      tl.validator:launchMacro(num, fam, cmd[clickNum], 4)
      meta.multiClick = nil
    end
  else
    for i = 1, clickNum do
      if cmd[i] ~= nil then
        tl.validator:launchMacro(num, fam, cmd[i], 4)
      end
    end
  end
  if timeActive == nil then
    meta.multiClick = nil
  end
  return -1
end


return MultiClickMacro