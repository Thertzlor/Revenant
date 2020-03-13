---@type MainLibObject
local tl = ...
local  Sleep, GetRunningTime, type, remove,pairs,unpack, resume, create, GetMKeyState_Hook, SetMKeyState_Hook =
Sleep,GetRunningTime, type,table.remove,pairs,unpack, coroutine.resume, coroutine.create, GetMKeyState, SetMKeyState
--=============================================================
---@type PollingModule
---: Task and Polling functions nabbed from g-max nabbed from kgober (modified) 
tl.polling = {pollControls = {}}

local GetMKeyState = function(family)
  family = family or "lhc"
  if family == tl.config.pollFamily then
    return tl.polling.pollControls.activeState
  elseif family == "lhc" then
    return 1
  else
    return GetMKeyState_Hook(family)
  end
end

local SetMKeyState = function(mkey, family)
  family = family or "lhc"
  if family == tl.config.pollFamily then
    if mkey == tl.polling.pollControls.activeState then return end
    tl.polling.pollControls.activeState = mkey
    tl.polling.pollControls.stateTimer = GetRunningTime() + tl.polling.pollControls.pollDeadTime
  end
  return SetMKeyState_Hook(mkey, family)
end

---played by Library on every poll event
local function _onPollEvent()
  if tl.mousePositionCheck then tl.mouseMonitorUtils.mouseCheckFunc() end
end

---Starts the polling task.
function tl.polling.initPolling()
  -->>> Polling related vars nabbed form g-max====================================================================================
  if tl.config.pollInterval <= 0 then tl.put("throttling polling") tl.config.pollInterval = 1 end --Prevent low poll rate from Crashing the program.
  tl.polling.pollControls.pollDeadTime = 100	-- settling time (in milliseconds) during which old poll events are drained
  tl.polling.pollControls.pollRateC = 0
  tl.polling.pollControls.pollRateSum = 0
  tl.polling.pollControls.pollLastPoll = 0
  tl.polling.pollControls.pollRate = tl.config.pollInterval
  tl.polling.pollControls.pollRateCI = 1000/tl.polling.pollControls.pollRate
  tl.polling.pollControls.onPoll = false
  tl.polling.pollControls.cutine = 0
  tl.polling.pollControls.activeState = GetMKeyState_Hook(tl.config.pollFamily)
  SetMKeyState_Hook(tl.polling.pollControls.activeState, tl.config.pollFamily)
end

---The main polling function
---@param event string
---@param arg number
---@param st number
function tl.polling.poll(event, arg, st)
  if st == nil and tl.polling.pollControls.stateTimer ~= nil then return end
  local t = GetRunningTime()
  if event == "M_PRESSED" and arg ~= tl.polling.pollControls.activeState then
    if tl.polling.pollControls.stateTimer ~= nil and t >= tl.polling.pollControls.stateTimer then tl.polling.pollControls.stateTimer = nil end
    if tl.polling.pollControls.stateTimer == nil then tl.polling.pollControls.activeState = arg end
    tl.polling.pollControls.stateTimer = t + tl.polling.pollControls.pollDeadTime
  elseif event == "M_RELEASED" and arg == tl.polling.pollControls.activeState then
    tl.polling.pollControls.pollRateSum = tl.polling.pollControls.pollRateSum + (t - tl.polling.pollControls.pollLastPoll)
    tl.polling.pollControls.pollLastPoll = t
    tl.polling.pollControls.pollRateC = tl.polling.pollControls.pollRateC + 1
    if tl.polling.pollControls.pollRateC == tl.polling.pollControls.pollRateCI then
      tl.polling.pollControls.pollRate = tl.polling.pollControls.pollRateSum/tl.polling.pollControls.pollRateCI
      tl.polling.pollControls.pollRateSum=0;tl.polling.pollControls.pollRateC=0
    end
    if tl.polling.pollControls.onPoll then _onPollEvent() end
    Sleep(tl.config.pollInterval)
    SetMKeyState_Hook(tl.polling.pollControls.activeState, tl.config.pollFamily)
  end
end


-- Task Management functions (by kgober)
---Continue running tasks.
function tl.polling.doTasks()
  local t = GetRunningTime()
  for key, task in pairs(tl.coroutines.taskList) do
    if t >= task.time and task.paused == false then
      tl.polling.pollControls.cutine = key
      local s, d = resume(task.task, task.run)
      if (not s) or ((d or -1) < 0) then
        tl.coroutines.taskList[key] = nil
        tl.coroutines.seQueue()
        tl.polling.pollControls.cutine = 0
      else
        task.time = task.time + d
      end
    elseif task.paused == true then
      task.time = t
    end
  end
end

---Executes a function as a coroutine.
---@param key string
---@param fam string
---@param num number
---@param func function
function tl.polling.taskRun(key,fam,num, func, ...)
  tl.polling.taskAbort(key)
  local task = {}
  if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~=nil then task.isTemp = 1 end
  task.time = GetRunningTime()
  task.task = create(func)
  task.run = true
  task.paused = false
  task.fam = fam
  task.num = num
  tl.polling.pollControls.cutine = key
  if tl.keyStates.roDown[key] then
    tl.helperUtils.wipe(tl.keyStates.roDown[key])
  else
    tl.keyStates.roDown[key]={}
  end
  local s, d = resume(task.task, unpack(arg))
  if (s) and ((d or -1) >= 0) then
    task.time = task.time + d
    tl.coroutines.taskList[key] = task
  end
end

---Aborts a task.
---@param key string
function tl.polling.taskAbort(key)
  local task = tl.coroutines.taskList[key]
  if task ~= nil then
    tl.logitech.putNoLCD("Stopping Task")
    if task.fam and task.num then tl.deviceState[task.fam]["_b"..task.num] = nil end
    task.run = false
    tl.macroIndex[key]._meta.seqPosition=nil
    tl.coroutines.taskList[key] = nil
    for i = #tl.coroutines.taskQueue, 1, -1 do
      if tl.coroutines.taskQueue[i][1] == key then remove(tl.coroutines.taskQueue,i) end
    end
    tl.str.allUp(key)
    tl.polling.pollControls.cutine = 0
  end
end

---Checks if a  task is running.
---@param key string
function tl.polling.taskRunning(key)
  local task = tl.coroutines.taskList[key]
  if task == nil then return false end
  return task.run
end

---Sets the inPoll Value.
function tl.polling.onPollEventIni()
  if type(_onPollEvent) == "function" then tl.polling.pollControls.onPoll = true end
end