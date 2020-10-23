local tl, Base = ...---@type MainLibObject
local ceil, huge, abs, GetRunningTime, type, insert, remove, unpack, OutputDebugMessage, running, pairs =
  math.ceil,math.huge,math.abs,GetRunningTime,type,table.insert,table.remove,unpack,OutputDebugMessage,coroutine.running,pairs
local toggled = {}
--=============================================================
---@class MacroExecutionModule
---: Functions controlling Macros that are run on key press
local MacroExecutionModule=Base:new()
MacroExecutionModule.lastDocumented = ""


---Alternate waiting function for multi click keys
---@param key string
---@param endMoment number
---@param id string
---@param fam string
---@param num number
local function _altTimer(key, endMoment, _, __, fam, num)
  key._meta.multiTimer = endMoment
  while GetRunningTime() < endMoment do
    tl.coroutines:wait(tl.config.pollInterval)
  end
  key._meta.multiTimer = nil
  if key._meta.multiClick ~= nil and (key.mode ~= "stack" or not key.mode) then
    tl.validator:launchMacro(num, fam, key[key._meta.multiClick], 4)
  end
  key._meta.multiClick = nil
  return -1
end

local function _timer(key, endMoment, interval, curNum, fam, num)
  if curNum > #key then
    curNum = #key
  end
  key._meta.multiTimer = endMoment
  while GetRunningTime() < endMoment and key._meta.multiClick == curNum do
    tl.coroutines:wait(tl.config.pollInterval)
  end
  if key._meta.multiClick == curNum or curNum == #key then
    if key.mode ~= "stack" then
      for i = 1, curNum do
        tl.validator:launchMacro(num, fam, key[i], 4)
      end
    else
      tl.validator:launchMacro(num, fam, key[curNum], 4)
    end
    key._meta.multiTimer = nil
    key._meta.multiClick = nil
  else
    _timer(key, (GetRunningTime() + interval), curNum, fam, num)
  end
  return -1
end

function MacroExecutionModule:cycleReset(buts) --here, cycles for cycling sequences are reset, either for a specific one or all of them.
  if buts and type(buts) == "table" then
    for k = 1, #buts do
      local v = buts[k]
      self:cycleReset(v)
    end
  elseif buts and type(buts) == "string" and buts ~= "" then
    for g = 1, #tl.stringPresets.families do
      local tk = tl.str:token(tl.stringPresets.families[g])
      tl.deviceState[tk].stable["_" .. buts] = nil
      tl.deviceState[tk].unstable["_" .. buts] = nil
    end
  elseif buts == "" or buts == 0 then
    for g = 1, #tl.stringPresets.families do
      local tk = tl.str:token(tl.stringPresets.families[g])
      tl.helperUtils.wipe(tl.deviceState[tk].stable["_" .. buts])
      tl.helperUtils.wipe(tl.deviceState[tk].unstable["_" .. buts])
    end
  end
end

local function _setCyclePosition(cycleName, position,fam)
  if type(position) ~= "number" then return end
  local cycleMacro = tl.macroIndex[cycleName]
  
  local cycleState = cycleMacro.cancel > 0 and tl.deviceState[fam].stable["_" .. cycleName] or tl.deviceState[fam].unstable["_" .. cycleName]
  tl.tbl:cycleIndex(#cycleMacro,position,cycleState)
end

local function _setCyclesCompleted(cycleName, number)
  if type(number)~="number" then return end
  tl.macroIndex[cycleName]._meta.cyclesComplete = number
end

function MacroExecutionModule:cycleControl(name,positionOption,completedOption,fam)
  if name and type(name) == "table" then
    for k = 1, #name do
      local v = name[k]
      self:cycleControl(v,positionOption)
    end
    return
  end
  if positionOption == 0 then 
    self:cycleReset(name)
  else
    _setCyclePosition(name,positionOption,fam)
  end
  if completedOption then
    _setCyclesCompleted(completedOption,fam)
  end
end

function MacroExecutionModule:sequenceControl(name,option)
  if name and type(name) == "table" then
    for k = 1, #name do
      local v = name[k]
      self:sequenceControl(v,option)
    end
    return
  end

  local setting = option
  local controls ={
    p="tPause",
    pause="tPause",
    c="taskAbort",
    cancel="taskAbort",
    r="tRes",
    resume="tRes",
  }

  if not setting then
    if tl.config.pauseOnDefault then
      if tl.polling:taskRunning(name) then  setting = "p"
      else setting = "r" end
    else setting = "c" end
  end
  
  tl.coroutines[controls[setting]](tl.coroutines,name)
end

---timing function for multi-click keys
---@param cont GenericMacro
---@param fam string
---@param num number
function MacroExecutionModule:timerKey(cont, fam, num)
  local time = cont.timer or tl.config.multiClickTime
  local meta = cont._meta
  if not meta.multiTimer and not meta.multiClick then
    meta.multiClick = 1
    tl.coroutines:taskRun(cont.pID,fam,num,((cont.timer == "absolute" and _altTimer) or _timer),cont,(GetRunningTime() + time),time,1)
  elseif meta.multiTimer ~= nil then
    meta.multiClick = meta.multiClick + 1
  end
  if cont.timer ~= "absolute" then
    return -1
  end

  local timeActive = meta.multiTimer
  local clickNum = meta.multiClick

  if cont.mode == nil or cont.mode ~= "stack" then
    if timeActive == nil and cont[clickNum] ~= nil then
      tl.validator:launchMacro(num, fam, cont[clickNum], 4)
      meta.multiClick = nil
    end
  else
    for i = 1, clickNum do
      if cont[i] ~= nil then
        tl.validator:launchMacro(num, fam, cont[i], 4)
      end
    end
  end
  if timeActive == nil then
    meta.multiClick = nil
  end
  return -1
end

---function for cancelling the execution of staggered sequences
---@param buttons string|table
---@param dir string
function MacroExecutionModule:staggerCancel(buttons, dir)
  if dir and dir ~= "down" then
    return
  end
  if buttons and type(buttons) == "table" then
    for k = 1, #buttons do
      local v = buttons[k]
      self:staggerCancel(v)
    end
  elseif buttons and type(buttons) == "string" and buttons ~= "" then
    tl.macroIndex[buttons]._meta.stagTimer = nil
  elseif buttons == nil or buttons == 0 then
    for k, _ in pairs(tl.macroIndex) do
      local cStat = tl.macroIndex[k]._meta
      cStat.stagTimer = nil
    end
  end
end

---Logging and LCD output function
---@param msg string
function MacroExecutionModule:outputWrapper(msg)
  if msg[1] == nil then
    error("No Message to Display")
  end
  local persist = tl.config.persistLCD
  local stay = msg[2] or tl.config.persistLCD
  if msg.debug then
    OutputDebugMessage(msg[1])
    return
  end
  if type(msg[1]) == "table" then
    tl.tbl:prettyTab(msg[1])
  elseif msg.noLCD == 1 then
    tl.logitech:putNoLCD(msg[1])
  else
    tl.config.persistLCD = stay
    tl:put(msg[1])
    tl.config.persistLCD = persist
  end
end

return MacroExecutionModule