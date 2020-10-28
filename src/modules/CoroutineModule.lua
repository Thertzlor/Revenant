local tl = ...---@type MainLibObject
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack, resume, create, GetRunningTime =
  math.abs,math.floor,math.random,Sleep,type,table.insert,table.remove,pairs,coroutine.running,coroutine.yield,unpack,coroutine.resume,coroutine.create,GetRunningTime
local Base = tl:classImport("BaseClass")
  --================================================================
---@class CoroutineModule
---: Functions that control coroutines
local CoroutineModule = tl.baseClass:new()
CoroutineModule.taskQueue = {}
CoroutineModule.taskList = {}

---Generate random delays for events and keys
---@param num number
---@param dev number
local function _deviate(num, dev)
  if dev == 0 or not dev then return num end
  local result = num
  if dev < 1 then
    if dev < 0 then dev = abs(dev) end
    dev = floor(num * dev)
  end
  result = result + random((dev * -1), dev)
  return result
end

---Pause function for all coroutines.
---@param dur number
---@param dev number
function CoroutineModule:wait(dur, dev, forceSleep)
  local finalDur = _deviate(dur, dev)
  return ((not forceSleep) and running() and yield(finalDur)) or Sleep(finalDur)
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:multiAbort(taskey)
  if taskey and type(taskey) == "string" and taskey ~= "" then
    self:taskAbort(taskey)
  elseif type(taskey) == "table" then
    for num = 1, #taskey do self:taskAbort(taskey[num]) end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      self:taskAbort(tl.polling.pollControls.cutine)
    end
  else
    for k, _ in pairs(self.taskList) do self:taskAbort(k) end
  end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:tPause(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = self.taskList[taskey]
    if ts ~= nil then
      ts.paused = true
      tl.str:allUp(taskey)
      tl.polling.pollControls.cutine = 0
    end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do self:tPause(taskey[num]) end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      self:tPause(tl.polling.pollControls.cutine)
    end
  else
    for _, v in pairs(self.taskList) do v.paused = true end
  end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:tRes(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = self.taskList[taskey]
    if ts ~= nil then ts.paused = false end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do self:tRes(taskey[num]) end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      self:tRes(tl.polling.pollControls.cutine)
    end
  else
    for _, v in pairs(self.taskList) do v.paused = false end
  end
end

---Keeps track of what coroutines are currently running
---@param nam string
---@param fam string
---@param num number
---@param inst string
function CoroutineModule:seQueue(nam, fam, num, inst, ...)
  if nam and inst then
    insert(self.taskQueue, {nam, fam, num, inst})
  else
    for i = #self.taskQueue, 1, -1 do local val = self.taskQueue[i]
      if self.taskList[val[1]] == nil then
        local macro = tl.activeProfile.macroIndex[val[i]]
        self:taskRun(val[1], val[2], val[3], macro.execute, macro, val[4], unpack(arg))
        remove(self.taskQueue, i)
      end
    end
  end
end

---Executes a function as a coroutine.
---@param key string
---@param fam string
---@param num number
---@param func function
function CoroutineModule:taskRun(key, fam, num, func, ...)
  self:taskAbort(key)
  local task = {}
  if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~= nil then task.isTemp = 1 end
  task.time = GetRunningTime()
  task.task = create(func)
  task.run = true
  task.paused = false
  task.fam = fam
  task.num = num
  tl.polling.pollControls.cutine = key
  if tl.keyStates.roDown[key] then tl.helperUtils.wipe(tl.keyStates.roDown[key])
  else tl.keyStates.roDown[key] = {} end
  local s, d = resume(task.task, unpack(arg))
  if (s) and ((d or -1) >= 0) then
    task.time = task.time + d
    self.taskList[key] = task
  end
end

---Aborts a task.
---@param key string
function CoroutineModule:taskAbort(key)
  local task = self.taskList[key]
  if task ~= nil then
    tl.logitech:putNoLCD("Stopping Task")
    if task.fam and task.num then tl.activeProfile.deviceState[task.fam]["_b" .. task.num] = nil end
    task.run = false
    if tl.activeProfile.macroIndex[key].state then tl.activeProfile.macroIndex[key].state.seqPosition = nil end
    self.taskList[key] = nil
    for i = #self.taskQueue, 1, -1 do
      if self.taskQueue[i][1] == key then remove(self.taskQueue, i) end
    end
    tl.str:allUp(key)
    tl.polling.pollControls.cutine = 0
  end
end

return CoroutineModule