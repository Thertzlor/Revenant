---@type MainLibObject
local tl = ...
local ceil, IsKeyLockOn, IsModifierPressed, format ,concat , remove, pairs, ClearLCD,ClearLog =
math.ceil, IsKeyLockOn, IsModifierPressed, string.format, table.concat, table.remove,pairs, tl.config.hubMode and tl.dummy or ClearLCD,ClearLog
-->>>> Functions that directly listen to events =================================================================================================

---compile and display stats on script startup
local function _launch()
  tl.quickGen(tl.assign.start)
  local defnum = 0
  local gennum = 0
  local monum = #tl.config.resolutions
  local moray = {}
  local moplural = ""
  local lintIndicator = tl.config.enableLinting and "\nLinting Enabled" or ""
  if monum > 1 then moplural = "s" end
  for k,_ in pairs(tl.assign.key) do if k ~= "pID" then defnum = defnum+1 end end
  for _,_ in pairs(tl.macroStats) do gennum = gennum+1  end
  for g=1, #tl.config.resolutions do local mon = tl.config.resolutions[g]
    moray[#moray+1] = mon.w.."x"..mon.h
  end
  tl.putNoLCD("\n\nG600 Profile '"..tl.config.profileName.."' powered by T-lib v"..tl.version.." succesfully launched.\n"..tl.locationIndicator.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..tl.namedTables.."\nGenerically Identified Tables: "..gennum.."\n"..monum.." Monitor"..moplural.." configured ("..concat(moray,",")..")"..lintIndicator)
  if tl.config.outputLCD then tl.putLCD('')end
end

---send shutdown message, abort all tasks, and set mode back to 1.
local function _shutDown()
  tl.exitingScript = 1
  if #tl.assign.exit ~= 0 then tl.quickGen(tl.assign.exit) end
  tl.putNoLCD("Profile '"..tl.config.profileName.."' deactivated.")
  if tl.config.outputLCD then ClearLCD()end
  if tl.config.clearLog then ClearLog()end
  tl.multiAbort("")
  tl.modeWrapper(1,nil,"all",true)
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num number
---@param fam string
local function _defTab(num,fam)
  if num == tl.state[fam].sKey or not tl.pressed then return end
  if tl.config.logLevel ~= 0 and #tl.lastKeysDown ~= 0 and
  ((tl.config.logLevel > 0 and tl.lastKeysDown[#tl.lastKeysDown].played == nil) or
  (tl.config.logLevel == 2 and tl.lastKeysDown[#tl.lastKeysDown].played == 0)) then
    tl.lastKeysDown[#tl.lastKeysDown] = nil
  end
  local currentDir = tl.state[fam].dir
  local keyNum = fam..num
  if #tl.lastKeysDown ~= 0 and tl.lastKeysDown[#tl.lastKeysDown].name ~= keyNum then
    if tl.lastKeysDown.family == fam then
      tl.wipe(tl.state[fam].unstable)
    elseif not tl.config.separateDeviceCycles then
      for g=1, #tl.families do local cFam = tl.token(tl.families[g])
        tl.wipe(tl.state[cFam].unstable)
      end
    end
    for m,p in pairs(tl.taskList) do
      if p.isTemp ~= nil then tl.taskAbort(m) end
    end
  end
  tl.keysDown[keyNum] = tl.keysDown[keyNum] or {}
  local saver = tl.keysDown[keyNum]
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
    tl.keysDown[keyNum] = nil
  end
  tl.lastKeysDown[#tl.lastKeysDown+1] = saver
  if #tl.lastKeysDown > tl.config.historyDepth +1 then remove(tl.lastKeysDown,1) end
end

---IDs for modifiers are set here
---@param ev string
---@param ar string
---@param fam string
local function _setArgsB(ev,ar,fam)
  local famto = tl.token(fam)
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
    tl.pressed = true
  elseif ev == "MOUSE_BUTTON_RELEASED" then
    tl.state[famto].dir = "up"
  end

  if ar == tl.state[famto].sKey then
    tl.currentButton = 0
    if tl.state[famto].dir == "down" then
      tl.state[famto].shift=1
    elseif tl.state[famto].dir == "up" then
      tl.state[fam].shift=0
    end
  else
    tl.currentButton = ar
  end
end

---Logs event properties to the console
---@param ar number
---@param fam string
local function _logEvent(ar,fam)
  local mads,tabs,mem
  if not tl.mods or #tl.mods == 0 then
  mads=""
  else
    mads = " , modifiers active: "..tl.mods
  end
  tabs = ""
  for k,_ in pairs(tl.keysDown) do
    if tabs == "" then
      tabs = " , Keys Down = "..k
    else
      tabs = tabs..", "..k
    end
  end
  local logKey = tl.config.customNames and " ("..(tl.config.rename[fam..ar] or fam..ar)..")" or ""
  local downList = {}
  local upList = {}
  for m=1, #tl.lastKeysDown do local el = tl.lastKeysDown[m]
      downList[#downList+1]= el.name
  end

  local lKey = " , Last Keys: "..concat(downList,",").."(down) , "..concat(upList,",").."(up)"
  mem = ""
  if tl.config.logMemory then
    mem = ", Memory in use: "
    local memUnit = "kB"
    local memKb = ceil(collectgarbage("count"))
    if(memKb > 1024)then
      memKb = format("%2f",(memKb/1024))
      memUnit = "mB"
    end
    mem = mem..memKb..memUnit
  end
  tl.putNoLCD("Key-Event = "..tl.state[fam].dir..", Current Key = "..fam..ar..logKey..", G-Shift = "..tl.state[fam].shift..", Mode = "..tl.state[fam].modus ..tabs..mads..lKey..mem)
end

---set how to react to the differend kind of events
---@param event string
---@param arg number
---@param family string
local function _EventReceiver(event,arg,family)
  if family == "" then
    if event == "PROFILE_ACTIVATED" then
      tl.assign = {}
      EnablePrimaryMouseButtonEvents(1)
      tl.funcRayD = tl.intersect(tl.defaultFuncs,tl.upDownFuncs)
      tl.constructKeyTable()
      tl.buildBindings()
      tl.onPollEventIni()
      tl.initPolling()
      if tl.config.showCompiled then
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
      for _,v in pairs(tl.configLintErrors) do
        tl.put("\n"..v)
      end
      _launch()
    elseif event == "PROFILE_DEACTIVATED" then
      _shutDown()
    end
  elseif family ~= tl.config.pollFamily then
    local famName = tl.token(family)
    _setArgsB(event,arg,famName)
    _defTab(arg,famName)
    tl.keyGen(arg,famName)
    if tl.config.logEvents then _logEvent(arg,famName)end
    tl.untempMode(famName)
    tl.state[famName].conKey = 0
    if arg ~= tl.state[famName].sKey then
      tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
    end
  end
end

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event string
---@param arg number
---@param family string
function OnEvent(event, arg, family)
  if family ==  tl.config.pollFamily then
    tl.poll(event, arg)
  else
    _EventReceiver(event,arg,family)
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