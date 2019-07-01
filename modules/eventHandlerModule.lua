local tl = ...
local IsModifierPressed = IsModifierPressed
local IsKeyLockOn = IsKeyLockOn
--->>>> Functions that directly listen to events =================================================================================================

function OnEvent(event, arg, family) -- Triggers whenever a mouse button is pressed, virtual or real.
  tl.EventReceiver(event,arg,family)
  tl.DoTasks()
  tl.Poll(event, arg, family, st)
  local fam = tl.token(family)
  if event == "MOUSE_BUTTON_PRESSED" and arg == tl.state[fam].sKey then
    tl.state[fam].mBeforeG = tl.state[fam].modus
  elseif tl.state[fam] and arg == tl.state[fam].sKey and  tl.state[fam].mBeforeG ~= tl.state[fam].modus then
    tl.mSync(tl.state[fam].modus,tl.state[fam].mBeforeG,fam)
    tl.state[fam].mBeforeG = tl.state[fam].modus
  end
end

function tl.launch() --compile and display stats on script startup
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

  tl.putNoLCD("\n\nG600 Profile '"..tl.profileName.."' powered by T-lib v"..tl.version.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n"..monum.." Monitor"..moplural.." configured ("..table.concat(moray,",")..")")
  if tl.outputLCD == 1 then tl.putLCD('')end
end

function tl.shutDown() --send shutdown message, abort all tasks, and set mode back to 1.
  tl.exitus = 1
  tl.quickGen(tl.assign.exit)
  tl.putNoLCD("Profile '"..tl.profileName.."' deactivated.")
  if tl.outputLCD == 1 then ClearLCD()end
  tl.multiAbort("")
  tl.molect(1,"all")
end

function tl.defTab(num,fam) --compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
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
    elseif tl.separateDeviceCycles==0 then
      for g=1, #tl.families do local cFam = tl.token(tl.families[g])
        tl.wipe(tl.state[cFam].unstable)
      end
    end

    for m,p in pairs(tl.TaskList) do
      if p.isTemp ~= nil then tl.TaskAbort(m) end
    end
  end
  tl.downs[keyNum] = tl.downs[keyNum] or {}
  local saver = tl.downs[keyNum]
  if currentDir == "down" then
    saver.name = keyNum
    saver.reName = tl.rename[keyNum] or keyNum
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
  if #tl.lastKeysDown > tl.historyDepth +1 then table.remove(tl.lastKeysDown,1) end
end

function tl.setArgsB(ev,ar,fam) --IDs for modifiers are set here
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

function tl.logEvent(ev,ar,fam)
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
  if tl.customNames == 1 then
    logKey = " ("..tl.rename[fam..ar]..")"
  end
  local downList = {}
  local upList = {}
  for m=1, #tl.lastKeysDown do local el = tl.lastKeysDown[m]
      downList[#downList+1]= el.name
  end

  local lKey = " , Last Keys: "..table.concat(downList,",").."(down) , "..table.concat(upList,",").."(up)"
  mem = ""
  if tl.logMemory == 1 then
    mem = ", Memory in use: "
    local memUnit = "kB"
    local memKb = math.ceil(collectgarbage("count"))
    if(memKb > 1024)then 
      memKb = string.format("%2f",(memKb/1024))
      memUnit = "mB"
    end
    mem = mem..memKb..memUnit
  end

  tl.putNoLCD("Key-Event = "..tl.state[fam].dir..", Current Key = "..fam..ar..logKey..", G-Shift = "..tl.state[fam].shift..", Mode = "..tl.pMod..tabs..mads..lKey..mem)
end

function tl.setArgsE(fam) --Make sure, no buttons that have been listed up are still listed as pressed down.
  tl.state[tl.token(fam)].conKey = 0
end

function tl.newSet(k,fam) --evaluate inputs to see what kind of bindings they have
  local bCode
  if tl.customNames == 1 then
    bCode = tl.rename[fam..k]
  else
    bCode = fam..k
  end

  local args = tl.assign.key[bCode]
  if type(k) ~= "number" or k == 0 or k > tl.state[fam].buttonCount then --can't press buttons that don't exist...
    error(" invalid mouse button")
  elseif args == nil then
    return
  elseif type(args) == "string" then
    tl.keyGen(k,fam,args,bCode)
  elseif type(args) == "table" then
    if tl.multiTab(args) == true then
      for num=1,#args do local coms = args[num]
        if #coms ~= 0 then
          tl.keyGen(k,fam,coms,bCode)
        end
      end
    else
      tl.keyGen(k,fam,args,bCode)
    end
  end
end

function tl.EventReceiver(event,arg,family) --set how to react to the differend kind of events
  if family == "" then family = "audio" end
  if string.sub(event,1,7) == "PROFILE" then family = "profile" end
  if event == "PROFILE_ACTIVATED" then
    EnablePrimaryMouseButtonEvents(1)
    tl.compileScreenCoordinates();
    tl.switchCustom()
    tl.funcRayD = tl.intersect(tl.defaultFuncs,tl.upDownFuncs)
    tl.funcRayU = tl.intersect(tl.upFuncs,tl.funcRayD)
    tl.funcRayM = tl.intersect(tl.macFuncs,tl.funcRayD)
    tl.assign = {}
    tl.prepKeys()
    tl.OnPollEventIni()
    tl.InitPolling()
    tl.setKeys()
    tl.toKey(tl.assign)
    tl.compileAssignments(tl.assign)
    tl.setDefaults(tl.assign.key)
    tl.inherit(tl.assign.key,1)
    if tl.showCompiled == 1 then
      tl.prettyTab(tl.assign.key,"Assignments:")
      if #tl.assign.start ~= 0 then
        tl.prettyTab(tl.assign.start,"Start Function:")
      end
      if #tl.assign.exit ~= 0 then
        tl.prettyTab(tl.assign.exit,"Exit Function:")
      end
      if #tl.assign.null ~= 0 then
        tl.prettyTab(tl.assign.null,"Null Storage:")
      end
    end
    tl.tablecrawl(tl.assign)
    tl.launch()
  elseif event == "PROFILE_DEACTIVATED" then
    tl.shutDown()
  elseif family ~= tl.PollFamily then
    local famName = tl.token(family)
    tl.setArgsB(event,arg,famName)
    tl.defTab(arg,famName)
    tl.newSet(arg,famName)
    if tl.logEvents == 1 then tl.logEvent(event,arg,famName)end
    tl.untempMode(famName)
    tl.setArgsE(event,famName)
    if arg ~= tl.state[famName].sKey then
      tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
    end
  end
end