local tl = ...

---->>> Functions that control coroutines ================================================================

function tl.deviate(num,dev)
  if dev and dev ~= 0  then
    local result = num
      if dev < 1 then
        if dev < 0 then dev = math.abs(dev)end
        dev = math.floor(dur * dev)
      end
      result = result + math.random((dev*-1),dev)
      tl.put(result)
    return result
  end
  return num
end

function tl.wait(dur,dev) --Pause function for all coroutines.
  local finalDur = tl.deviate(dur,dev)
  if coroutine.running() ~= nil then
      coroutine.yield(finalDur)
      return
    end
    Sleep(finalDur)
  end
  
  function tl.multiAbort(taskey) --Terminates one or multiple tasks/coroutines (recursively)
    if taskey and type(taskey) == "string" and taskey ~= "" then
      tl.TaskAbort(taskey)
    elseif type(taskey) == "table" then
      for num=1,#taskey do local val = taskey[num]
        tl.TaskAbort(val)
      end
    elseif taskey == 0 then
      if tl.cutine ~= 0 then tl.TaskAbort(tl.cutine) end
    else
      for k,_ in pairs(tl.TaskList) do
        tl.TaskAbort(k)
      end
    end
  end
  
  function tl.tPause(taskey) --Pauses one or multiple tasks/coroutines (recursively)
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
  
  function tl.tRes(taskey) --Resumes one or multiple tasks/coroutines (recursively)
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
  
  function tl.seQueue(nam,inst,...) --Keeps track of what coroutines are currently running
    if nam and inst then
      table.insert(tl.squ,{nam,inst})
    else
      for i = #tl.squ, 1, -1 do
        local val = tl.squ[i]
        if tl.TaskList[val[1]] == nil then
          tl.TaskRun(val[1],tl.quiKey,val[2], unpack(arg))
          table.remove(tl.squ,i)
        end
      end
    end
  end