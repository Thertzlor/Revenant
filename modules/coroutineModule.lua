---@type MainLibObject
local tl = ...
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack =
  math.abs,math.floor,math.random,Sleep,type,table.insert,table.remove,pairs,coroutine.running,coroutine.yield,unpack
--================================================================
---@type CoroutineModule
---: Functions that control coroutines 
tl.coroutines = {
  taskQueue = {},
  taskList = {}
}

---Generate random delays for events and keys
---@param num number
---@param dev number
local function _deviate(num, dev)
  if dev == 0 or not dev then
    return num
  end
  local result = num
  if dev < 1 then
    if dev < 0 then
      dev = abs(dev)
    end
    dev = floor(num * dev)
  end
  result = result + random((dev * -1), dev)
  return result
end

---Pause function for all coroutines.
---@param dur number
---@param dev number
function tl.coroutines.wait(dur, dev)
  local finalDur = _deviate(dur, dev)
  return (running() and yield(finalDur)) or Sleep(finalDur)
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.coroutines.multiAbort(taskey)
  if taskey and type(taskey) == "string" and taskey ~= "" then
    tl.polling.taskAbort(taskey)
  elseif type(taskey) == "table" then
    for num = 1, #taskey do
      tl.polling.taskAbort(taskey[num])
    end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      tl.polling.taskAbort(tl.polling.pollControls.cutine)
    end
  else
    for k, _ in pairs(tl.coroutines.taskList) do
      tl.polling.taskAbort(k)
    end
  end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.coroutines.tPause(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.coroutines.taskList[taskey]
    if ts ~= nil then
      ts.paused = true
      tl.str.allUp(taskey)
      tl.polling.pollControls.cutine = 0
    end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do
      tl.coroutines.tPause(taskey[num])
    end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      tl.coroutines.tPause(tl.polling.pollControls.cutine)
    end
  else
    for _, v in pairs(tl.coroutines.taskList) do
      v.paused = true
    end
  end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.coroutines.tRes(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.coroutines.taskList[taskey]
    if ts ~= nil then
      ts.paused = false
    end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do
      tl.coroutines.tRes(taskey[num])
    end
  elseif taskey == 0 then
    if tl.polling.pollControls.cutine ~= 0 then
      tl.coroutines.tRes(tl.polling.pollControls.cutine)
    end
  else
    for _, v in pairs(tl.coroutines.taskList) do
      v.paused = false
    end
  end
end

---Keeps track of what coroutines are currently running
---@param nam string
---@param fam string
---@param num number
---@param inst string
function tl.coroutines.seQueue(nam, fam, num, inst, ...)
  if nam and inst then
    insert(tl.coroutines.taskQueue, {nam, fam, num, inst})
  else
    for i = #tl.coroutines.taskQueue, 1, -1 do
      local val = tl.coroutines.taskQueue[i]
      if tl.coroutines.taskList[val[1]] == nil then
        tl.polling.taskRun(val[1], val[2], val[3], tl.macros.keySequence, val[4], unpack(arg))
        remove(tl.coroutines.taskQueue, i)
      end
    end
  end
end
