local tl = ...
local SetMKeyState, Sleep, GetMKeyState, GetRunningTime = SetMKeyState,Sleep,GetMKeyState,GetRunningTime
--->>> Polling related vars nabbed form g-max====================================================================================

if tl.PollInterval == 0 then tl.PollInterval = 1 end --Prevent low poll rate from Crashing the program.
tl.PollFamily = "lhc"	-- current mice don't have M-states, so this is a good choice
tl.PollDeadTime = 100	-- settling time (in milliseconds) during which old poll events are drained
tl.PollRateC = 0
tl.PollRateSum = 0
tl.PollLastPoll = 0
tl.PollRate = tl.PollInterval
tl.PollRateCI = 1000/tl.PollRate
tl.OnPoll = false
tl.cutine = 0

--->>> Task and Polling functions nabbed from g-max nabbed from kgober (modified) ===============================================================================

function tl.InitPolling()
  tl.ActiveState = GetMKeyState_Hook(tl.PollFamily)
  SetMKeyState_Hook(tl.ActiveState, tl.PollFamily)
end

function tl.Poll(event, arg, family, st)
  if st == nil and tl.StateTimer ~= nil then return end
  local t = GetRunningTime()
  if family == tl.PollFamily then
    if event == "M_PRESSED" and arg ~= tl.ActiveState then
      if tl.StateTimer ~= nil and t >= tl.StateTimer then tl.StateTimer = nil end
      if tl.StateTimer == nil then tl.ActiveState = arg end
      tl.StateTimer = t + tl.PollDeadTime
    elseif event == "M_RELEASED" and arg == tl.ActiveState then
      tl.PollRateSum = tl.PollRateSum + (t - tl.PollLastPoll)
      tl.PollLastPoll = t
      tl.PollRateC = tl.PollRateC + 1
      if tl.PollRateC == tl.PollRateCI then
        tl.PollRate = tl.PollRateSum/tl.PollRateCI
        tl.PollRateSum=0;tl.PollRateC=0
      end
      if tl.OnPoll then OnPollEvent() end
      Sleep(tl.PollInterval)
      SetMKeyState_Hook(tl.ActiveState, tl.PollFamily)
    end
  end
end

GetMKeyState_Hook = GetMKeyState

GetMKeyState = function(family)
  family = family or "kb"
  if family == tl.PollFamily then
    return tl.ActiveState
  elseif family == "audio" then
    return 1
  else
    return GetMKeyState_Hook(family)
  end
end
SetMKeyState_Hook = SetMKeyState

SetMKeyState = function(mkey, family)
  family = family or "kb"
  if family == tl.PollFamily then
    if mkey == tl.ActiveState then return end
    tl.ActiveState = mkey
    tl.StateTimer = GetRunningTime() + tl.PollDeadTime
  end
  return SetMKeyState_Hook(mkey, family)
end

-- Task Management functions (by kgober)
function tl.DoTasks()
  local t = GetRunningTime()
  for key, task in pairs(tl.TaskList) do
    if t >= task.time and task.paused == false then
      tl.cutine = key
      local s, d = coroutine.resume(task.task, task.run)
      if (not s) or ((d or -1) < 0) then
        tl.TaskList[key] = nil
        tl.seQueue()
        tl.cutine = 0
      else
        task.time = task.time + d
      end
    elseif task.paused == true then
      task.time = t
    end
  end
end

function tl.TaskRun(key, func, ...)
  tl.TaskAbort(key)
  local task = {}
  if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~=nil then task.isTemp = 1 end
  task.time = GetRunningTime()
  task.task = coroutine.create(func)
  task.run = true
  task.paused = false
  tl.cutine = key
  if tl.roDown[key] then
    tl.wipe(tl.roDown[key])
  else
    tl.roDown[key]={}
  end
  local s, d = coroutine.resume(task.task, unpack(arg))
  if (s) and ((d or -1) >= 0) then
    task.time = task.time + d
    tl.TaskList[key] = task
  end
end

function tl.TaskAbort(key)
  local task = tl.TaskList[key]
  if task ~= nil then
    tl.put("Stopping Task: "..key)
    task.run = false
    tl.macroStats[(key or "null")].seqPosition=nil
    tl.macroStats[(key or "null")].buffer = nil
    tl.TaskList[key] = nil
    for i = #tl.squ, 1, -1 do
      if tl.squ[i][1] == key then table.remove(tl.squ,i) end
    end
    tl.allUp(key)
    tl.cutine = 0
  end
end

function tl.TaskRunning(key)
  local task = tl.TaskList[key]
  if task == nil then return false end
  return task.run
end

function tl.OnPollEventIni()
  if type(_G["OnPollEvent"]) == "function" then tl.OnPoll = true end
end

function OnPollEvent() 				-- played by Library on every Poll event
  if tl.mousePositionCheck then tl.mouseCheckFunc() end
end