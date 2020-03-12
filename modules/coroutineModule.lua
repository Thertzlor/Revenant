---@type MainLibObject
local tl = ...
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack =
  math.abs,math.floor,math.random,Sleep,type,table.insert,table.remove,pairs,coroutine.running,coroutine.yield,unpack
-->>>>> Functions that control coroutines ================================================================

tl.coroutines = {}

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
    if tl.pollControls.cutine ~= 0 then
      tl.polling.taskAbort(tl.pollControls.cutine)
    end
  else
    for k, _ in pairs(tl.taskList) do
      tl.polling.taskAbort(k)
    end
  end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.coroutines.tPause(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.taskList[taskey]
    if ts ~= nil then
      ts.paused = true
      tl.str.allUp(taskey)
      tl.pollControls.cutine = 0
    end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do
      tl.coroutines.tPause(taskey[num])
    end
  elseif taskey == 0 then
    if tl.pollControls.cutine ~= 0 then
      tl.coroutines.tPause(tl.pollControls.cutine)
    end
  else
    for _, v in pairs(tl.taskList) do
      v.paused = true
    end
  end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.coroutines.tRes(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.taskList[taskey]
    if ts ~= nil then
      ts.paused = false
    end
  elseif type(taskey) == "table" then
    for num = 1, #taskey do
      tl.coroutines.tRes(taskey[num])
    end
  elseif taskey == 0 then
    if tl.pollControls.cutine ~= 0 then
      tl.coroutines.tRes(tl.pollControls.cutine)
    end
  else
    for _, v in pairs(tl.taskList) do
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
    insert(tl.squ, {nam, fam, num, inst})
  else
    for i = #tl.squ, 1, -1 do
      local val = tl.squ[i]
      if tl.taskList[val[1]] == nil then
        tl.polling.taskRun(val[1], val[2], val[3], tl.macros.keySequence, val[4], unpack(arg))
        remove(tl.squ, i)
      end
    end
  end
end
