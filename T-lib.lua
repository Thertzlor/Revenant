tl.modus = 1
tl.shiftor = false
tl.shiftus = false
tl.state = 0
tl.but = 0
tl.dir = 0
tl.mBeforeG = 1
tl.verNum = "1.4"
tl.findEx="Running on internal configs"
tl.press = false
tl.downs = {}
tl.invertG=false
tl.altMode=0
tl.pMod = 0
tl.mods= ""
tl.seqNamed = {}
tl.altMods = 0
tl.finMods = ""
tl.conKey = 0
tl.macPlay = false
tl.toggled = {}
tl.timeTable = {}
tl.stable = {}
tl.unstable = {}
tl.lastMod = 0
tl.stagTimer = {}
tl.cList = {}
tl.assign = {}
tl.roDown={}
tl.squ={}
tl.testres={}
tl.arn = 0
tl.lastKey = {up=0,down=0}
dofile(tl.path .. tl.keyFile)
tl.reMouse = {"m1","m2","m3","m7","m8","m6","m5","m4","g1","g2","g3","g4","g5","g6","g7","g8","g9","g10","g11","g12"}

--->>> Polling related vars nabbed form g-max================================================
tl.PollFamily = "lhc"	-- current mice don't have M-states, so this is a good choice
tl.PollDeadTime = 100	-- settling time (in milliseconds) during which old poll events are drained
tl.PollRateC = 0
tl.PollRateSum = 0
tl.PollLastPoll = 0
tl.PollRate = tl.PollInterval
tl.PollRateCI = 1000/tl.PollRate
tl.OnPoll = false
tl.cutine = 0

--Library Functions from around the net... ===============================================================================
function tl.Reverse(arr)
  local i, j = 1, #arr
  while i < j do
    arr[i], arr[j] = arr[j], arr[i]
    i = i + 1
    j = j - 1
  end
end

function tl.dump(o)
  if type(o) == 'table' then
    local s = ''
    for k in pairs(o) do
      if type(k) ~= 'number' then k = k end
      s = s..k.."  "
    end
    return s .. ''
  else
    return tostring(o)
  end
end

function tl.wipe(tab)
  for k,v in pairs(tab) do
    tab[k] = nil
  end
end

--->>> Output functions nabbed from ll.project (modified) ===============================================================================

function tl.isMouseButton(key)
  local b
  if key and string.sub(key,1,2) == "mb" then
    b = tonumber( string.sub(key,3) )
  end
  return b or false
end

function tl.Press(key, delay)		-- delay is optional for a delay between pressing modifiers before the primary key if there is one.
  -- tl.put("pressing "..key)
  tl.addDown(key)
  local k = tl._KEYBOARD[key]
  delay = delay or 0

  if k then
    if k.key then
      tl.__PressKey(k, delay)
    elseif k[1] then		-- if there is no key, there are tables of keys.
      local i, n
      n = table.maxn(k)
      for i = 1, n do
        tl.__PressKey(k[i], delay)
      end
    elseif k.mb then
      PressMouseButton(k.mb)
    end
  else
    PressKey(key)
  end
end

function tl.Release(key, delay,sil)		-- delay is optional for a delay between pressing modifiers before the primary key if there is one.
  local k = tl._KEYBOARD[key]
  delay = delay or 0
  if k then
    if k.key then
      tl.__ReleaseKey(k, delay)
    elseif k[1] then		-- if there is no key, there are tables of keys.
      local i, n
      n = table.maxn(k)
      for i = 1, n do
        tl.__ReleaseKey(k[i], delay)
      end
    elseif k.mb then
      ReleaseMouseButton(k.mb)
    end
  else
    ReleaseKey(key)
  end
  tl.remDown(key,sil)
end

function tl.PressAndRelease(key, delax)	-- delay is optional delay between all press and releases of keys
  tl.addDown(key)
  local k = tl._KEYBOARD[key]
  local delay = delax or tl.keyDelay
  if k and k[1] then	-- a multiple key press key is found, we must handle key key separate.
    local i, n
    n = table.maxn(k)
    for i=1, n do
      tl.__PressKey(k[i], delay)
      if delay ~=0 then tl.wait(delay) end
      tl.__ReleaseKey(k[i], delay)
      if i < n then
        tl.wait(delay)
      end
    end
  else
    tl.Press(key, delay)
    if delay ~=0 then tl.wait(delay) end
    tl.Release(key, delay)
  end
  tl.remDown(key)
end

function tl.__ReleaseKey(k, delay)
  ReleaseKey(k.key)
  if k.modifier then
    if delay then
      tl.wait(delay)
    end
    if type(k.modifier) == "table" then
      local i,v
      for i, v in ipairs(k.modifier) do
        ReleaseKey(v)
      end
    else
      ReleaseKey(k.modifier)
    end
  end
end

function tl.__PressKey(k, delay)
  if k.modifier then
    if type(k.modifier) == "table" then
      local i,v
      for i, v in ipairs(k.modifier) do
        PressKey(v)
      end
    else
      PressKey(k.modifier)
    end
    if delay then
      tl.wait(delay)
    end
  end
  PressKey(k.key)
end

function tl.TypeString(s, delay,kelay)			-- delay is optional tl.wait time between key presses
  local i, n, c
  local waitTime = delay
  n = # s
  i = 1
  while i <= n do
    c = string.sub(s, i, i)				-- get each character from s
    if c == "/" then					-- / signals special character, which is 2 characters wide
      if i < n then
        c = string.sub(s, i, i+1)
        i = i + 1
      else
        error("tl.TypeString(s, delay) - found a single / at end of string.  For a single /, put two in a row. i.e. //", 2)
      end
    end
    tl.PressAndRelease(c,kelay)
    if delay and i < n then
      --tl.put("waiting for "..waitTime.."ms")
      tl.wait(waitTime)
    end
    i = i + 1
  end
end
--->>> Task and Polling functions nabbed from g-max nabbed from kgober (modified) ===============================================================================
-- Poll Management functions (by kgober)
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
tl.TaskList = {}

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
  local s, d = coroutine.resume(task.task, ...)
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

function OnPollEvent() 				-- played by Library on every Poll event (ONLY FOR EXPERTS!)
end

--->>> code written by myself ===============================================================================

function OnEvent(event, arg, family)
--if event == "MOUSE_BUTTON_PRESSED" and arg == 11 then PressKey("a") elseif arg==11 then ReleaseKey("a") end
tl.EventReceiver(event,arg,family)
tl.DoTasks()
tl.Poll(event, arg, family, st)
if event == "MOUSE_BUTTON_PRESSED" and arg == tl.sKey then
  tl.mBeforeG = tl.modus
elseif arg == tl.sKey and  tl.mBeforeG ~= tl.modus then
  tl.mSync(tl.modus,tl.mBeforeG)
  tl.mBeforeG = tl.modus
end
end

function tl.loadEx()
  local dirSelect = "ext_lua\\"
  if tl.workProfile == true then dirSelect = "ext_work\\" end
  if tl.exFile == true and loadfile(tl.path..dirSelect..tl.pName..".lua") then
    tl.findEx="Running on external configs"
    dofile(tl.path..dirSelect..tl.pName..".lua")
  elseif tl.exFile == true then
    tl.findEx="Running on internal configs, external file missing or broken"
  end
end

function tl.multiAbort(taskey)
  if taskey and type(taskey) == "string" and taskey ~= "" then
    tl.TaskAbort(taskey)
  elseif type(taskey) == "table" then
    for num,val in ipairs(taskey) do
      tl.TaskAbort(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.TaskAbort(tl.cutine) end
  else
    for k,v in pairs(tl.TaskList) do
      tl.TaskAbort(k)
    end
  end
end

function tl.tPause(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.TaskList[taskey]
    if ts ~= nil then
      ts.paused = true
      tl.allUp(taskey)
      tl.cutine = 0
    end
  elseif type(taskey) == "table" then
    for num,val in ipairs(taskey) do
      tl.tPause(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.tPause(tl.cutine) end
  else
    for k,v in pairs(tl.TaskList) do
      v.paused = true
    end
  end
end

function tl.tRes(taskey)
  if type(taskey) == "string" and taskey ~= "" then
    local ts = tl.TaskList[taskey]
    if ts ~= nil then ts.paused = false end
  elseif type(taskey) == "table" then
    for num,val in ipairs(taskey) do
      tl.tRes(val)
    end
  elseif taskey == 0 then
    if tl.cutine ~= 0 then tl.tRes(tl.cutine) end
  else
    for k,v in pairs(tl.TaskList) do
      v.paused = false
    end
  end
end

function tl.seQueue(nam,inst)
  if nam and inst then
    table.insert(tl.squ,{nam,inst})
  else
    for i = #tl.squ, 1, -1 do
      local val = tl.squ[i]
      if tl.TaskList[val[1]] == nil then
        tl.TaskRun(val[1],tl.quiKey,val[2])
        table.remove(tl.squ,i)
      end
    end
  end
end

function tl.executor(convict)
  if type(convict) == "string" then
    _G[convict]()
  elseif type(convict) == "table" then
    local namu = convict[1]
    table.remove(convict,1)
    _G[namu](unpack(convict))
    table.insert(convict,1,namu)
  end
end

function tl.addDown (key)
  --tl.put("adding "..tostring(key))
  if tl.cutine ~=0 then
    table.insert(tl.roDown[tl.cutine],key)
  end
end

function tl.remDown(key,sil)
  if sil then else
  --tl.put("removing "..tostring(key))
end
if tl.cutine ~=0 then
  for i, va in pairs(tl.roDown[tl.cutine]) do
    if va == key then
      tl.roDown[tl.cutine][i]= nil
    end
  end
end
end

function tl.allUp(there)
for i, va in pairs(tl.roDown[there]) do
  if va ~= nil then
    tl.put("auto-released "..va)
    tl.Release(va,0,1)
  end
end
tl.wipe(tl.roDown[there])
end

function tl.namecrawl(tar)
  if tar.name and tar.name ~="" then
    tar.pID = tar.name
    tl.seqNamed[tar.name] = tar
  else
    tar.pID = "c"..tl.arn
    tl.arn = tl.arn+1
  end
  for g,n in pairs(tar) do
    if type(n) == "table" then
      tl.namecrawl(n)
    end
  end
end

function tl.wait(dur,name)
  if coroutine.running() ~= nil then
    coroutine.yield(dur)
    return
  end
  Sleep(dur)
end

function tl.mSync(torg,orig)
  if tl.maxMode > 3 or tl.modeBound == false or tl.maxMode == 1 then return end
  local mod = orig or tl.modus
  local targ = torg or mod+1
  if targ == 0 then targ = mod + 1 end
  if targ > tl.maxMode then targ = 1 end
  if mod == targ then return end
  function pm()
    PlayMacro("Mode Switch (G600)")
    mod = mod+1
  end
  if mod > targ then
    while tl.maxMode >= mod do
      pm()
    end
    if tl.maxMode ==2 then pm() end
    mod = 1
  end
  while targ > mod do
    pm()
  end
end

function tl.molect(targ,nope)
  if type(targ) ~= "number" then tl.checkM() return
elseif tl.maxMode == 1 or tl.modus == targ then return end
  if tl.shiftor == false then  tl.mSync(targ) end
  local midas = tl.modus
  function sMode()
    if tl.modus < tl.maxMode then
      tl.modus = tl.modus +1
    else
      tl.modus = 1
    end
  end
  if targ == nil or targ == 0 then
    sMode()
  elseif targ <= tl.maxMode then
    while targ ~= tl.modus do
      sMode()
    end
  else
    tl.molect(tl.maxMode)
  end
  if tl.autoHot == true and tl.workProfile == false then
    PressAndReleaseKey("f15")
  end
  tl.put("changed to mode "..tl.modus)
end

function tl.launch()
  local defnum = 0
  local nanum = 0
  local gennum = tl.arn-1

  for k,v in pairs(tl.assign) do if k ~= "pID" then defnum = defnum+1 end end
  for k,v in pairs(tl.seqNamed) do nanum = nanum+1 end

  tl.put("\n\nG600 Profile '"..tl.pName.."' powered by T-lib v"..tl.verNum.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n")
  if tl.autoHot == true and tl.workProfile == false then
    PlayMacro("~actiScript")
    tl.wait(250)
    PressAndReleaseKey("f13")
    for i = tl.maxMode, 1, -1 do
      PressAndReleaseKey("f14")
    end

    for i = tl.nameIndex, 1, -1 do
      PressAndReleaseKey("f17")
    end
  end
end

function tl.shutDown()
  tl.put("Profile '"..tl.pName.."' deactivated.")
  tl.multiAbort("")
  tl.molect(1,true)
end

function tl.defTab(num)
  if num ~= tl.sKey then
    if tl.press == true then
      cody = num
      if tl.shiftor == true then
        cody = cody.."t"
      else
        cody = cody.."f"
      end

      cody = cody..tl.modus
      cody = cody..tl.mods

      curNum = {}
      curSt = string.match(cody, "%a")
      curMo = string.match(cody,"%a+$")

      for i in string.gmatch(cody, "%d+") do
        table.insert(curNum,i)
      end

      if tl.dir == "up" then
        for i, obj in ipairs(tl.downs) do
          local tempNum = {}
          local tempSt =  string.match(obj, "%a")
          local tempMo = string.match(obj, "%a+$")

          for d in string.gmatch(obj, "%d+") do
            table.insert(tempNum,d)
          end
          if tempNum[1] == curNum[1]  then
            if tempSt ~= curSt then
              tl.invertG=true
            else
              tl.invertG = false
            end
            if tempNum[2] ~= curNum[2] then
              tl.altMode = tempNum[2]
            else
              tl.altMode = 0
            end
            if curMo ~= tempMo then
              --	OutputLogMessage("difference detected between current %s and previous %s\n", tostring(curMo), tostring(tempMo) )
              tl.altMods = tempMo
            else
              tl.altMods = 0
            end
            table.remove(tl.downs,i)
          end
        end
      else
        table.insert(tl.downs,cody)
      end
    end
  end
end

function tl.setArgsB(ev,ar)
  tl.invertG = false
  tl.altMode = 0
  tl.mods = ""
  tl.finMods=""
  tl.altMods=0
  tl.conKey = 0
  local morail = {
    {"ralt","ra"},
    {"lalt","la"},
    {"alt","ga"},
    {"rshift","rs"},
    {"lshift","ls"},
    {"shift","gs"},
    {"rctrl","rc"},
    {"lctrl","lc"},
    {"ctrl","gc"}
  }

  for i,obj in ipairs(morail) do
    if IsModifierPressed(obj[1]) then
      tl.mods = tl.mods..obj[2]
    end
  end

  if ev == "MOUSE_BUTTON_PRESSED" then
    tl.dir = "down"
    tl.press = true
  elseif ev == "MOUSE_BUTTON_RELEASED" then
    tl.dir = "up"
  end

  if ar == tl.sKey then
    tl.but = 0
    if tl.dir == "down" then
      tl.shiftor=true
    elseif tl.dir == "up" then
      tl.shiftor=false
    end
  else
    tl.but = ar
  end

  tl.defTab(ar)

  if tl.invertG == true then
    tl.shiftus = not tl.shiftor
  else
    tl.shiftus = tl.shiftor
  end

  if tl.altMode ~= 0 then
    tl.pMod = tl.altMode
  else
    tl.pMod = tl.modus
  end

  if tl.altMods ~= 0 then
    tl.finMods = tl.altMods
  else
    tl.finMods = tl.mods
  end

  if tl.finMods == nil or #tl.finMods == 0 then
    mads=""
  else
    mads = " , modifiers pressed: "..tl.finMods
  end

  if table.getn(tl.downs) == 0 then
    tabs = ""
  else
    tabs = " , Keys Down = "..table.concat(tl.downs,",")
  end

  if #tl.dump(tl.cList) == 0 then
    tabs2 = ""
  else
    tabs2 = " , keys locked: "..tl.dump(tl.cList)
  end
  local logKey = ""
  if tl.logicalMouse == true then
    logKey = " ("..tl.reMouse[ar]..")"
  end
  lKey = " , Last Keys: "..tl.lastKey.down.."(down), "..tl.lastKey.up.."(up)"

  OutputLogMessage("Key-Event = %s , Current Key = %s"..logKey..", G-Shift = %s , Mode = %s%s%s%s%s\n", tl.dir, ar, tostring(tl.shiftus), tl.pMod, tabs, mads, tabs2, lKey)
end

function tl.setArgsE(ev,ar)

  if tl.invertG == true then
    tl.shiftus = tl.shiftor
  end
  tl.conKey = 0
  tl.finMods = tl.mods

  if tl.dir == "up"then

    for k in pairs(tl.cList) do
      if type(k) == 'string' then
        if string.match(k,"_"..tl.but.."t%-?%g*") then
          -- 	OutputLogMessage("heyo\n")
          tl.cList[k]=nil
        end
      end
    end
  end
end

function tl.staggerRoutine(bifu,buta)
  local rupture = false
  local conta = bifu[1]
  local tita = bifu[2]
  local save
  local rem = false
  local stm= bifu.stagger or "absolute"

  local relTime_r = GetRunningTime()
  local preTime_r = tl.timeTable["_"..buta]

  if  (type(tita) == "table" and #conta-1 > #tita) or (type(tita) == "number" and stm=="init") then
    rem = true
    save = conta[1]
    table.remove(conta,1)
  end

  if type(tita) == "table" then
    local finalTime = tita[#tita]

    if stm == "relative" then
      local i = #tita - 1
      while i > 0 do
        finalTime = finalTime+tita[i]
        i = i -1
      end
    end

    while (relTime_r-preTime_r) < finalTime do
      tl.wait(tl.PollInterval)
      if tl.stagTimer["_"..bifu.pID] == false then
        if rem == true then table.insert(conta,1,save) end
        return end
        relTime_r = GetRunningTime()
      end

    elseif type(tita) =="number" then
      while math.floor((relTime_r-preTime_r)/(tita * #conta)) == 0 do
        tl.wait(tl.PollInterval)
        if tl.stagTimer["_"..bifu.pID] == false then
          if rem == true then table.insert(conta,1,save) end
          return end
          relTime_r = GetRunningTime()
        end
      end
      tl.stagTimer["_"..bifu.pID] = false
      tl.quiKey(conta[#conta])
      if rem == true then table.insert(conta,1,save)
    end
  end

  function tl.staggerKey(bifu)
    if  #bifu ~=2 or type(bifu[1]) ~= "table" then
      tl.put("Invalid Stagger Sequence")
      return
    end

    local conta = bifu[1]
    local tita = bifu[2]
    local savedVal
    local rem = false
    local stm= bifu.stagger or "absolute"
    if tl.stagTimer["_"..bifu.pID] ~= true then
      if tl.dir == "up" then
        return false end
        tl.stagTimer["_"..bifu.pID] = false
      end

      local mode = bifu.play or "normal"

      if tl.dir=="down" then
        tl.stagTimer["_"..bifu.pID] =true
        tl.timeTable["_"..tl.but] = GetRunningTime()

        if (type(tita) == "table" and #conta-1 > #tita) or (type(tita) == "number" and stm=="init") then
          tl.quiKey(conta[1],conta[1].pID)
        end
        if mode ~= "hold" then
          tl.TaskRun(bifu.pID,tl.staggerRoutine,bifu,tl.but)
        end
      elseif tl.stagTimer["_"..bifu.pID] == true then
        tl.stagTimer["_"..bifu.pID] = false
        local played = false
        local relTime = GetRunningTime()
        local preTime = tl.timeTable["_"..tl.but]

        if  mode == "hold" and ((type(tita) == "table" and #conta-1 > #tita) or (type(tita) == "number" and stm=="init")) then
          rem = true
          savedVal = conta[1]
          table.remove(conta,1)
        end
        if type(tita) == "table" then
          for i, obj in ipairs(tita) do
            if stm == "relative" then
              if i ~= 1 then
                tita[i] = tita[i]+tita[i-1]
              end
            end

            if (relTime-preTime) < tita[i] then
              tl.quiKey(conta[i],conta[i].pID)
              played=true
              break
            end
          end

        elseif type(tita) =="number" then
          played=true
          playa = math.ceil((relTime-preTime)/tita)
          if playa > #conta then
            playa = #conta
          end
          tl.quiKey(conta[playa],conta[playa].pID)
        end

        if played == false then
          tl.quiKey(conta[#conta],conta[#conta].pID)
        end
        if  rem == true then
          table.insert(conta,1,savedVal)
        end
    end
end

function tl.normKey(tg)
  if tl.dir == "down" then
    if type(tg) == "string" then
      tl.Press(tg)
    elseif type(tg) == "table" then
      tl.preRay(tg)
    end
  elseif tl.dir =="up" then
    if type(tg) == "string" then
      tl.Release(tg)
    elseif type(tg) == "table" then
      tl.relRay(tg)
    end
  end
end

function tl.normKeyT(tg)
  local isDown = false
  for k,v in ipairs(tl.toggled) do
    if v == tg then
      isDown = true
      table.remove(tl.toggled,k)
    end
  end

  if isDown == false then
    table.insert(tl.toggled,1,tg)
    if type(tg) == "string" then
      tl.Press(tg)
    elseif type(tg) == "table" then
      tl.preRay(tg)
    end
  else
    if type(tg) == "string" then
      tl.Release(tg)
    elseif type(tg) == "table" then
      tl.relRay(tg)
    end
  end
end

function tl.cycleReset(buts)
  if buts and type(buts) == "table" then
    for k,v in ipairs(buts) do tl.cycleReset(v) end
    return
  end
  if buts and type(buts) == "string" and buts ~= "" then
    tl.stable["_"..buts] = nil
    tl.unstable["_"..buts] = nil
  elseif buts == nil or buts == 0 then
    tl.wipe(tl.stable)
    tl.wipe(tl.unstable)
  end
end

function tl.lcancel(buts)
  if buts and type(buts) == "table" then
    for k,v in ipairs(buts) do tl.lcancel(v) end
    return
  end
  if buts and type(buts) == "string" and buts ~= "" then
    tl.stagTimer["_"..buts] = nil
  elseif buts == nil or buts == 0 then
    tl.wipe(tl.stagTimer)
  end
end

function tl.cycleBut(tar,cycleMod,temp)
  local numlog = tl.stable
  if temp == 1 then numlog = tl.unstable end
  local nofl=false
  if type(tar) ~= "table" or #tar ==1 then
    return
  else
    if numlog["_"..tar.pID] == nil then
      numlog["_"..tar.pID] = 1
      nofl=true
    end

    if (tl.dir == "down" and (cycleMod == 0 or cycleMod == 3)) or (tl.dir == "up" and (cycleMod == 1 or cycleMod ==4) or (cycleMod == 2 and tl.dir== "down")) then
      if (numlog["_"..tar.pID]+1) > #tar then
        numlog["_"..tar.pID] = 1
        nofl=true
      end

      if nofl==false and (cycleMod ~= 2 or (cycleMod == 2 and tl.dir == "down")) then
        numlog["_"..tar.pID] = numlog["_"..tar.pID] + 1
      end
    end

    if (tl.dir == "down" and (cycleMod == 0 or cycleMod == 3)) or (tl.dir == "up" and (cycleMod == 1 or cycleMod ==4)) or cycleMod >= 2 then

      if cycleMod == 2 then
        tl.staggerKey(tar[numlog["_"..tar.pID]])
      elseif cycleMod == 0 or cycleMod == 1 or cycleMod == 4 then
        tl.quiKey(tar[numlog["_"..tar.pID]],tar[numlog["_"..tar.pID]].pID)
      elseif cycleMod == 3 then
        tl.normKey(tar[numlog["_"..tar.pID]])
      end
    end
  end
end

function tl.preRay(rayz)
  for i, obj in ipairs(rayz) do
    if type(obj) == "string" then
      tl.Press(obj)
    end
  end
end

function tl.relRay(rayz)
  tl.Reverse(rayz)
  for i, obj in ipairs(rayz) do
    if type(obj) == "string" then
      tl.Release(obj)
    end
  end
  tl.Reverse(rayz)
end

function tl.togMode(md)
  if tl.dir == "down" then
    tl.lastMod = tl.modus
    tl.molect(md)
  else
    tl.molect(tl.lastMod)
    tl.lastMod=0
  end
end

function tl.checkM()
  if tl.autoHot == true and tl.workProfile == false then
    PressAndReleaseKey("f16")
  end
end

function tl.bothRay(blu,del)
  tl.preRay(blu)
  if del then tl.wait(del) end
  tl.relRay(blu)
end

function tl.put(input)
  if type(input) ~= "string" then input=tostring(input)end
  OutputLogMessage(input.."\n")
end

function tl.typer(tstring,del,kdel)
  wt = del or tl.actionDelay
  kwt = kdel or tl.keyDelay
  if (#tstring == 1 or (string.sub(tstring,0,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(string.sub(tstring,2,3)) < 25)))) then
    tl.PressAndRelease(tstring,kwt)
  else
    tl.TypeString(tstring,wt,kwt)
  end
end

function tl.quiKey(tg,name,dir,descPlay)
  local descDir = descPlay or "normal"
  local mode = tg.play or "normal"
  local delayer = tg.delay or tl.actionDelay
  local dekayer = tg.kdelay or tl.keyDelay
  local ride = tg.stack or tl.defStack

  if dir then
    if ((mode == "normal" or mode == "toggle" or mode=="ptoggle") and ((dir == "up" and descDir == "normal") or (dir=="down" and descDir == "up" ))) then
      return
    elseif (mode == "hold" and dir == "up") then
      tl.TaskAbort(name)
      return
    elseif (mode == "phold" and dir == "up") then
      tl.tPause(name)
      return
    end
  end

  if (mode == "ptoggle" and descDir == "normal" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==false and (dir == nil or dir == "down")) or (mode == "ptoggle" and descDir == "up" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==false and dir == "up") then
    tl.tPause(name)
    return
  end

  if (mode == "toggle" and descDir == "normal" and tl.TaskRunning(name) == true and (dir == nil or dir == "down")) or (mode == "toggle" and descDir == "up" and tl.TaskRunning(name) == true and dir == "up") then
    tl.TaskAbort(name)
    return
  end

  if name then
    if tl.TaskList[name] == nil then
      tl.TaskRun(name,tl.quiKey,tg)
    else
      if tl.TaskList[name].paused == true then
        tl.TaskList[name].paused = false
      elseif ride == 0 then
        tl.TaskRun(name,tl.quiKey,tg)
      elseif ride == 2 then
        tl.seQueue(name,tg)
      end
    end
    return
  end

  function processTable()
    local noWait = false

    for i, obj in ipairs(tg) do
      if i ~= 1 and noWait == false and type(obj) ~= "number" then
        tl.wait(delayer)
      elseif noWait == true  then
        noWait = false
      end

      if type(obj) == "string" then
        tl.typer(obj,delayer,dekayer)
      elseif type(obj) == "table" then
        if (#obj > 3) or (#obj == 2 and type(obj[1]) == "string" and type(obj[2]) == "string") then
          tl.bothRay(obj,delayer)
        elseif #obj == 2 and type(obj[2]) == "number" and type(obj[1]) == "string"
          or
          ((obj[2] == 5 or obj[2] == 8 or obj[2] == 9) and type(obj[1]) == "number")
          or
          ((obj[2] == 6 or obj[2] == 7) and type(obj[1]) == "table")
          or
          obj[2] > 9
          then
            if obj[2] == 0 then
              tl.Press(obj[1])
            elseif obj[2] == 1 then
              tl.Release(obj[1])
            elseif obj[2] == 2 then
              tl.PlayMac(obj[1])
            elseif obj[2] == 3 then
              AbortMacro()
              tl.macPlay = false
            elseif obj[2] == 4 then
              tl.PlayMac(obj[1],false,2)
            elseif obj[2] == 5 then
              tl.molect(obj[1])
            elseif obj[2] == 6 then
              if type(obj[1]) == "string" then
                tl.quiKey(tl.seqNamed[obj[1]])
              else
                tl.quiKey(obj[1])
              end
            elseif obj[2] == 7 then
              tl.executor(obj[1])
            elseif obj[2] == 8 then
              if type(obj[1]) == "number" then
                delayer = obj[1]
              elseif obj[1] == "default" then
                delayer = tg.delay or tl.actionDelay
              end
            elseif obj[2] == 9 then
              if type(obj[1]) == "number" then
                dekayer = obj[1]
              elseif obj[1] == "default" then
                dekayer = tg.kdelay or tl.keyDelay
              end
            elseif obj[2] == 10 then
              tl.multiAbort(obj[1])
            elseif obj[2] == 11 then
              tl.tPause(obj[1])
            elseif obj[2] == 12 then
              tl.tRes(obj[1])
            elseif obj[2] == 13 then
              tl.cycleReset(obj[1])
            elseif obj[2] == 14 then
              tl.lcancel(obj[1])
            end
          end

        elseif type(obj) == "number" then
          noWait = true
          tl.wait(obj)
        end
      end
    end

    if type(tg) == "string" then
      tl.typer(tg,delayer,dekayer)
    elseif type(tg) == "table" then
      processTable()
      local looper = tg.loop or 0

      while looper ~= 0 do
        processTable()
        looper = looper-1
      end
    end
    return -1
  end

  function tl.PlayMac(nam,c)
    if c == 2 or c == 3 then
      AbortMacro()
      tl.macPlay = false
    end
    PlayMacro(nam)
  end

  function tl.TogMac(nam,c)
    if tl.macPlay == false then
      if c == 2 or c==3 then
        AbortMacro()
        tl.macPlay = false
      end
      PlayMacro(nam)
      tl.macPlay = true
    else
      AbortMacro()
      tl.macPlay = false
    end
  end

function tl.key(mouse,cmd,def,shifted,modi,mkeys,mouseLock,keyLock,cons,tes,pDir,ident)
  --tl.put(tl.dump(cmd))
  function tNum(n,rev)
    local putout = rev or false

    local downT = table.concat(tl.downs,",")

    if (string.match(downT,"^"..n.."%a%d%a*") ~= nil) or (string.match(downT,","..n.."%a%d%a*") ~= nil) then
      return not putout
    else
      return putout
    end
  end

  function tup(domo)
    local selec = 2
    if domo then selec = 1 end
    local reray = {{"normal","down"},{"up","up"}}
    --tl.put(tl.dir.." "..pDir.." "..tostring(tl.dir == "up" and pDir == "up"))
    return tl.dir == reray[selec][2] and pDir == reray[selec][1]
  end

  function tessa(ind)
    local tes = ind or tes
    if tes == nil or tes == true then
      return true
    end

    local res = true
    local tas = tes

    if type(tes) == "number" then

      if 0 > tes then
        res = false
        tas = math.abs(tes)
      end

      if tl.dir == "down" and tNum(tas) == true then
        return res
      elseif tl.dir == "down" and tNum(tas) == false then
        tl.cList["_"..mouse.."t"..tes] = 1
        return not res
      end

      if pDir ~= "up" then
        if tl.cList["_"..mouse.."t"..tes] == nil then
          return res
        else
          return not res
        end
      else
        return tNum(tas,res)
      end
    elseif type(tes) == "string" and tonumber(tes) then
      tas = tonumber(tes)
      local tus = tonumber(tes)
      if 0 > tus then
        tas = math.abs(tas)

        if tl.lastKey.down ~= tas or (tl.dir == "up" and tl.lastKey.down ~= mouse and tl.lastKey.up ~= mouse) then
          return res
        else
          return not res
        end

      else

        if tl.lastKey.down == tas or (tl.dir == "up" and tl.lastKey.down == mouse and tl.lastKey.up ~= mouse) then
          return res
        else
          return not res
        end

      end

    elseif type(tes) == "table" then
      local m = tes.m or "or"
      if tl.dir =="down" or (tl.dir == "up" and tup()) then
        if tl.dir == "down" then
          tl.cList["_"..mouse.."t"..table.concat(tes,"")] = 1
        end

        for i, obj in ipairs(tes) do
          if m == "or" and tessa(obj) == true then return true end

          if m == "and" and tessa(obj) == false then return false
        elseif m == "and" and i == #tes then return true end

        end
        return false

      elseif tl.dir == "up" then
        if tl.cList["_"..mouse.."t"..table.concat(tes,"")] == nil then
          return res
        else
          return not res
        end
      end
    else
      return res
    end
  end

  local okayG = false
  local okayM = false
  local okayK = false
  local lShift = tl.shiftus
  local lMod = tl.pMod
  local lModif = tl.finMods

  if  type(mouseLock) == "boolean" and mouseLock == true then
    lShift = tl.shiftor
    lMod = tl.modus
  end

  if type(keyLock) == "boolean" and keyLock == true then
    lModif = tl.mods
  end

  if tl.but == mouse and tl.conKey ~= mouse then

    if (mkeys == "no" and (lModif == nil or lModif== 0 or #lModif ==0)) or (mkeys ~="no" and (mkeys==nil or mkeys==0 or mkeys=="" or lModif == mkeys)) then
      okayK = true
    elseif type(lModif) == "string" and type(mkeys) == "string" then
      local comTab = {}
      local recTab = {}

      for i in string.gmatch(mkeys, "%a%a") do
        table.insert(comTab,i)
      end

      for i in string.gmatch(lModif, "%a%a") do
        table.insert(recTab,i)
      end

      typeComb = false

      for i, obj in ipairs(recTab) do
        typeComb = false

        for d, abj in ipairs(comTab) do
          if string.match(obj,"%a$") == string.match(abj,"%a$") then
            typeComb = true
          end
          if typeComb == false then
            break
          end
        end
      end

      keyComb = false

      for i, obj in ipairs(comTab) do
        keyComb = false

        for d, abj in ipairs(recTab) do

          if abj == obj or (string.match(obj,"%a") == "g" and string.match(obj,"%a$") == string.match(abj,"%a$")) then
            keyComb = true
          end
          if keyComb == false then
            break
          end
        end
      end
      if keyComb == true and typeComb == true then
        okayK = true
      end
    end

    if type(shifted) == "number" then

      if shifted == 2 or (shifted == 1 and lShift == true) or (shifted == 0 and lShift  == false) then
        okayG = true
      end
    else
      okayG = true
    end

    if type(modi) == "number" then
      if modi == 0 or modi == tonumber(lMod) then
        okayM = true
      end

    elseif type(modi) == "table" then
      for i, obj in ipairs(modi) do
        if obj == lMod then
          okayM = true
          break
        end
      end
    else
      okayM = true
    end

    local teres = tessa()
    ---[[
    if ident ~=nil then
      if tl.dir == "down" then
        tl.testres[ident] = tessa()
      elseif tup() then
        tl.testres[ident] = nil
      else
        if tl.testres[ident] ~= nil then
          teres = tl.testres[ident]
        end
        tl.testres[ident] = nil
      end
    end
    --]]

    if okayG == true and okayM == true and okayK == true and ((pDir=="normal" or tup()) and teres) == true then
      if tl.lastKey.down ~= mouse then tl.wipe(tl.unstable) end
      tl.lastKey[tl.dir] = mouse
      if cons == 1  or cons==3 then
        tl.conKey = mouse
      end
      if def == "n" or def == nil then
        tl.normKey(cmd)
      elseif def == "nt" and tl.dir == "down" then
        tl.normKeyT(cmd)
      elseif def == "nc" and pDir == "normal" then
        tl.cycleBut(cmd,3,0)
      elseif def == "nc" and tup() then
        tl.cycleBut(cmd,4,0)
      elseif def == "s" then
        tl.quiKey(cmd,cmd.pID,tl.dir,pDir)
      elseif def == "sc" and pDir == "normal" then
        tl.cycleBut(cmd,0,0)
      elseif def == "sc" and tup() then
        tl.cycleBut(cmd,1,0)
      elseif def == "sscs" then
        tl.cycleBut(cmd,2,0)
      elseif def == "nct"  and pDir == "normal" then
        tl.cycleBut(cmd,3,1)
      elseif def == "nct" and tup() then
        tl.cycleBut(cmd,4,1)
      elseif def == "sct"  and pDir == "normal" then
        tl.cycleBut(cmd,0,1)
      elseif def == "sct" and tup() then
        tl.cycleBut(cmd,1,1)
      elseif def == "sscst" then
        tl.cycleBut(cmd,2,1)
      elseif def == "ss"  then
        tl.staggerKey(cmd)
      elseif def == "ssc" and tl.dir == "down" then
        tl.lcancel(cmd)
      elseif def == "m" and (tup() or tup(1)) then
        tl.PlayMac(cmd,cons)
      elseif def == "mh" then
        tl.TogMac(cmd,cons)
      elseif def == "mt" and tl.dir == "down" then
        tl.TogMac(cmd,cons)
      elseif def == "c" and (tup() or tup(1)) then
        tl.molect(cmd)
      elseif def == "ct"  and type(cmd) == "number" then
        tl.togMode(cmd)
      elseif def == "ab"   and (tup() or tup(1))  then
        tl.multiAbort(cmd)
      elseif def == "fn"  and (tup() or tup(1))  then
        tl.executor(cmd)
      elseif def == "rc"   and (tup() or tup(1))  then
        tl.cycleReset(cmd)
      elseif def == "ps"   and (tup() or tup(1)) then
        tl.tPause(cmd)
      elseif def == "rs"   and (tup() or tup(1)) then
        tl.tRes(cmd)
      end
    end
  end
end

function tl.multiTab(acc)
  if type(acc) == "table" then
    for k, v in pairs(acc) do
      if type(k) ~= "number" and k ~= "pID" then
        return false
      end
    end
    return true
  end
  return false
end

function tl.keyGen(keyn,lock,keyCode)
  local pKey = tl.assign[keyCode]
  local cmd = lock
  --if #cmd == 1 and type(cmd[1]) == "string" then cmd = cmd[1] end

  --if lock.type or lock.t then cmd = cmd[1] end
  tl.key(
  keyn,
  cmd,
  lock.type or lock.t or "n",
  lock.gshift or lock.g or pKey.gshift or tl.defG,
  lock.mode or lock.m or pKey.mode or tl.defMode,
  lock.mkey or lock.mk or pKey.mkey,
  lock.mouseLock or pKey.mouseLock,
  lock.keyLock or pKey.keyLock,
  lock.consume or pKey.consume,
  lock.test or pKey.test,
  lock.direction or lock.d or pKey.direction or "normal",
  lock.pID or pKey.pID)
end

function tl.overrideProps(source,code)
  if type(source) ~= "table" then return end

  local tKey = tl.assign[code]
  for k , v in pairs(source) do
    tKey[k] = v
  end
end

function tl.newSet(k)
  local pChange = false
  local bCode
  if tl.logicalMouse == true then
    bCode = tl.reMouse[k]
  else
    bCode = "m"..k
  end

  local args = tl.assign[bCode]

  if type(k) ~= "number" or k == 0 or k > 20 then
    error(" invalid mouse button")
  elseif args == nil then
    return
  elseif type(args) == "string" then
    tl.keyGen(k,args,bCode)
  elseif type(args) == "table" then
    if tl.multiTab(args) == true then
      for num, coms in ipairs(args) do
        if #coms == 0 then
          pChange = true
          tl.overrideProps(coms,bCode)
        else
          tl.keyGen(k,coms,bCode)
        end
      end
    else
      tl.keyGen(k,args,bCode)
    end
    if pChange == true then
      for k,v in pairs(args) do
        if type(k) ~= "number" then args[k]=nil end
      end
    end
  end
end

function tl.EventReceiver(event,arg,family)
  if family == "" then family = "audio" end
  if string.sub(event,1,7) == "PROFILE" then family = "profile" end
  if event == "PROFILE_ACTIVATED" then
    tl.wipe(tl.assign)
    tl.OnPollEventIni()
    tl.InitPolling()
    tl.setKeys()
    tl.namecrawl(tl.assign)
    tl.launch()
  elseif event == "PROFILE_DEACTIVATED" then
    tl.shutDown()
  elseif family ~= tl.PollFamily then
    tl.setArgsB(event,arg)
    tl.newSet(arg)
    tl.setArgsE(event,arg)
  end
end