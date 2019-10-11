local abs,floor,random, Sleep,type, insert, remove, pairs, running, yield, unpack =
math.abs,math.floor,math.random, Sleep,type, table.insert, table.remove,pairs , coroutine.running, coroutine.yield, unpack
---@type MainLibObject
local tl = ...
-->>>>> Functions that control coroutines ================================================================

---Generate random delays for events and keys
---@param num number
---@param dev number
local function _deviate(num,dev)
  if dev and dev ~= 0  then
    local result = num
      if dev < 1 then
        if dev < 0 then dev = abs(dev)end
        dev = floor(num * dev)
      end
      result = result + random((dev*-1),dev)
    return result
  end
  return num
end

---Pause function for all coroutines.
---@param dur number
---@param dev number
function tl.wait(dur,dev)
  local finalDur = _deviate(dur,dev)
  if running() ~= nil then
    yield(finalDur)
    return
  end
  Sleep(finalDur)
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.multiAbort(taskey)
  if taskey and type(taskey) == "string" and taskey ~= "" then
    tl.taskAbort(taskey)
  elseif type(taskey) == "table" then
    for num=1,#taskey do local val = taskey[num]
      tl.taskAbort(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.taskAbort(tl.cutine) end
  else
    for k,_ in pairs(tl.TaskList) do
      tl.taskAbort(k)
    end
  end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.tPause(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.TaskList[taskey]
    if ts ~= nil then
      ts.paused = true
      tl.allUp(taskey)
      tl.cutine = 0
    end
  elseif type(taskey) == "table" then
    for num=1,#taskey do local val = taskey[num]
      tl.tPause(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.tPause(tl.cutine) end
  else
    for _,v in pairs(tl.TaskList) do
      v.paused = true
    end
  end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function tl.tRes(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.TaskList[taskey]
    if ts ~= nil then ts.paused = false end
  elseif type(taskey) == "table" then
    for num=1,#taskey do local val = taskey[num]
      tl.tRes(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.tRes(tl.cutine) end
  else
    for _,v in pairs(tl.TaskList) do
      v.paused = false
    end
  end
end

---Keeps track of what coroutines are currently running
---@param nam string
---@param fam string
---@param num number
---@param inst string
function tl.seQueue(nam,fam,num,inst,...)
  if nam and inst then
    insert(tl.squ,{nam,fam,num,inst})
  else
    for i = #tl.squ, 1, -1 do
      local val = tl.squ[i]
      if tl.TaskList[val[1]] == nil then
        tl.taskRun(val[1],val[2],val[3],tl.quiKey,val[4], unpack(arg))
        remove(tl.squ,i)
      end
    end
  end
end