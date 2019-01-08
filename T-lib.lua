--Default values for the options specified in in the logitech bindings, as a fallback
tl.exFile = tl.exFile or 0
tl.workProfile = tl.workProfile or 0
tl.keyFile = tl.keyFile or "T-lib_keySetup.lua"
tl.autoHot = tl.autoHot or 0
tl.modeBound = tl.modeBound or 1
tl.sKey = tl.sKey or 6
tl.maxMode = tl.maxMode or 3
tl.PollInterval = tl.PollInterval or 10
tl.actionDelay = tl.actionDelay or 10
tl.keyDelay = tl.keyDelay or 10
tl.logicalMouse = tl.logicalMouse or 1
tl.defMode = tl.defMode or 0
tl.defG = tl.defG or 2
tl.preferShort = tl.preferShort or 0
tl.standartStagger = tl.standartStagger or 300

tl.modeStack = tl.modeStack or"append"
tl.shiftStack = tl.shiftStack or"append"
tl.customStack = tl.customStack or"append"
tl.modeSort = tl.modeSort or"standard"
tl.shiftSort = tl.shiftSort or"standard"
tl.customSort = tl.customSort or{}
tl.stackOrder = tl.stackOrder or{"custom","mode","shift"}
tl.stackAutoReverse = tl.stackAutoReverse or 1
tl.stackDepth = tl.stackDepth or 1
tl.singleType = tl.singleType or 0
tl.showCompiled = tl.showCompiled or 1

tl.defStack = tl.defStack or 1
tl.pName = tl.pName or "no_name"
tl.nameIndex = tl.nameIndex or 999

tl.modus = 1
tl.shiftor = false
tl.shiftus = false
tl.state = 0
tl.but = 0
tl.dir = 0
tl.mBeforeG = 1
tl.verNum = "1.7"
tl.findEx="Running on internal configs"
tl.press = false
tl.downs = {}
tl.invertG=false
tl.altMode=0
tl.pMod = 0
tl.mods= ""
tl.cycleTimer = {}
tl.cyclesComplete = {}
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
tl.dynamicTables = {}
tl.keyCount = 0
tl.arn = {}
tl.lastKey = {up={0,0},down={0,0}}
tl.pprint = dofile(tl.path..'inspect.lua')
dofile(tl.path .. tl.keyFile)

tl.reMouse={
  m1="m1",
  m2="m2",
  m3="m3",
  m4="m7",
  m5="m8",
  m6="m6",
  m7="m5",
  m8="m4",
  m9="g1",
  m10="g2",
  m11="g3",
  m12="g4",
  m13="g5",
  m14="g6",
  m15="g7",
  m16="g8",
  m17="g9",
  m18="g10",
  m19="g11",
  m20="g12"
}

tl.cycleCombi = {"/c","/s","/a","/24"}

tl.shortHands={
  {"t","type"},
  {"g","gshift"},
  {"m","mode"},
  {"mk","mkey"},
  {"c","consume"},
  {"l","loop"},
  {"p","play"},
  {"dir","direction"},
  {"ad","delay"},
  {"kd","keyDelay"}
}
--tl.normKey(tg,dir,relmod,vir,bid)
--tabs[def](cmd,mDir,pDir,mouse,virtu,virp)
tl.defaultFuncs={
  c     = function(f,g,h,b,v,y) tl.agnostiCycle(f,g,v,y) end,
  n     = function(f,g,h,b,v) tl.normKey(f,g,0,v,f.pID) end,
  p     = function(f,g,h,b,v) tl.normKey(f,g,1,v,f.pID) end,
  r     = function(f,g,h,b,v) tl.normKey(f,g,2,v,f.pID) end,
  s     = function(f,g,h,b,v)  tl.quiKey(f,f.name or f.pID,g,h,b,v) end,
  h     = function(f,g) tl.newStagger(f,g) end,
  eh    = function(f) tl.TogMac(f) end,
  et    = function(f) tl.TogMac(f,tl.dir) end,
  mt    = function(f) tl.TogMode(f) end,
}

tl.upDownFuncs={
  nt    = function(f,g,h,b,v) tl.normKey(f,g,3,v,f.pID) end,
  hc    = function(f) tl.lcancel(f,tl.dir) end,
  mn    = function(f) tl.tempMode(f) end,
  pc    = function(f) tl.profileCycle() end,
  e     = function(f) tl.PlayMac(f) end,
  ea    = function() AbortMacro() end,
  m     = function(f) tl.molect(f) end,
  sa    = function(f) tl.multiAbort(f) end,
  fn    = function(f) tl.executor(f) end,
  cr    = function(f) tl.cycleReset(f) end,
  sp    = function(f) tl.tPause(f) end,
  sr    = function(f) tl.tRes(f) end
}

tl.upFuncs = {
}

tl.macFuncs = {
 -- n     = function(f) tl.bothRay(f,delayer) end
}
tl.sequenceInheritor = {"gshift","mode","mkey","mouseLock","keyLock"}

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
--Library Functions from around the net... =======================================================================================
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
    if tl.logiKeys[key] then PressKey(key) return true else tl.remDown(key) tl.quiKey({key}) return end
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
  elseif key ~="" and tl.logiKeys[key] then
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
  if arg[1] and arg[1].cancel ~=nil then task.isTemp = 1 end
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
end

--->>> code written by myself ===============================================================================

---->>> 1. Functions that interact directly with the LGS software ==========================================

function tl.put(...) --Outputs messages to lua log
  for i=0, arg.n do
  if type(arg[i]) ~= "string" then arg[i]=tostring(arg[i])end
  end
  local fin = table.concat(arg," ")
  OutputLogMessage(fin.."\n")
end

function tl.profileCycle() -- cycles to the next LOGITECH Profile
  tl.normKey(tl.cycleCombi,nil,0,1)
end

function tl.loadEx() -- Loads external configuration files depending on profile types
  local dirSelect = "ext_lua\\"
  if tl.workProfile == 1 then dirSelect = "ext_work\\" end
  if tl.exFile == 1 and loadfile(tl.path..dirSelect..tl.pName..".lua") then
    tl.findEx="Running on external configs"
    dofile(tl.path..dirSelect..tl.pName..".lua")
  elseif tl.exFile == 1 then
    tl.findEx="Running on internal configs, external file '"..tl.path..dirSelect..tl.pName..".lua".."' missing or broken"
  end
end

function tl.mSync(torg,orig) --This function keeps the internal script mode in synch with the hardware's mode
  if tl.maxMode > 3 or tl.modeBound == 0 or tl.maxMode == 1 then return end
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
  if tl.autoHot == 1 then
    PressAndReleaseKey("f15")
  end
  tl.put("changed to mode "..tl.modus)
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
  if tl.autoHot == 1 then
    PressAndReleaseKey("f16")
  end
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

---->>> 2. Functions that control coroutines ================================================================

function tl.wait(dur,name) --Pause function for all coroutines.
  if coroutine.running() ~= nil then
    coroutine.yield(dur)
    return
  end
  Sleep(dur)
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

---->>> 3. Functions controlling sequences that are run on key press ========================================

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

function tl.normKey(tg,dir,relmod,vir,bid,del)
if vir and dir == nil then
  if type(tg) == "string" then
    tl.Press(tg,del)
  elseif type(tg) == "table" then
    tl.preRay(tg,del)
  end
else
  if (dir == "down" and relmod == 0) or relmod == 1 or (relmod == 3 and tl.toggled["_"..bid] == nil) then
    if relmod == 3 then 
     tl.toggled["_"..bid] = 1 
    end
    if type(tg) == "string" then
      tl.Press(tg)
    elseif type(tg) == "table" then
      tl.preRay(tg)
    end
  elseif (dir =="up" and relmod == 0) or relmod == 2 or (dir == "down" and relmod == 3 and tl.toggled["_"..bid] ~= nil) then
    if type(tg) == "string" then
      tl.Release(tg)
    elseif type(tg) == "table" then
      tl.relRay(tg)
    end
    if relmod == 3 then 
      tl.toggled["_"..bid] = nil
    end
  end
end
end

function tl.quiKey(targ,name,dir,descPlay,mos,vir) --main function for executing macro sequences
  local tg = targ._tablified_s or targ
  if tg.assume then tg = tg._tablified_s or assumption(tg,"s") end
  local descDir = descPlay or "normal"
  local mode = tg.play or "normal"
  local ride = tg.stack or tl.defStack
  local mouseN = mos or 0
  local delayer = tl.actionDelay
  local dekayer = tl.keyDelay

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
  if  vir ~= 1 and vir ~= 3 and name and tl.TaskList[tg.pID] == nil then --launching coroutines
    if tl.TaskList[name] == nil then
      tl.TaskRun(name,tl.quiKey,tg,nil,dir,descDir,mouseN,vir)
    else
      if tl.TaskList[name].paused == true then
        tl.TaskList[name].paused = false
      elseif ride == 0 then
        tl.TaskRun(name,tl.quiKey,tg,nil,dir,descDir,mouseN,vir)
      elseif ride == 2 then
        tl.seQueue(name,tg,nil,dir,descDir,mouseN,vir)
      end
    end
    return
  end

  function processTable() --process nested tables storing special information
    local looper = tg.loop or tg.l or 1
    local loopNum = #tg*looper
    if looper == 0 then return -1 elseif looper < 0 then loopNum = math.huge end

    local noWait = false
    for g=1, loopNum do
      local i = g - (#tg*(math.ceil((g/#tg-1)+1)-1))
      local obj = tg[i]
      if i ~= 1 and noWait == false and type(obj) ~= "number" then
        tl.wait(delayer)
      elseif noWait == true  then
        noWait = false
      end
      if type(obj) == "string" then
        tl.typer(obj,delayer,dekayer)
      elseif type(obj) == "table" then
        if tl.props(obj) == false then
          if tl.allType(obj,"string") then
            if #obj == 1 then tl.keyGen(mouseN,tl.seqNamed[obj[1]],0,1,dir) else tl.normKey(obj,nil,0,1,obj.pID,delayer)end
          elseif tl.allType(obj,"number") then
            if obj[1] >= 0 then delayer = obj[1] elseif obj[1] == -1 then delayer = tg.delay or tl.actionDelay elseif obj[1] == -2 then delayer =  tl.actionDelay end
            if obj[2] ~= nil then
               if obj[2] >= 0 then dekayer = obj[2] elseif obj[2] == -1 then dekayer = tg.kdelay or tl.keyDelay elseif obj[2] == -2 then delayer = tl.actionDelay end
            end
        end
        else
            obj.delay= obj.delay or delayer
            obj.kdelay=obj.kdelay or dekayer
            for m=1, #tl.sequenceInheritor do local attr = tl.sequenceInheritor[m]
            obj[attr] =  obj[attr] or tg[attr]
            end
          tl.keyGen(mouseN,obj,0,1,dir)
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
    end
    return -1
end

function tl.agnostiCycle(tarry,dir,vir,virpar) --main function for cycling sequences
  local tar = tarry._tablified_c or tl.assumption(tarry,"c")
  local lim = tar.limit or math.huge
  local inherit = tar.inherit or "all"
  if lim == 0 then lim = math.huge end
  local rupture = tar.cancel or 0
  local parent = virpar or 999
  if type(parent) ~= "number" then parent= "_"..parent end
  local numlog = tl.stable
  local quitter = tar.finish or "stall"
  local start = 1
  local init = start
  local finish = #tar
  if type(tar.range) == "table" and tl.allType(tar.range,"number") then

    for  j=1, #tar.range do local ab=tar.range[j]
      if tar.range[j] <= 0 then tar.range[j] = #tar + tar.range[j] end
    end
    if tar.range[2] and tar.range[2] < #tar then
      init = tar.range[2]
    end
    if tar.range[1] < #tar then
      start = tar.range[1]
    end
    finish = tar.range[3] or finish
    if finish > #tar then finish = #tar end
  end

  local directed = 2
  if vir then directed = 3 end
  if rupture == 1 or rupture < 0 then numlog = tl.unstable end

  if type(tar) ~= "table" then
    return
  else
    if numlog["_"..tar.pID] == nil or (vir and dir=="down" and (tl.unstable[parent] == 1 or tl.stable[parent] == 1) and tl.cyclesComplete[parent] == 1 and tar.inherit ~= "timing" and tar.inherit ~= "none") then
      numlog["_"..tar.pID] = init
      tl.cyclesComplete["_"..tar.pID] = 1
      tl.cycleTimer["_"..tar.pID] = GetRunningTime()
    elseif rupture ~=0 and rupture ~=1 and (vir ~= nil or dir == "down") and (GetRunningTime() -tl.cycleTimer["_"..tar.pID] > math.abs(rupture)) then
      numlog["_"..tar.pID] = init
      tl.cyclesComplete["_"..tar.pID] = 1
    end

    if type(tl.cyclesComplete["_"..tar.pID]) == "number" and quitter=="end" and tl.cyclesComplete["_"..tar.pID] > lim then
      return end
    if vir and virpar and tar.inherit ~= "status" and tar.inherit ~= "none" then
      tl.cycleTimer["_"..tar.pID] = tl.cycleTimer[parent]
    else
      tl.cycleTimer["_"..tar.pID] = GetRunningTime()
    end
    tl.keyGen(0,tar[numlog["_"..tar.pID]],0,directed,dir,tar.pID)
      if vir ~= nil or dir == "up" then
        numlog["_"..tar.pID] = numlog["_"..tar.pID] + 1
        if numlog["_"..tar.pID] > finish or numlog["_"..tar.pID] > #tar then
          if not (init > finish and numlog["_"..tar.pID] < #tar  and tl.cyclesComplete["_"..tar.pID] == 1) then
            if tl.cyclesComplete["_"..tar.pID] < lim then
              numlog["_"..tar.pID] = start
              tl.cyclesComplete["_"..tar.pID] = tl.cyclesComplete["_"..tar.pID] + 1
            else
              tl.cyclesComplete["_"..tar.pID] = lim+1
              numlog["_"..tar.pID] = #tar
            end
          end
        end
      end
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
  elseif buts == "" or buts == 0 then
    tl.wipe(tl.stable)
    tl.wipe(tl.unstable)
  end
end

function tl.finalStagger(con,startval,tID)
  while GetRunningTime() < (startval + con[1]) do
    tl.wait(tl.PollInterval)
  end
  if tl.stagTimer["_"..tID] ~= nil then
    tl.stagTimer["_"..tID] = nil
    tl.keyGen(0,con[2],0,4)
  end
  return -1
end

function tl.newStagger(cam, dira)
  local com = cam._tablified_s or cam
  if com.assume then com = com._tablified_s or tl.assumption(com,"s") end
  if type(com) ~="table" or #com < 2 then return end
  local deflay = com.defaultHold or tl.standartStagger
  local curlay = 0
  local initas = com.init or 0
  local lease = com.release or "auto"
  local dirge = dira or tl.dir
  local singleD = false
  local comray = com
  local stagMode = com.mode or "relative"
  local commy = tl.intersect(com,{})
  local lastN = table.remove(commy)
  if type(lastN) == "number" and tl.noType(commy,"number") then
  comray = commy
  deflay = lastN
  singleD = true
  end

  local workTab={}
  for i=1, #comray do local that = comray[i]
    if type(that) == "number" then
        deflay = that
    elseif initas == 1 and #workTab == 0 then
      initas = 0
      deflay = 0
      if dirge == "down" then tl.keyGen(0,that,0,4) end
    else
      table.insert(workTab,{curlay,that})
      if stagMode == "absolute" then
        curlay =  deflay
      else
        curlay = curlay + deflay
      end
    end
  end

  if dirge == "down" then
    if lease == "auto" then
      local seppy = table.remove(workTab)
      tl.TaskRun(com.pID,tl.finalStagger,seppy,GetRunningTime(),com.pID)
    end

    tl.stagTimer["_"..com.pID] = GetRunningTime()
  elseif dirge =="up" and tl.stagTimer["_"..com.pID] ~= nil then
    local timeNow = GetRunningTime() - tl.stagTimer["_"..com.pID]
      for g=1, #workTab do
        local i = #workTab-g+1
        local tabsi = workTab[i]
        if tabsi[1] < timeNow then
          tl.keyGen(0,tabsi[2],0,4)
          break
        end
      end
    tl.stagTimer["_"..com.pID] = nil
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

---->>> 4.Functions for dealing with tables =================================================================================

function tl.full(tab) --does the table have any contents besides empty tables
  if type(tab) ~= "table" then
    return  true
  end
    for i=1, #tab do
      if tl.full(tab[i]) then return true end
  end
  return false
end

function tl.allType(ta,ty) -- Is there only a single data type stored in a table?
  for i=1,#ta do
    if type(ta[i]) ~= ty then return false end
  end
  return true
end

function tl.props(tb) --does the table contain non-numeric keys?
  for i,k in pairs(tb) do
    if type(i) == "string" and i ~= "pID" then return true end
  end
  return false
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

function tl.noType(table,typus) -- does a table NOT contain values of a certain type?
  for k, v in pairs(table) do
    if type(v) == typus then
      return false
    end
  end
  return true
end

function tl.intersect(tBase,tAdd,override) --Merge two tables in different ways
  local tRes = {}
  local tOver ={}
  local rider = override or 1
  local ignoray={
    {"pID","name"},
    {"singleType","pID","name"},
    {1,"type","t","pID","name","newType"}
  }
  for k,v in pairs(tBase) do
    tRes[k] = v
  end

  for k,v in pairs(tAdd) do
    tOver[k] = v
  end

  for k,v in pairs(tOver) do
    local ig = true
    for i=1, #ignoray[rider] do
      if k == ignoray[rider][i] then
        ig = false
      end
    end
    if override == 3 and k == "newType" then
      tRes.type= v
    end
    if (tRes[k] == nil or override == 1 or override == 3) and string.match(k,"^_c") == nil and ig then
      tRes[k] = v
    end
  end
  return tRes
end

function tl.tablecrawl(tar) --Defines IDs of all sequence tables (recursively)
  for  o = 1, #tl.shortHands do local short = tl.shortHands[o]
    if tar[short[1]] then
      local shorty = tar[short[2]] or tar[short[1]]
      if tl.preferShort == 1 then shorty = tar[short[1]]  end
      tar[short[2]] =  shorty
      tar[short[1]] = nil
    end
  end
  if tar.assume ~= nil then tl.assumption(tar,tar.type) end

  if tar.pID == nil and tar.name and tar.name ~="" then -- If the sequences is named, the name will be used as its ID and a reference is put into a special array.
    tar.pID = tar.name
    tl.seqNamed[tar.name] = tar
  elseif tar.pID == nil then
    tar.pID = "c"..#tl.arn+1 --otherwise a unique ID will be generated based on execution order.
    tl.arn[#tl.arn+1] = tar
  end
  for g,n in pairs(tar) do
    if type(n) == "table" then
      tl.tablecrawl(n)
    end
  end
end

function tl.inherit(taba,globalis) --pass parent properties to child tables
  for k,d in pairs(taba) do
    local rideray = {}
    local gloverbal = {}
    if globalis == 1 then
    rideray = tl.assign.global
    gloverbal = tl.assign.globalOverride
    end

    if type(k) == "string" and string.match(k,"^[gm][0-9]+$") then
      if type(d) == "table" and tl.props(d) == false then
        local m = 1
        while d[m] ~= nil do local v = d[m]
          if type(v) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
            v = {v}
          end
          if type(v) == "table" then
            if #v == 0 then
              rideray = tl.intersect(rideray,v,1)
              table.remove(d,m)
              m=m-1
            elseif tl.props(tl.intersect(rideray,gloverbal,1)) then
              taba[k][m] = tl.intersect(tl.intersect(v,rideray),gloverbal,1)
            end
          end
          m=m+1
        end
      elseif type(d) == "table" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      elseif type(d) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        d = {d}
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      end
    end
  end
  if globalis == 1 then
    tl.assign.global = nil
    tl.assign.globalOverride = nil
  end
end

function tl.assumption(tur,lat) --special inherit function for virtual buttons
  local let = lat or "s"
  local g = 1
  local old =tl.intersect({},tur,1)
  while g < #old+1 do
    if let == "c" and type(old[g]) == "number" then
    table.remove(old,g)
    g = g - 1
    elseif type(old[g]) ~= "number" then
      if type(old[g]) ~= "table" then old[g] = {old[g]} end
      old[g].type = old[g].type or old.assume
      for m=1, #tl.sequenceInheritor do local attr = tl.sequenceInheritor[m]
      old[g][attr] =  old[attr] or old[g][attr]
      end
    end
    g = g + 1
  end
  old.assume = nil
  tur.assume = nil
  tl.tablecrawl(old)
  tur["_tablified_"..let] = old
  tl.put(let)
  tl.prettyTab(old)
  return old
end

function tl.prettyTab(tabu,specmes) --pretty prints a table
  specmes=specmes or ""
  local hana = tl.pprint(tabu)

  hana = string.gsub(hana,"[\n]","")
  hana = string.gsub(hana," +"," ")
  hana = string.gsub(hana,"^{ *","")
  hana = string.gsub(hana,"}$","")
  hana = string.gsub(hana,", ([gm][0-9])",",\n%1")
  --hana = string.gsub(hana,"},{","},\n{")
  --hana = string.gsub(hana,"([}{])([}{])","%1\n%2")

  tl.put("\n"..specmes.."\n"..hana)
end

--->>> 5. Functions that process or type strings ==================================================================

function tl.querylize(query,targ) --implements a javascript-like "/.../" syntax for distinguishing between string and regex matches
  if string.match(query,"^/") and string.match(query,"/$") then

    if string.match(targ,string.sub(query,2,-2)) then return true end
  else
    return targ == query
  end
  return false
end

function tl.preRay(rayz) --pressing down an array of buttons in order
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Press(obj)
    end
  end
end

function tl.relRay(rayz,norev) --...and releasing an array of buttons in order
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

--->>> 6. functions magaging pressed keys ==================================================================================================

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

--->>> 7. The main framework functions for the script ===========================================================================================

function tl.prepKeys() --Prepare the key assignments array
  tl.assign.start={}
  tl.assign.exit={}
  tl.assign.global={}
  tl.assign.globalOverride={}
  tl.assign.key={}
  function resign(tagta,cdepth)
    local depth = cdepth or 0
    if tl.sKey ~= 0 then
      for p=0, 2 do
        tagta["s"..p]={}
        if depth < tl.stackDepth then resign(tagta["s"..p],depth+1) end
      end
    end

    for i = 0, tl.maxMode do
      tagta["mode"..i]={}
      if depth < tl.stackDepth then resign(tagta["mode"..i],depth+1) end
    end
  end
  resign(tl.assign)
end

function tl.toKey(legtab) --push legacy key bindings into the key table and apply default bindings
  for k,v in pairs(legtab) do
    if type(k) == "string" and string.match(k,"^[gm][0-9]+") then
      legtab.key[k] = legtab.key[k] or v
      legtab[k] = nil
    end
  end
  legtab.key.m3 = legtab.key.m3 or {"/3",m=0,s=0}
  legtab.key.m4 = legtab.key.m4 or {"/4",m=0,s=0}
  legtab.key.m5 = legtab.key.m5 or {"/5",m=0,s=0}
end

function tl.compileAssignments(startable) --main function for parsing the flexible syntax
  local collector = startable.key

  function tabExtract(state,presets,moda) --Extract button functionality and put it into the main table
    tl.inherit(state)
    local stackM = tl[moda.."Stack"]
    local secundus = {}
    local prosits = tl.intersect({},presets)
    local hastype = prosits.type
    local single = prosits.singleType or tl.singleType

    for k,v in pairs(state) do
      if type(k) == "string" and string.match(k,"^[gm][0-9]+") then
          if type(v) ~= "table" then
              v={v}
              v = tl.intersect(v,prosits,2)
          elseif tl.props(v) or (hastype ~= nil and single == 1) then
            v = tl.intersect(v,prosits,2)
          else
            for u=1, #v do
              if type(v[u]) ~= "table"  then
                v[u]={v[u]}
              end
              v[u] = tl.intersect(v[u],prosits,2)
            end
          end

          if collector[k] == nil then
            collector[k] = v
          else
              if type(collector[k]) ~= "table" or tl.props(collector[k]) == true or tl.noType(collector[k],"table") then
                collector[k]={collector[k]}
              end
              if type(v) ~= "table" or tl.props(v) then
                if stackM == "prepend" then
                  table.insert(collector[k],1,v)
                else
                  collector[k][#collector[k]+1]=v
                end
              else
                for u=1, #v do local h = u
                  if stackM == "prepend" then
                    if tl.stackAutoReverse == 1 then h = #v-u+1 end
                    table.insert(collector[k],1,v[h])
                  else
                    collector[k][#collector[k]+1]=v[h]
                  end
                end
              end
          end
          state[k]=nil
      elseif type(state[k]) == "table" and k ~= "key" then
          secundus[k]=v
          state[k]=nil
      end
    end
    return {secundus,prosits,moda}
    end

  function unhier(t,prevs) --recursively retrieve key definitions from array
  local nextWave={}
  tl.inherit(t)
  prevs = prevs or {}
  local provs = tl.intersect({},prevs)
    function setMode()
      local retVal={}
      for k=0, tl.maxMode do local j = k
        if tl.modeSort == "reverse" then
          j = tl.maxMode-k
        elseif type(tl.modeSort) == "table" and #tl.modeSort == tl.maxMode+1 then
          j = tl.modeSort[k+1]
        end
        if  t["mode"..j] ~=nil then
          local curtable = t["mode"..j]
          provs.mode = j
          retVal[#retVal+1] = tabExtract(curtable,provs,"mode")
          t["mode"..j]=nil
        end
        provs.mode=prevs.mode
      end
    return retVal
    end

    function setShift()
      local retVal={}
      if tl.sKey ~=0 then
        for h = 0 , 2 do local i = h
          if tl.shiftSort == "reverse" then
            j = tl.maxMode-h
          elseif type(tl.shiftSort) == "table" and #tl.shiftSort == 3 then
            j = tl.shiftSort[h+1]
          end
            if t["s"..i] ~=nil then
                local shiftable = t["s"..i]
                provs.gshift = i
                retVal[#retVal+1] = tabExtract(shiftable,provs,"shift")
                t["s"..i] = nil
            end
            provs.gshift=prevs.gshift
          end
        end
    return retVal
    end

    function setCustom()
      local retVal={}
      for r = 1, #tl.customSort do local cusn = tl.customSort[r]
        local privs = {}
        if t[cusn] and t[cusn] == "table" then
          for d,m in pairs(t[cusn]) do
            if type(d) == "string" and not string.match(d,"^[gm][0-9]+") then privs[d] = m end
          end
          retVal[#retVal+1] = tabExtract(t[cusn],tl.intersect(prevs,privs,1),"custom")
          t[cusn]=nil
        end
      end

    for h,p in pairs(t) do
      local privs = {}
        if string.match(h,"^_c") and type(p) == "table" then
          for d,m in pairs(p) do
            if type(d) == "string" and not string.match(d,"^[gm][0-9]+") then privs[d] = m end
          end
          retVal[#retVal+1] = tabExtract(p,tl.intersect(prevs,privs,1),"custom")
          t[h]=nil
        end
      end
    return retVal
  end

  local ordertable = {custom=setCustom,mode=setMode,shift=setShift}
  for g = 1, #tl.stackOrder do local l = g
    if tl.stackAutoReverse == 1 and tl.modeStack == "prepend" and tl.shiftStack == "prepend" and tl.customStack == "prepend" then
      l = #tl.stackOrder-g+1
    end
    nextWave[#nextWave+1] = ordertable[tl.stackOrder[l]]()
  end

    if tl.full(nextWave) then
      for t=1,#nextWave do local n= nextWave[t]
        for o=1, #n do local x=n[o]
          unhier(x[1],x[2],x[3])
        end
      end
    end
  end

  unhier(startable)
  unhier(startable.key)
  startable = collector
end

function tl.keyGen(keyN,lock,keyCode,virt,virtrect,virpar) --function for fetching a button's bindings and feeding it to the execution function.
  local pKey = tl.assign.key[keyCode]
  if virt then pKey = lock end
  if (lock.type == "l") and tl.seqNamed[lock[1]] ~=nil then
    local unlock = tl.seqNamed[lock[1]]
    if tl.dynamicTables[unlock.pID] ~= nil then
      lock = tl.dynamicTables[unlock.pID]
    else
      lock = tl.intersect(unlock,lock,3)
      tl.dynamicTables[unlock.pID] = lock
    end
  end

  local cmd = lock

 tl.key(
  keyN,
  cmd,
  lock.type,
  lock.gshift or pKey.gshift or tl.defG,
  lock.mode or pKey.mode or tl.defMode,
  lock.mkey or pKey.mkey,
  lock.mouseLock or pKey.mouseLock,
  lock.keyLock or pKey.keyLock,
  lock.consume or pKey.consume,
  lock.test or pKey.test,
  lock.direction or pKey.direction or "normal",
  lock.pID or pKey.pID,
  virt,
  lock.simDir or virtrect,
  virpar)
end

function tl.quickGen(bar) --quick and dity keyGen call
  if type(bar) ~= "table" or #bar ~= 0 then
   tl.keyGen(0,bar,0,1,"down",4)
  end
end

function tl.key(mouse,cmd,def,shifted,modi,mkeys,mouseLock,keyLock,cons,tes,pDir,ident,virtu,virdir,virp) --the main program for parsing key commands
  local mouseDir = virdir or tl.dir
  local played = 0
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
    return mouseDir == reray[selec][2] and pDir == reray[selec][1]
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

      if mouseDir == "down" and tNum(tas) == true then
        return res
      elseif mouseDir == "down" and tNum(tas) == false then
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
      local idx = 2
      if virtu and tl.lastKey.down[idx] == mouse then idx = 1 end
      tas = tonumber(tes)
      local tus = tonumber(tes)
      if 0 > tus then
        tas = math.abs(tas)
        if tl.lastKey.down[idx] ~= tas or (mouseDir == "up" and tl.lastKey.down[idx] ~= mouse and tl.lastKey.up[idx] ~= mouse) then
          return res
        else
          return not res
        end

      else
        if tl.lastKey.down[idx] == tas or (mouseDir == "up" and tl.lastKey.down[idx] == mouse and tl.lastKey.up[idx] ~= mouse) then
          return res
        else
          return not res
        end
      end

    elseif type(tes) == "string" then
      if string.match(tes,"^!?/") and string.sub(tes,-1) == "/" then
        if string.sub(tes,1,1) == "!" and tl.props(tl.TaskList) == false then
          return res
        elseif tl.props(tl.TaskList) == false then
          return not res
        end
        for r,t in pairs(tl.TaskList) do
          if string.sub(tes,1,1) == "!" then
            local tos = string.sub(tes,2)
            if tl.querylize(tos,r) then return not res end
          else

            if tl.querylize(tes,r) then return res end
          end
        end
      else
        if string.sub(tes,1,1) == "!" then
          local tos = string.sub(tes,2)
          if tl.TaskList[tos] ~= nil then return not res end
        else
          if tl.TaskList[tes] ~= nil then return res end
        end
      end

    elseif type(tes) == "table" then --recursively testing arrays
      local m = tes.mode or "or"
      if mouseDir =="down" or (mouseDir == "up" and tup()) then
        if mouseDir == "down" then
         if not virtu then tl.cList["_"..mouse.."t"..table.concat(tes,"")] = 1 end
        end

        for i=1,#tes do local obj = tes[i]
          if m == "or" and tessa(obj) == true then return true end
          if m == "and" and tessa(obj) == false then return false
        elseif m == "and" and i == #tes then return true end
        end
        return false

      elseif mouseDir == "up" then
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
      if mouseDir == "down" then
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

    if okayG == true and okayM == true and okayK == true and  teres == true then
            --^^are all conditions for executing the button cleared?
        if not virtu then
        if tl.lastKey.down[2] ~= mouse then
          tl.wipe(tl.unstable)
          for m,p in pairs(tl.TaskList) do
            if p.isTemp ~= nil then tl.TaskAbort(m) end
          end
        end --here temporary cycling sequences are reset based on button id.
        tl.lastKey[mouseDir][3] = mouse
        tl.lastKey[mouseDir] = {tl.lastKey[mouseDir][2],tl.lastKey[mouseDir][3]}
        if cons == 1  or cons==3 then
          tl.conKey = mouse
        else
          tl.conKey = 0
        end
      end

        local mDir = mouseDir
        local tabs = tl.defaultFuncs
        if virtu and virtu ~= 2 and virdir == nil then
        mDir = nil
        tabs = tl.funcRayM
        elseif tup() then
        tabs = tl.funcRayU
        elseif tup(1) then
        tabs = tl.funcRayD
        end
      if def then
        if tabs[def] then
          tabs[def](cmd,mDir,pDir,mouse,virtu,virp)
          
          played = 1
        end
        played = 2
      else
        tabs.n(cmd,mDir,pDir,mouse,virtu,virp)
        played = 1
      end
    end
  end
  return played
end

--->>>> 8. Functions that directly listen to events =================================================================================================

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

function tl.launch() --compile and display stats on script startup
  tl.quickGen(tl.assign.start)
  local defnum = 0
  local nanum = 0
  local gennum = #tl.arn

  for k,v in pairs(tl.assign.key) do if k ~= "pID" then defnum = defnum+1 end end
  for k,v in pairs(tl.seqNamed) do nanum = nanum+1 end

  tl.put("\n\nG600 Profile '"..tl.pName.."' powered by T-lib v"..tl.verNum.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n")
  if tl.autoHot == 1 then
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
  tl.quickGen(tl.assign.exit)
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
  if tl.logicalMouse == 1 then
    logKey = " ("..tl.reMouse["m"..ar]..")"
  end
  lKey = " , Last Keys: "..table.concat(tl.lastKey.down,",").."(down) , "..table.concat(tl.lastKey.up,",").."(up)"

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

function tl.newSet(k) --evaluate inputs to see what kind of bindings they have
  local pChange = false
  local bCode
  if tl.logicalMouse == 1 then
    bCode = tl.reMouse["m"..k]
  else
    bCode = "m"..k
  end

  local args = tl.assign.key[bCode]

  if type(k) ~= "number" or k == 0 or k > 20 then --can't press buttons that don't exist...
    error(" invalid mouse button")
  elseif args == nil then
    return
  elseif type(args) == "string" then
    tl.keyGen(k,args,bCode)
  elseif type(args) == "table" then
    if tl.multiTab(args) == true then
      for num=1,#args do local coms = args[num]
        if #coms ~= 0 then
          tl.keyGen(k,coms,bCode)
        end
      end
    else
      tl.keyGen(k,args,bCode)
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
    tl.prepKeys()
    tl.OnPollEventIni()
    tl.InitPolling()
    tl.setKeys()
    tl.toKey(tl.assign)
    tl.compileAssignments(tl.assign)
    tl.inherit(tl.assign.key,1)
    if tl.showCompiled == 1 then
      tl.prettyTab(tl.assign.key,"Assignments:")
      if #tl.assign.start ~= 0 then
        tl.prettyTab(tl.assign.start,"Start Function:")
      end
      if #tl.assign.exit ~= 0 then
        tl.prettyTab(tl.assign.exit,"Exit Function:")
      end
    end
    tl.tablecrawl(tl.assign)
    tl.launch()
  elseif event == "PROFILE_DEACTIVATED" then
    tl.shutDown()
  elseif family ~= tl.PollFamily then
    tl.setArgsB(event,arg)
    tl.newSet(arg)
    tl.untempMode()
    tl.setArgsE(event,arg)
    if arg ~= tl.sKey then
      tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
    end
  end
end