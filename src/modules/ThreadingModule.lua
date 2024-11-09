local rv = ... ---@type Revenant
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack, resume, create, GetRunningTime, sub, randomseed, GetMKeyState_Hook, SetMKeyState_Hook = math.abs, math.floor, math.random, Sleep, type, table.insert, table.remove, pairs, coroutine.running, coroutine.yield, unpack, coroutine.resume, coroutine.create, GetRunningTime, string.sub, math.randomseed, GetMKeyState, SetMKeyState

--[[=============================================================]] --
---@class TaskData #holds data of a single task
---@field time integer #the time this task was started
---@field task thread #the thread this task runs in
---@field paused boolean #Is the task currently paused?
---@field fam? FamilyToken #the device family this task was launched from
---@field run boolean #is this task running?
---@field num? integer #key number a task corresponds to
---@field isTemp? boolean #is this a temporary cancelable task?
---@field pauseDur integer #the number of milliseconds the task will wait
--[[=============================================================]] --
---@class PollControls #Polling related vars nabbed from g-max
---@field activeState integer #the current M key state of the poll family
---@field onPoll boolean #does a poll hook function exist?
---@field pollDeadTime integer #settling time (in milliseconds) during which old poll events are drained
---@field pollLastPoll integer #time of last poll
---@field pollRate integer #how many milliseconds to wait between each polling events
---@field pollRateC integer #current poll rate
---@field pollRateCI integer #control timer to check polling offset
---@field pollRateSum integer #the sum of polling times
---@field stateTimer integer #time to wait until next poll
local pollControls = {}
local fixedLag = false ---@type number|false
local lagOffset = 0 ---the current lag offset in milliseconds
local lagThreshold = 50 ---minimum lag in milliseconds to trigger offset calculations
local maxLagSamples = 100 ---the maximum number of samples to store
local offsetLag = true ---true if we want to reduce lag on older computers
local totalLag = 0 ---the total amount of lag found during sampling
local lagSamples = 0 ---the number of samples collected for lag offset
local anotasks = 0 ---the number of tasks not bound to a specific key

---Functions that control coroutines
---@class ThreadingModule:BaseClass
---@field randomizer fun():number
---@field activeTask string|0
---@field noNextWaitLag boolean
---@field noNextMovementLag boolean
local ThreadingModule = rv.baseClass:new()
local taskRedirect = {} ---@type table<string,string>
local taskQueue = {} ---@type {[1]:string, [2]:FamilyToken, [3]:integer, [4]:string }[]
local taskList = {} ---@type table<string,TaskData>
ThreadingModule.activeTask = 0

---Generate random delays for events and keys
---@private
---@param num integer
---@param var integer
function ThreadingModule:_variance(num, var)
   if var == 0 or not var then return num end
   local result = num
   if var then result = abs(floor(result + ((var * (self.randomizer())) - (var / 2)))) --[[@as integer]] end
   return result
end

---Pause initiate random number generator.
function ThreadingModule:initRandom()
   local manualRandom = (rv.profile.assign.hooks or {}).onRandom
   if not manualRandom then
      randomseed(GetRunningTime())
      for _ = 1, 5 do random() end
   end
   self.randomizer = manualRandom or random
end

function ThreadingModule:outputLagOffset() return lagOffset end

function ThreadingModule:initLagSettings()
   if rv.profile.config.fixedWaitLag ~= 0 then
      fixedLag = rv.profile.config.fixedWaitLag
      lagOffset = fixedLag
   end
   offsetLag = fixedLag == false and rv.profile.config.offsetWaitLag
   lagThreshold = rv.profile.config.waitLagThreshold
   maxLagSamples = rv.profile.config.maxLagSamples
end

---Pause function for all coroutines.
---@param dur integer
---@param var? integer
---@param forceSleep? boolean
---@param thresholdOverride? number
---@async
function ThreadingModule:wait(dur, var, forceSleep, thresholdOverride)
   local finalDuration = ((var and var ~= 0 and self:_variance(dur, var)) or dur)
   local noLagDuration = finalDuration
   local thresh = thresholdOverride or lagThreshold
   local lagRelevant = (offsetLag or fixedLag ~= false) and not self.noNextWaitLag and finalDuration > thresh
   if lagRelevant then
      lagSamples = offsetLag and lagSamples + 1 or 0
      finalDuration = finalDuration + lagOffset
      if finalDuration < 0 then finalDuration = 0 end
   end
   local thenTime = lagRelevant and GetRunningTime() or 0
   local waitOutput = ((not forceSleep) and running() and yield(finalDuration)) or Sleep(finalDuration)
   if lagRelevant and offsetLag then
      local diff = (GetRunningTime() - thenTime)
      if (not thresholdOverride) and abs(noLagDuration - diff) > thresh then return waitOutput end
      if noLagDuration ~= 0 and diff ~= 0 then totalLag = totalLag + (noLagDuration - diff) end
      if lagSamples % maxLagSamples == 0 then
         totalLag = lagOffset
         lagSamples = 1
      end
      lagOffset = totalLag / lagSamples
   elseif self.noNextWaitLag then
      self.noNextWaitLag = false
   end
   return waitOutput
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskId string|table
---@async
function ThreadingModule:multiAbort(taskId)
   if taskId and type(taskId) == "string" and taskId ~= "" then
      self:taskAbort(taskId)
   elseif type(taskId) == "table" then
      for num = 1, #taskId do self:taskAbort(taskId[num]) end
   elseif taskId == 0 then
      if self.activeTask ~= 0 then self:taskAbort(self.activeTask --[[@as string]] ) end
   else
      for k in pairs(taskList) do self:taskAbort(k) end
   end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskId string|table|integer
---@async
function ThreadingModule:multiPause(taskId)
   if type(taskId) == "string" and taskId ~= "" then
      local realTask = taskRedirect[taskId] or taskId
      local taskState = taskList[realTask]
      if taskState ~= nil then
         taskState.paused = true
         rv.keys:releaseAll(realTask)
         self.activeTask = 0
      end
   elseif type(taskId) == "table" then
      for num = 1, #taskId do self:multiPause(taskId[num]) end
   elseif taskId == 0 then
      if self.activeTask ~= 0 then self:multiPause(self.activeTask) end
   else
      for _, v in pairs(taskList) do v.paused = true end
   end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskId string|table|number
function ThreadingModule:taskResume(taskId)
   if type(taskId) == "string" and taskId ~= "" then
      local realTask = taskRedirect[taskId] or taskId
      local taskState = taskList[realTask]
      if taskState ~= nil then taskState.paused = false end
   elseif type(taskId) == "table" then
      for num = 1, #taskId do self:taskResume(taskId[num]) end
   elseif taskId == 0 then
      if self.activeTask ~= 0 then self:taskResume(self.activeTask) end
   else
      for _, v in pairs(taskList) do v.paused = false end
   end
end

---Keeps track of what coroutines are currently running
---@param nam? string
---@param fam? FamilyToken
---@param num? integer
---@param inst? string
---@async
function ThreadingModule:sequenceQueue(nam, fam, num, inst, ...)
   if nam and inst then
      insert(taskQueue, {nam, fam, num, inst})
   else
      for i = #taskQueue, 1, -1 do
         local val = taskQueue[i]
         if taskList[val[1]] == nil then
            local macro = rv.profile.macroIndex[val[1]]
            self:taskRun(val[1], val[2], val[3], macro.execute, macro, val[4], unpack(arg))
            remove(taskQueue, i)
         end
      end
   end
end

---Executes a function as a coroutine.
---@param key? string
---@param fam? FamilyToken
---@param num? integer
---@param func async fun()
---@async
function ThreadingModule:taskRun(key, fam, num, func, ...)
   if key then self:taskAbort(key) end
   local task = {time = GetRunningTime(), task = create(func), pauseDur = 0, run = true, paused = false, fam = fam, num = num}
   if arg[1] and type(arg[1]) == "table" and arg[1] --[[@as {cancel:boolean}]] .cancel ~= nil then task.isTemp = 1 end
   local taskName = key
   if key then
      self.activeTask = key
      if rv.states.keyStates.taskDown[key] then
         rv.utils.wipe(rv.states.keyStates.taskDown[key])
      else
         rv.states.keyStates.taskDown[key] = {}
      end
   else
      taskName = "anon_" .. anotasks
      anotasks = anotasks + 1
   end
   local s, d = resume(task.task, unpack(arg))
   if taskName ~= nil and s and (d or -1) >= 0 then

      task.pauseDur = d
      task.time = task.time + d
      taskList[taskName] = task
   elseif s == false then
      error(d, 2)
   end
end

---@async
function ThreadingModule:tempCancel() for id, state in pairs(taskList) do if state.isTemp ~= nil then self:taskAbort(id) end end end

---Aborts a task.
---@param taskId string
---@async
function ThreadingModule:taskAbort(taskId)
   local realTask = taskRedirect[taskId] or taskId
   local task = taskList[realTask]
   if task ~= nil then
      if task.fam and task.num then
         rv.profile.deviceState[task.fam]["_b" .. task.num] = nil ---@type nil
      end
      if rv.profile.macroStates[realTask] then rv.profile.macroStates[realTask].seqPosition = nil end
      taskList[realTask] = nil
      for i = #taskQueue, 1, -1 do if taskQueue[i][1] == realTask then remove(taskQueue, i) end end
      if type(realTask) == "string" and sub(realTask, 1, 5) ~= "anon_" then rv.keys:releaseAll(realTask) end
      self.activeTask = 0
   end
end

---Adds a subtask
---@param taskId string
function ThreadingModule:addSubtask(taskId)
   local active = self.activeTask
   if active == 0 or active == taskId or not active then return end ---@cast active string
   taskRedirect[taskId] = active
end

---Removes a subtask
---@param taskId string
function ThreadingModule:removeSubtask(taskId) taskRedirect[taskId] = nil end

---Starts the polling task.
function ThreadingModule:initPolling()
   local config = rv.profile.config ---@class OptionsCollection
   if config.pollInterval <= 0 then
      rv:put("throttling polling")
      config.pollInterval = 1
   end -- Prevent low poll rate from Crashing the program.
   pollControls.pollDeadTime = 100
   pollControls.pollRateC = 0
   pollControls.pollRateSum = 0
   pollControls.pollLastPoll = 0
   pollControls.pollRate = config.pollInterval
   pollControls.pollRateCI = 1000 / pollControls.pollRate
   pollControls.onPoll = false
   self.activeTask = 0
   pollControls.activeState = GetMKeyState_Hook(config.pollFamily)
   SetMKeyState_Hook(pollControls.activeState, config.pollFamily)
end

---The main polling function
---@param event string
---@param argument integer
---@param st? number
function ThreadingModule:poll(event, argument, st)
   if st == nil and pollControls.stateTimer ~= nil then return end
   local profile = rv.profile
   local t = GetRunningTime()
   if event == "M_PRESSED" and argument ~= pollControls.activeState then
      if pollControls.stateTimer ~= nil and t >= pollControls.stateTimer then pollControls.stateTimer = nil end
      if pollControls.stateTimer == nil then pollControls.activeState = argument end
      pollControls.stateTimer = t + pollControls.pollDeadTime
   elseif event == "M_RELEASED" and argument == pollControls.activeState then
      pollControls.pollRateSum = pollControls.pollRateSum + (t - pollControls.pollLastPoll)
      pollControls.pollLastPoll = t
      pollControls.pollRateC = pollControls.pollRateC + 1
      if pollControls.pollRateC == pollControls.pollRateCI then
         pollControls.pollRate = pollControls.pollRateSum / pollControls.pollRateCI
         pollControls.pollRateSum = 0
         pollControls.pollRateC = 0
      end
      if pollControls.onPoll then profile.hooks.onPollHook() end
      Sleep(profile.config.pollInterval)
      SetMKeyState_Hook(pollControls.activeState, profile.config.pollFamily)
   end
end

-- Task Management functions (by kgober)
---Continue running tasks.
---@async
function ThreadingModule:doTasks()
   local t = GetRunningTime()
   for key, task in pairs(taskList) do
      if t >= task.time and task.paused == false then
         if sub(key, 1, 5) ~= "anon_" then self.activeTask = key end
         local s, d = resume(task.task, true)
         if d == nil then d = -1 end
         if (not s) or (d < 0) then
            taskList[key] = nil
            self:sequenceQueue()
            self.activeTask = 0
            if d and type(d) ~= "number" then rv:put(d) end
         else
            task.time = task.time + d
         end
      elseif task.paused == true then
         task.time = t
      end
   end
end

---Gives the status of a task. 0 for not running, 1 for running and 2 for paused
---@return 0|1|2
function ThreadingModule:taskStatus(key)
   local task = taskList[taskRedirect[key] or key]
   if task == nil then return 0 end
   return task.paused and 2 or 1
end

---Sets the onPoll Value.
function ThreadingModule:onPollEventIni() if type(rv.profile.hooks.onPollHook) == "function" then pollControls.onPoll = true end end

---this is called by LGS internally
---@param family HardwareFamily
---@diagnostic disable-next-line: unused-function, unused-local
local GetMKeyState = function(family)
   family = family or "lhc"
   if rv.profile.config.pollMKeysOnly or family == rv.profile.config.pollFamily then
      return pollControls.activeState
   elseif family == "lhc" then
      return 1
   else
      return GetMKeyState_Hook(family)
   end
end

---this is called by LGS internally
---@param mkey integer
---@param family HardwareFamily
---@diagnostic disable-next-line: unused-function, unused-local
local SetMKeyState = function(mkey, family)
   family = family or "lhc"
   if rv.profile.config.pollMKeysOnly or family == rv.profile.config.pollFamily then
      if mkey == pollControls.activeState then return end
      pollControls.activeState = mkey
      pollControls.stateTimer = GetRunningTime() + pollControls.pollDeadTime
   end
   return SetMKeyState_Hook(mkey, family)
end

return ThreadingModule
