tl.modus = 1
tl.shiftor = false
tl.shiftus = false
tl.state = 0
tl.but = 0
tl.dir = 0
tl.mBeforeG = 1
tl.verNum = "1.5"
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
tl.lastModN = 0
tl.lastModC = 0
tl.unstable = {}
tl.lastMod = 0
tl.stagTimer = {}
tl.cList = {}
tl.assign = {}
tl.roDown={}
tl.squ={}
tl.testres={}
tl.keyCount = 0
tl.arn = 0
tl.lastKey = {up=0,down=0}
dofile(tl.path .. tl.keyFile)
tl.reMouse = {"m1","m2","m3","m7","m8","m6","m5","m4","g1","g2","g3","g4","g5","g6","g7","g8","g9","g10","g11","g12"}
tl.cycleCombi = {"/c","/s","/a","/24"}
if tl.PollInterval == 0 then tl.PollInterval = 1 end --Prevent low poll rate from Crashing the program.

tl.defaultFuncs={
  n     = function(f) tl.normKey(f) end,
  s     = function(f,g,h,b,v) tl.quiKey(f,f.pID,g,h,b,v) end,
  ss    = function(f) tl.staggerKey(f) end,
  mh    = function(f) tl.TogMac(f) end,
  mt    = function(f) tl.TogMac(f,tl.dir) end,
  ct    = function(f) tl.TogMode(f) end,
  cn    = function(f) tl.tempMode(f) end,
  pc    = function(f) tl.profileCycle() end,
  ssc   = function(f) tl.lcancel(f,tl.dir) end,
  sscst = function(f) tl.cycleBut(f,2,1) end,
  nc    = function(f) tl.cycleBut(f,3,0) end,
  sc    = function(f) tl.cycleBut(f,0,0) end,
  nct   = function(f) tl.cycleBut(f,3,1) end,
  sct   = function(f) tl.cycleBut(f,0,1) end,
  ncn  = function(f) tl.cycleBut(f,3,2) end,
  scn  = function(f) tl.cycleBut(f,0,2) end
}

tl.upDownFuncs={
  m     = function(f) tl.PlayMac(f) end,
  c     = function(f) tl.molect(f) end,
  ab    = function(f) tl.multiAbort(f) end,
  fn    = function(f) tl.executor(f) end,
  rc    = function(f) tl.cycleReset(f) end,
  ps    = function(f) tl.tPause(f) end,
  rs    = function(f) tl.tRes(f) end
}

tl.upFuncs = {
  nc    = function(f) tl.cycleBut(f,4,0) end,
  sc    = function(f) tl.cycleBut(f,1,0) end,
  nct   = function(f) tl.cycleBut(f,4,1) end,
  sct   = function(f) tl.cycleBut(f,1,1) end,
  ncte  = function(f) tl.cycleBut(f,4,2) end,
  scte  = function(f) tl.cycleBut(f,1,2) end
}

tl.macFuncs = {
  n     = function(f) tl.bothRay(f,delayer) end,
}

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
  elseif key ~="" then
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
  elseif key ~="" then
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
      for i=1,#k.modifier do local v = k.modifier[i]
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
      for i=1,#k.modifier do local v = k.modifier[i]
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
  local prelease = tl.PressAndRelease;
  local waiter = tl.wait;
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
    prelease(c,kelay)
    if delay and i < n then
      --tl.put("waiting for "..waitTime.."ms")
    waiter(waitTime)
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

function OnEvent(event, arg, family) -- Triggers whenever a mouse button is pressed, virtual or real.
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

function tl.put(input) --Outputs messages to lua log
  if type(input) ~= "string" then input=tostring(input)end
  OutputLogMessage(input.."\n")
end

function tl.profileCycle()
tl.normKey(tl.cycleCombi)
end

function tl.loadEx() -- Loads external configuration files depending on profile types
  local dirSelect = "ext_lua\\"
  if tl.workProfile == true then dirSelect = "ext_work\\" end
  if tl.exFile == true and loadfile(tl.path..dirSelect..tl.pName..".lua") then
    tl.findEx="Running on external configs"
    dofile(tl.path..dirSelect..tl.pName..".lua")
  elseif tl.exFile == true then
    tl.findEx="Running on internal configs, external file missing or broken"
  end
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
    for k,v in pairs(tl.TaskList) do
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
    for k,v in pairs(tl.TaskList) do
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
    for k,v in pairs(tl.TaskList) do
      v.paused = false
    end
  end
end

function tl.seQueue(nam,inst) --Keeps track of what coroutines are currently running
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

function tl.executor(convict) --Executes named sequences (recursively)
  if type(convict) == "string" then
    _G[convict]()
  elseif type(convict) == "table" then
    local namu = convict[1]
    table.remove(convict,1)
    _G[namu](unpack(convict))
    table.insert(convict,1,namu)
  end
end

function tl.addDown (key) --adds currently pressed down keys
  if tl.cutine ~=0 then
    tl.roDown[tl.cutine][#tl.roDown[tl.cutine]+1] = key
  end
end

function tl.remDown(key,sil) --removes keys from the held down list, when they are released again
  if sil then
    return
  else
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

function tl.allUp(there) --Releases all keys currently locked/held down, called at the end of the script.
  for i, va in pairs(tl.roDown[there]) do
    if va ~= nil then
      tl.put("auto-released "..va)
      tl.Release(va,0,1)
    end
  end
  tl.wipe(tl.roDown[there])
end

function tl.namecrawl(tar) --Defines IDs of all sequences (recursively)
  if tar.name and tar.name ~="" then -- If the sequences is named, the name will be used as its ID and a reference is put into a special array.
    tar.pID = tar.name
    tl.seqNamed[tar.name] = tar
  else
    tar.pID = "c"..tl.arn --otherwise a unique ID will be generated based on execution order.
    tl.arn = tl.arn+1
  end
  for g,n in pairs(tar) do
    if type(n) == "table" then
      tl.namecrawl(n)
    end
  end
end

function tl.allType(ta,ty)
  for i=1,#ta do
    if type(ta[i]) ~= ty then return false end
  end
  return true
end

function tl.noType(ta,ty)
  for i=1,#ta do
    if type(ta[i]) == ty then return false end
  end
  return true
end

function tl.someType(ta,ty)
  for i=1,#ta do
    if type(ta[i]) == ty then return true end
  end
  return false
end

function tl.intersect(t1,t2)
local t3 = {}

for k,v in pairs(t1) do
  t3[k] = v
end

for k,v in pairs(t2) do
  if t3[k] == nil then
    t3[k] = v
  end
end
return t3
end

function tl.wait(dur,name) --Pause function for all coroutines.
  if coroutine.running() ~= nil then
    coroutine.yield(dur)
    return
  end
  Sleep(dur)
end

function tl.mSync(torg,orig) --This function keeps the internal script mode in synch with the hardware's mode
  if tl.maxMode > 3 or tl.modeBound == false or tl.maxMode == 1 then return end
  local mod = orig or tl.modus
  local targ = torg or mod+1
  if targ == 0 then targ = mod + 1 end
  if targ > tl.maxMode then targ = 1 end
  if mod == targ then return end
  function pm()
    AbortMacro();
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

function tl.molect(targ,nope) --Put the mouse in a specific mode.
  if type(targ) == "table"then targ = targ[1] end
  if type(targ) ~= "number" then
    tl.checkM() return
  elseif tl.maxMode == 1 or tl.modus == targ then
    return
  end
  if tl.shiftor == false then
    tl.mSync(targ)
  end
  local midas = tl.modus
  function sMode() --sub function to make sure the modes cycle back correctly
    if tl.modus < tl.maxMode then
      tl.modus = tl.modus +1
    else
      tl.modus = 1
    end
  end
  if targ == nil or targ == 0 then --if the target mode is 0, just cycle to teh next mode
    sMode()
  elseif targ <= tl.maxMode then --else cycle until you reach teh target mode
    while targ ~= tl.modus do
      sMode()
    end
  else
    tl.molect(tl.maxMode)
  end
  if tl.autoHot == true then
    PressAndReleaseKey("f15")
  end
  tl.put("changed to mode "..tl.modus)
end

function tl.launch() --compile and display stats on script startup
  local defnum = 0
  local nanum = 0
  local gennum = tl.arn-1

  for k,v in pairs(tl.assign) do if k ~= "pID" then defnum = defnum+1 end end
  for k,v in pairs(tl.seqNamed) do nanum = nanum+1 end

  tl.put("\n\nG600 Profile '"..tl.pName.."' powered by T-lib v"..tl.verNum.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n")
  if tl.autoHot == true then
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

function tl.shutDown() --send shutdown message, abort all tasks, and set mode back to 1.
  tl.put("Profile '"..tl.pName.."' deactivated.")
  tl.multiAbort("")
  tl.molect(1,true)
end

function tl.defTab(num) --compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
  if num ~= tl.sKey then
    if tl.press == true then
      local cody = num
      if tl.shiftor == true then
        cody = cody.."t"
      else
        cody = cody.."f"
      end

      cody = cody..tl.modus
      cody = cody..tl.mods

      local curNum = {}
      local curSt = string.match(cody, "%a")
      local curMo = string.match(cody,"%a+$")

      for i in string.gmatch(cody, "%d+") do
        curNum[#curNum+1] = i
      end

      if tl.dir == "up" then --this part makes sure that if the state of of modifiers has changed since a button has been pressed, keyup events of the same button will still funtion correctly
        for i=1,#tl.downs do local obj = tl.downs[i]
          local tempNum = {}
          local tempSt =  string.match(obj, "%a")
          local tempMo = string.match(obj, "%a+$")

          for d in string.gmatch(obj, "%d+") do
            tempNum[#tempNum+1] = d
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
              tl.altMods = tempMo
            else
              tl.altMods = 0
            end
            table.remove(tl.downs,i)
          end
        end
      else
        tl.downs[#tl.downs+1] = cody
      end
    end
  end
end

function tl.setArgsB(ev,ar) --IDs for modifiers are set here
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

  for i=1,#morail do local obj = morail[i]
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
--At this point, a status message is generated, for the console to show current button states.
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
  lKey = " , Last Keys: "..tl.lastKey.down.."(down) , "..tl.lastKey.up.."(up)"

  OutputLogMessage("Key-Event = %s , Current Key = %s"..logKey.." , G-Shift = %s , Mode = %s%s%s%s%s\n", tl.dir, ar, tostring(tl.shiftus), tl.pMod, tabs, mads, tabs2, lKey)
end

function tl.setArgsE(ev,ar) --Make sure, no buttons that have been listed up are still listed as pressed down.
  if tl.invertG == true then
    tl.shiftus = tl.shiftor
  end
  tl.conKey = 0
  tl.finMods = tl.mods

  if tl.dir == "up"then
    for k in pairs(tl.cList) do
      if type(k) == 'string' then
        if string.match(k,"_"..tl.but.."t%-?%g*") then
          tl.cList[k]=nil
        end
      end
    end
  end
end

function tl.staggerRoutine(bifu,buta) --This is the standard setup for a staggered sequence coroutine
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

    while (relTime_r-preTime_r) < finalTime do --This is the important part that defines how long to wait before the next action is initialized.
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

function tl.staggerKey(bifu) --This is the main function for the staggered sequences and  cycling staggered sequences. it gets kind of complicated.
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
          for i=1,#tita do local obj = tita[i]
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

function tl.normKey(tg) --pressing and releasing a normal key, if it was provided as a string.
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

function tl.normKeyT(tg,dir)    --the same as above, but for toggling keys.
  if dir and dir ~= "down" then return end
  local isDown = false
  for k=1,#tl.toggled do local v = tl.toggled[k]
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


function tl.preRay(rayz) --pressing down an array of buttons in order
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Press(obj)
    end
  end
end

function tl.relRay(rayz) --...and releasing an array of buttons in order
  tl.Reverse(rayz)
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Release(obj)
    end
  end
  tl.Reverse(rayz)
end

function tl.bothRay(blu,del) --press an array of keys, then release it.
  tl.preRay(blu)
  if del then tl.wait(del) end
  tl.relRay(blu)
end

function tl.typer(tstring,del,kdel) --function for deciding how to type different strings and arrays
  local wt = del or tl.actionDelay
  local kwt = kdel or tl.keyDelay
  if (#tstring == 1 or (string.sub(tstring,0,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(string.sub(tstring,2,3)) < 25)))) then
    tl.PressAndRelease(tstring,kwt)
  else
    tl.TypeString(tstring,wt,kwt)
  end
end


function tl.cycleReset(buts)  --here, cycles for cycling sequences are reset, either for a specific one or all of them.
  if buts and type(buts) == "table" then
    for k=1,#buts do local v = buts[k] tl.cycleReset(v) end
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

function tl.lcancel(buts,dir)   -- function for cancelling the execution of staggered sequences
  if dir and dir ~= "down" then return end
  if buts and type(buts) == "table" then
    for k=1,#buts do local v = buts[k] tl.lcancel(v) end
    return
  end
  if buts and type(buts) == "string" and buts ~= "" then
    tl.stagTimer["_"..buts] = nil
  elseif buts == nil or buts == 0 then
    tl.wipe(tl.stagTimer)
  end
end

function tl.cycleBut(tar,cycleMod,temp) --main function for cycling sequences
  local numlog = tl.stable
  if temp then numlog = tl.unstable end
  local nofl=false
  if type(tar) ~= "table" or #tar ==1 then
    return
  else
    if numlog["_"..tar.pID] == nil then
      numlog["_"..tar.pID] = 1
      nofl=true
    end

    if (tl.dir == "down" and (cycleMod == 0 or cycleMod == 3)) or (tl.dir == "up" and (cycleMod == 1 or cycleMod ==4) or (cycleMod == 2 and tl.dir== "down")) then
      if (numlog["_"..tar.pID]+1) > #tar then --defining at which point a certain button is in its sequence and resetting it when necessary
        if temp ~= 2 then numlog["_"..tar.pID] = 1 end
        nofl=true
      end

      if nofl==false and (cycleMod ~= 2 or (cycleMod == 2 and tl.dir == "down")) then
        numlog["_"..tar.pID] = numlog["_"..tar.pID] + 1
      end
    end

    if (tl.dir == "down" and (cycleMod == 0 or cycleMod == 3)) or (tl.dir == "up" and (cycleMod == 1 or cycleMod ==4)) or cycleMod >= 2 then

      if cycleMod == 2 then --here all the different cycling modes for normal keys, sequences and staggered sequences are taken care of.
        tl.staggerKey(tar[numlog["_"..tar.pID]])
      elseif cycleMod == 0 or cycleMod == 1 or cycleMod == 4 then
        tl.quiKey(tar[numlog["_"..tar.pID]],tar[numlog["_"..tar.pID]].pID)
      elseif cycleMod == 3 then
        tl.normKey(tar[numlog["_"..tar.pID]])
      end
    end
  end
end

function tl.togMode(md) --toggling a different mouse mode as long as a button is held down
  if tl.dir == "down" then
    tl.lastMod = tl.modus
    tl.molect(md)
  else
    tl.molect(tl.lastMod)
    tl.lastMod=0
  end
end

function tl.tempMode(md,num) --changing the mode temporarily, but even after the button is released.
  if tl.lastModN == 0 and tl.dir == "down" then
    tl.lastModN = tl.modus
    tl.lastModC = tl.keyCount
    tl.molect(md)
  end
end

function tl.untempMode() --set the mode back to the standard mode once a single button press has been executed.
  if tl.lastModN ~=0 and (tl.keyCount - tl.lastModC) > 2 then
    tl.molect(tl.lastModN)
    tl.lastModN = 0
    tl.put("mode reset")
  end
end

function tl.checkM() --tells the autohotkey GUI to display the current mode.
  if tl.autoHot == true then
    PressAndReleaseKey("f16")
  end
end

function tl.quiKey(tg,name,dir,descPlay,m,v) --main function for executing macro sequences
  local descDir = descPlay or "normal"
  local mode = tg.play or "normal"
  local ride = tg.stack or tl.defStack
  local mouseN = m or 0
  local delayer = tg.delay or tl.actionDelay
  local dekayer = tg.kdelay or tl.keyDelay

  if dir then
    if ((mode == "normal" or mode == "toggle" or mode=="ptoggle") and ((dir == "up" and descDir == "normal") or (dir=="down" and descDir == "up" ))) then
      return --make sure we don't fire events meant to be played on keyup/keydown at the wrong time.
    elseif (mode == "hold" and dir == "up") then --pausing or aborting "hold" type sequences
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

    --^^ dealing with toggling sequences


  if name and v == nil then --launching coroutines
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

  function processTable() --process nested tables storing special information

    local noWait = false
    for i=1,#tg do local obj = tg[i]
      if i ~= 1 and noWait == false and type(obj) ~= "number" then
        tl.wait(delayer)
      elseif noWait == true  then
        noWait = false
      end

      if type(obj) == "string" then
        tl.typer(obj,delayer,dekayer)
      elseif type(obj) == "table" then
        if obj.type == nil and obj.t == nil then
          if tl.allType(obj,"string") then
            if #obj == 1 then tl.keyGen(mouseN,tl.seqNamed[obj[1]],0,true) else tl.bothRay(obj,delayer)end
          elseif tl.noType(obj,"table") and tl.someType(obj,"number") then
            if type(obj[1]) == "number" then delayer = obj[1] elseif (obj[1] == "default" or obj[1]=="d") then delayer = tg.delay or tl.actionDelay end
            if obj[2] ~= nil then
               if type(obj[2]) == "number" then dekayer = obj[2] elseif (obj[2] == "default" or f=="d") then dekayer = tg.kdelay or tl.keyDelay end
            end
        end
        else
          tl.keyGen(mouseN,obj,0,true)
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

function tl.PlayMac(nam,c) --play an external LGS macro
  if type(nam) == "table"then
  nam = nam[1]
  c = nam.consume
  end

  if c == 2 or c == 3 then
    AbortMacro()
    tl.macPlay = false
  end
  PlayMacro(nam)
end

function tl.TogMac(nam,c,d) --toggle an external LGS macro
  if type(nam) == "table"then
    nam = nam[1]
    c = nam.consume
  end
  if d and d ~= "down" then return end
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

function tl.key(mouse,cmd,def,shifted,modi,mkeys,mouseLock,keyLock,cons,tes,pDir,ident,virtu) --the main program for parsing key commands
  function tNum(n,rev)
    local putout = rev or false
    local downT = table.concat(tl.downs,",")
    if (string.match(downT,"^"..n.."%a%d%a*") ~= nil) or (string.match(downT,","..n.."%a%d%a*") ~= nil) then
      return not putout
    else
      return putout
    end
  end

  function tup(domo) --If specified, do the direction instructions on the key line up with the current input?
    local selec = 2
    if domo then selec = 1 end
    local reray = {{"normal","down"},{"up","up"}}
    return tl.dir == reray[selec][2] and pDir == reray[selec][1]
  end

  function tessa(ind) --evaluating the "test" conditions of a key.(recursive)
    local tes = ind or tes
    if tes == nil or tes == true then --is the test an expression that is truthy in itself?
      return true
    end

    local res = true
    local tas = tes

    if type(tes) == "number" then --testing for keys being currently held down.
      if 0 > tes then
        res = false
        tas = math.abs(tes)
      end

      if tl.dir == "down" and tNum(tas) == true then
        return res
      elseif tl.dir == "down" and tNum(tas) == false then
        if not virtu then tl.cList["_"..mouse.."t"..tes] = 1 end
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
    elseif type(tes) == "string" and tonumber(tes) then --testing for keys previously pushed.
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

    elseif type(tes) == "table" then --recursively testing arrays
      local m = tes.m or "or"
      if tl.dir =="down" or (tl.dir == "up" and tup()) then
        if tl.dir == "down" then
         if not virtu then tl.cList["_"..mouse.."t"..table.concat(tes,"")] = 1 end
        end

        for i=1,#tes do local obj = tes[i]
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

  if (tl.but == mouse or virtu) and (virtu or tl.conKey ~= mouse) then --starting the process to test if the right modifiers are down.

    if (mkeys == "no" and (lModif == nil or lModif== 0 or #lModif ==0)) or (mkeys ~="no" and (mkeys==nil or mkeys==0 or mkeys=="" or lModif == mkeys)) then
      okayK = true
    elseif type(lModif) == "string" and type(mkeys) == "string" then
      local comTab = {}
      local recTab = {}

      for i in string.gmatch(mkeys, "%a%a") do
        comTab[#comTab+1] = i
      end

      for i in string.gmatch(lModif, "%a%a") do
        recTab[#recTab+1] = i
      end

      typeComb = false

      for i=1,#recTab do local obj = recTab[i]
        typeComb = false
        for d=1,#comTab do local abj = comTab[d]
          if string.match(obj,"%a$") == string.match(abj,"%a$") then
            typeComb = true
          end
          if typeComb == false then
            break
          end
        end
      end

      keyComb = false

      for i=1,#comTab do local obj = comTab[i]
        keyComb = false

        for d=1,#recTab do local abj = recTab[d]
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
      for i=1,#modi do local obj = modi[i]
        if obj == lMod then
          okayM = true
          break
        end
      end
    else
      okayM = true
    end

    local teres = tessa() --on keyup, use the result of the test expression that has been generated on key down
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

    if okayG == true and okayM == true and okayK == true and ((pDir=="normal" or tup()) and teres) == true then
            --^^are all conditions for executing the button cleared?
      if not virtu then
        if tl.lastKey.down ~= mouse then tl.wipe(tl.unstable) end --here temporary cycling sequences are reset based on button id.
        tl.lastKey[tl.dir] = mouse
        if cons == 1  or cons==3 then
          tl.conKey = mouse
        else
          tl.conKey = 0
        end
      end

      if def then
        local mDir = tl.dir
        local tabs = tl.defaultFuncs
        if virtu then
        mDir = nil
        tabs = tl.funcRayM
        elseif tup() then
        tabs = tl.funcRayU
        elseif tup(1) then
        tabs = tl.funcRayD
        end
        if tabs[def] then tabs[def](cmd,mDir,pDir,mouse,virtu) end
      else
        tl.normKey(cmd)
      end
    end
  end
end

function tl.multiTab(acc) --is a table a button definition or another type of table?
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

function tl.keyGen(keyN,lock,keyCode,virt) --function for fetching a button's bindings and feeding it to the execution function.
  local pKey = tl.assign[keyCode]
  if virt then pKey = lock end
  if (lock.type == "sn" or lock.t=="sn") and tl.seqNamed[lock[1]] ~=nil then lock = tl.seqNamed[lock[1]]  end
  local cmd = lock
  tl.key(
  keyN,
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
  lock.pID or pKey.pID,
  virt)
end

function tl.overrideProps(source,code) --transmitting properties to child elements
  if type(source) ~= "table" then return end
  local tKey = tl.assign[code]
  for k , v in pairs(source) do
    tKey[k] = v
  end
end

function tl.setLast(n) --recording the current key for future reference
  if tl.lastKey.down ~= n then tl.wipe(tl.unstable) end
  tl.lastKey[tl.dir] = n
end

function tl.newSet(k) --evaluate inputs to see what kind of bindings they have
  local pChange = false
  local bCode
  if tl.logicalMouse == true then
    bCode = tl.reMouse[k]
  else
    bCode = "m"..k
  end

  local args = tl.assign[bCode]

  if type(k) ~= "number" or k == 0 or k > 20 then --can't press buttons that don't exist...
    error(" invalid mouse button")
  elseif args == nil then
    return
  elseif type(args) == "string" then
    tl.keyGen(k,args,bCode)
  elseif type(args) == "table" then
    if tl.multiTab(args) == true then
      for num=1,#args do local coms = args[num]
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

function tl.EventReceiver(event,arg,family) --set how to react to the differend kind of events
  if family == "" then family = "audio" end
  if string.sub(event,1,7) == "PROFILE" then family = "profile" end
  if event == "PROFILE_ACTIVATED" then
    tl.funcRayD = tl.intersect(tl.defaultFuncs,tl.upDownFuncs)
    tl.funcRayU = tl.intersect(tl.upFuncs,tl.funcRayD)
    tl.funcRayM = tl.intersect(tl.macFuncs,tl.funcRayD)
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
    tl.setLast(arg)
    tl.untempMode()
    tl.setArgsE(event,arg)
    if arg ~= tl.sKey then
      tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
    end
  end
end