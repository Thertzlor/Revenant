---@type MainLibObject
local tl = ...
local SetMKeyState, Sleep, GetMKeyState, GetRunningTime, type, remove,pairs,unpack, resume, create, GetMKeyState_Hook, SetMKeyState_Hook =
SetMKeyState,Sleep,GetMKeyState,GetRunningTime, type,table.remove,pairs,unpack, coroutine.resume, coroutine.create
-->>>> Task and Polling functions nabbed from g-max nabbed from kgober (modified) ===============================================================================

---played by Library on every poll event
local function _onPollEvent()
  if tl.mousePositionCheck then tl.mouseCheckFunc() end
end

---Starts the polling task.
function tl.initPolling()
  -->>> Polling related vars nabbed form g-max====================================================================================
  if tl.config.pollInterval <= 0 then tl.put("throttling polling") tl.config.pollInterval = 1 end --Prevent low poll rate from Crashing the program.
  tl.pollControls = {}
  tl.pollControls.pollDeadTime = 100	-- settling time (in milliseconds) during which old poll events are drained
  tl.pollControls.pollRateC = 0
  tl.pollControls.pollRateSum = 0
  tl.pollControls.pollLastPoll = 0
  tl.pollControls.pollRate = tl.config.pollInterval
  tl.pollControls.pollRateCI = 1000/tl.pollControls.pollRate
  tl.pollControls.onPoll = false
  tl.pollControls.cutine = 0
  tl.pollControls.activeState = GetMKeyState_Hook(tl.config.pollFamily)
  SetMKeyState_Hook(tl.pollControls.activeState, tl.config.pollFamily)
end

---The main polling function
---@param event string
---@param arg number
---@param st number
function tl.poll(event, arg, st)
  if st == nil and tl.pollControls.stateTimer ~= nil then return end
  local t = GetRunningTime()
  if event == "M_PRESSED" and arg ~= tl.pollControls.activeState then
    if tl.pollControls.stateTimer ~= nil and t >= tl.pollControls.stateTimer then tl.pollControls.stateTimer = nil end
    if tl.pollControls.stateTimer == nil then tl.pollControls.activeState = arg end
    tl.pollControls.stateTimer = t + tl.pollControls.pollDeadTime
  elseif event == "M_RELEASED" and arg == tl.pollControls.activeState then
    tl.pollControls.pollRateSum = tl.pollControls.pollRateSum + (t - tl.pollControls.pollLastPoll)
    tl.pollControls.pollLastPoll = t
    tl.pollControls.pollRateC = tl.pollControls.pollRateC + 1
    if tl.pollControls.pollRateC == tl.pollControls.pollRateCI then
      tl.pollControls.pollRate = tl.pollControls.pollRateSum/tl.pollControls.pollRateCI
      tl.pollControls.pollRateSum=0;tl.pollControls.pollRateC=0
    end
    if tl.pollControls.onPoll then _onPollEvent() end
    Sleep(tl.config.pollInterval)
    SetMKeyState_Hook(tl.pollControls.activeState, tl.config.pollFamily)
  end
end

GetMKeyState_Hook = GetMKeyState

GetMKeyState = function(family)
  family = family or "lhc"
  if family == tl.config.pollFamily then
    return tl.pollControls.activeState
  elseif family == "lhc" then
    return 1
  else
    return GetMKeyState_Hook(family)
  end
end

SetMKeyState_Hook = SetMKeyState

SetMKeyState = function(mkey, family)
  family = family or "lhc"
  if family == tl.config.pollFamily then
    if mkey == tl.pollControls.activeState then return end
    tl.pollControls.activeState = mkey
    tl.pollControls.stateTimer = GetRunningTime() + tl.pollControls.pollDeadTime
  end
  return SetMKeyState_Hook(mkey, family)
end

-- Task Management functions (by kgober)
---Continue running tasks.
function tl.doTasks()
  local t = GetRunningTime()
  for key, task in pairs(tl.taskList) do
    if t >= task.time and task.paused == false then
      tl.pollControls.cutine = key
      local s, d = resume(task.task, task.run)
      if (not s) or ((d or -1) < 0) then
        tl.taskList[key] = nil
        tl.seQueue()
        tl.pollControls.cutine = 0
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
function tl.taskRun(key,fam,num, func, ...)
  tl.taskAbort(key)
  local task = {}
  if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~=nil then task.isTemp = 1 end
  task.time = GetRunningTime()
  task.task = create(func)
  task.run = true
  task.paused = false
  task.fam = fam
  task.num = num
  tl.pollControls.cutine = key
  if tl.roDown[key] then
    tl.wipe(tl.roDown[key])
  else
    tl.roDown[key]={}
  end
  local s, d = resume(task.task, unpack(arg))
  if (s) and ((d or -1) >= 0) then
    task.time = task.time + d
    tl.taskList[key] = task
  end
end

---Aborts a task.
---@param key string
function tl.taskAbort(key)
  local task = tl.taskList[key]
  if task ~= nil then
    tl.put("Stopping Task")
    if task.fam and task.num then tl.state[task.fam]["_b"..task.num] = nil end
    task.run = false
    tl.macroStats[(key or "null")].seqPosition=nil
    tl.taskList[key] = nil
    for i = #tl.squ, 1, -1 do
      if tl.squ[i][1] == key then remove(tl.squ,i) end
    end
    tl.allUp(key)
    tl.pollControls.cutine = 0
  end
end

---Checks if a  task is running.
---@param key string
function tl.taskRunning(key)
  local task = tl.taskList[key]
  if task == nil then return false end
  return task.run
end

---Sets the inPoll Value.
function tl.onPollEventIni()
  if type(_G["_OnPollEvent"]) == "function" then tl.pollControls.onPoll = true end
end