local tl = ...
local ceil, IsKeyLockOn, IsModifierPressed, format, type ,concat , remove, pairs, ClearLCD =
math.ceil, IsKeyLockOn, IsModifierPressed, string.format, type, table.concat, table.remove,pairs, ClearLCD
--->>>> Functions that directly listen to events =================================================================================================

function OnEvent(event, arg, family) -- Triggers whenever a mouse button is pressed, virtual or real.
  if family ==  tl.PollFamily then
    tl.poll(event, arg, family)
  else
    tl._EventReceiver(event,arg,family)
    local fam = tl.token(family)
    if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == tl.state[fam].sKey then
    tl.state[fam].mBeforeG = tl.state[fam].modus
    elseif tl.state[fam] and arg == tl.state[fam].sKey and  tl.state[fam].mBeforeG ~= tl.state[fam].modus then
      tl.mSync(tl.state[fam].modus,tl.state[fam].mBeforeG,fam)
      tl.state[fam].mBeforeG = tl.state[fam].modus
    end
  end
  tl.doTasks()
end

local OnEvent = OnEvent

function tl._launch() --compile and display stats on script startup
  tl.quickGen(tl.assign.start)
  local defnum = 0
  local nanum = 0
  local gennum = tl.tabNum
  local monum = #tl.resolutions
  local moray = {}
  local moplural = ""
  if monum > 1 then moplural = "s" end
  for k,_ in pairs(tl.assign.key) do if k ~= "pID" then defnum = defnum+1 end end
  for _,i in pairs(tl.macroStats) do if i.macro and i.macro.name then nanum = nanum+1 end end
  for g=1, #tl.resolutions do local mon = tl.resolutions[g]
    moray[#moray+1] = mon.w.."x"..mon.h
  end
  tl.putNoLCD("\n\nG600 Profile '"..tl.profileName.."' powered by T-lib v"..tl.version.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n"..monum.." Monitor"..moplural.." configured ("..concat(moray,",")..")")
  if tl.outputLCD then tl.putLCD('')end
end

function tl._shutDown() --send shutdown message, abort all tasks, and set mode back to 1.
  tl.exitus = 1
  tl.quickGen(tl.assign.exit)
  tl.putNoLCD("Profile '"..tl.profileName.."' deactivated.")
  if tl.outputLCD then ClearLCD()end
  tl.multiAbort("")
  tl.molect(1,"all")
end

function tl._defTab(num,fam) --compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
  if num == tl.state[fam].sKey or not tl.press then return end
  if tl.logLevel ~= 0 and #tl.lastKeysDown ~= 0 and
  ((tl.logLevel > 0 and tl.lastKeysDown[#tl.lastKeysDown].played == nil) or
  (tl.logLevel == 2 and tl.lastKeysDown[#tl.lastKeysDown].played == 0)) then
    tl.lastKeysDown[#tl.lastKeysDown] = nil
  end

  local currentDir = tl.state[fam].dir
  local keyNum = fam..num

  if #tl.lastKeysDown ~= 0 and tl.lastKeysDown[#tl.lastKeysDown].name ~= keyNum then
    if tl.lastKeysDown.family == fam then
      tl.wipe(tl.state[fam].unstable)
    elseif not tl.separateDeviceCycles then
      for g=1, #tl.families do local cFam = tl.token(tl.families[g])
        tl.wipe(tl.state[cFam].unstable)
      end
    end

    for m,p in pairs(tl.TaskList) do
      if p.isTemp ~= nil then tl.taskAbort(m) end
    end
  end
  tl.downs[keyNum] = tl.downs[keyNum] or {}
  local saver = tl.downs[keyNum]
  if currentDir == "down" then
    saver.name = keyNum
    saver.reName = keyNum
    saver.shift = tl.state[fam].shift
    saver.mode = tl.state[fam].modus
    saver.modKeys = tl.mods
    saver.family = fam
  elseif currentDir == "up" then
    saver.shiftUp = tl.state[fam].shift
    saver.modeUp = tl.state[fam].modus
    saver.modKeysUp = tl.mods
    tl.downs[keyNum] = nil
  end
  tl.lastKeysDown[#tl.lastKeysDown+1] = saver
  if #tl.lastKeysDown > tl.historyDepth +1 then remove(tl.lastKeysDown,1) end
end

function tl._setArgsB(ev,ar,fam) --IDs for modifiers are set here
  local famto = tl.token(fam)
  tl.altMode = 0
  tl.mods = ""
  tl.state[famto].conKey = 0
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

  local lorail= {
    {"scrolllock","sl"},
    {"capslock","cl"},
    {"numlock","nl"},
  }

  for i=1,#morail do local obj = morail[i]
    if IsModifierPressed(obj[1]) then
      tl.mods = tl.mods..obj[2]
    end
  end

  for f=1,#lorail do local obj = lorail[f]
    if IsKeyLockOn(obj[1]) then
      tl.mods = tl.mods..obj[2]
    end
  end

  if ev == "MOUSE_BUTTON_PRESSED" then
    tl.state[famto].dir = "down"
    tl.press = true
  elseif ev == "MOUSE_BUTTON_RELEASED" then
    tl.state[famto].dir = "up"
  end

  if ar == tl.state[famto].sKey then
    tl.but = 0
    if tl.state[famto].dir == "down" then
      tl.state[famto].shift=1
    elseif tl.state[famto].dir == "up" then
      tl.state[fam].shift=0
    end
  else
    tl.but = ar
  end
end

function tl._logEvent(ev,ar,fam)
  local mads,tabs,tabs2,mem
  if tl.mods == nil or #tl.mods == 0 then
  mads=""
  else
    mads = " , modifiers active: "..tl.mods
  end
  tabs = ""
  for k,_ in pairs(tl.downs) do
    if tabs == "" then
      tabs = " , Keys Down = "..k
    else
      tabs = tabs..", "..k
    end
  end
  local logKey = ""
  if tl.customNames then
    logKey = " ("..(tl.rename[fam..ar] or fam..ar)..")"
  end
  local downList = {}
  local upList = {}
  for m=1, #tl.lastKeysDown do local el = tl.lastKeysDown[m]
      downList[#downList+1]= el.name
  end

  local lKey = " , Last Keys: "..concat(downList,",").."(down) , "..concat(upList,",").."(up)"
  mem = ""
  if tl.logMemory then
    mem = ", Memory in use: "
    local memUnit = "kB"
    local memKb = ceil(collectgarbage("count"))
    if(memKb > 1024)then
      memKb = format("%2f",(memKb/1024))
      memUnit = "mB"
    end
    mem = mem..memKb..memUnit
  end
  tl.putNoLCD("Key-Event = "..tl.state[fam].dir..", Current Key = "..fam..ar..logKey..", G-Shift = "..tl.state[fam].shift..", Mode = "..tl.pMod..tabs..mads..lKey..mem)
end

function tl._setArgsE(fam) --Make sure, no buttons that have been listed up are still listed as pressed down.
  tl.state[tl.token(fam)].conKey = 0
end

function tl._newSet(k,fam) --evaluate inputs to see what kind of bindings they have
  local bCode = fam..k
  local args = tl.assign.key[bCode]
  if args == nil then return
  elseif type(args) == "string" then
     tl.keyGen(k,fam,args,bCode)
  elseif type(args) == "table" then
    if tl.isContainer(args) == true then
      for num=1,#args do local coms = args[num]
          tl.keyGen(k,fam,coms,bCode)
      end
    else
      tl.keyGen(k,fam,args,bCode)
    end
  end
end

function tl._EventReceiver(event,arg,family) --set how to react to the differend kind of events
  if family == "" then
    if event == "PROFILE_ACTIVATED" then
      tl.assign = {}
      EnablePrimaryMouseButtonEvents(1)
      tl.funcRayD = tl.intersect(tl.defaultFuncs,tl.upDownFuncs)
      tl.funcRayU = tl.intersect(tl.upFuncs,tl.funcRayD)
      tl.funcRayM = tl.intersect(tl.macFuncs,tl.funcRayD)
      tl.buildBindings()
      tl.onPollEventIni()
      tl.initPolling()
      if tl.showCompiled then
        tl.prettyTab(tl.assign.key,"Assignments:")
        if #tl.assign.start ~= 0 then
          tl.prettyTab(tl.assign.start,"Start Function:")
        end
        if #tl.assign.exit ~= 0 then
          tl.prettyTab(tl.assign.exit,"Exit Function:")
        end
        if #tl.assign.library ~= 0 then
          tl.prettyTab(tl.assign.library,"Macro Library:")
        end
      end
      for _,v in pairs(tl.lintErrors) do
        tl.put("\n"..v)
      end
      tl._launch()
    elseif event == "PROFILE_DEACTIVATED" then
      tl._shutDown()
    end
  elseif family ~= tl.PollFamily then
    local famName = tl.token(family)
    tl._setArgsB(event,arg,famName)
    tl._defTab(arg,famName)
    tl._newSet(arg,famName)
    if tl.logEvents then tl._logEvent(event,arg,famName)end
    tl.untempMode(famName)
    tl._setArgsE(event,famName)
    if arg ~= tl.state[famName].sKey then
      tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
    end
  end
end