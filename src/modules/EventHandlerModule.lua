local tl = ...---@type MainLibObject
local ceil, IsKeyLockOn, IsModifierPressed, format, concat, remove, pairs, ClearLCD, ClearLog,collectgarbage,gsub,insert  = math.ceil, IsKeyLockOn, IsModifierPressed, string.format, table.concat, table.remove, pairs,  ClearLCD, ClearLog, collectgarbage,string.gsub,table.insert
local ProfileDefinition = tl:classImport("ProfileDefinition")---@type ProfileDefinition
-->>>> Functions that directly listen to events =================================================================================================
---@class EventHandlerModule
local EventHandler = tl.baseClass:new()
EventHandler.pressed = false
---compile and display stats on script startup
local function _launchFramework()
  if tl.activeProfile.config.outputLCD then
    tl:put("")
  end
  if tl.activeProfile.bindings.start then tl.activeProfile.bindings.start:run() end 
  local defnum = 0
  local gennum = 0
  local monum = #tl.activeProfile.resolutions
  local moray = {}
  local moplural = ""
  local lintIndicator = tl.activeProfile.config.enableLinting and "\nLinting Enabled" or ""
  if monum > 1 then moplural = "s" end
  for k, _ in pairs(tl.activeProfile.assign.key or {}) do
    if k ~= "pID" then defnum = defnum + 1 end
  end
  for _, _ in pairs(tl.activeProfile.macroIndex) do gennum = gennum + 1 end
  for g = 1, #tl.activeProfile.resolutions do local mon = tl.activeProfile.resolutions[g]
    moray[#moray + 1] = mon.w .. "x" .. mon.h
  end
  tl.logitech:putNoLCD("\nG600 Profile '" ..tl.activeProfile.name .."' powered by T-lib v" ..tl.scriptStates.version .." successfully launched.\n" ..
  tl.scriptStates.locationIndicator .."\nCurrent stats:\nButtons Assigned: " ..defnum .."\nNamed Sequences: " ..tl.scriptStates.namedTables ..
  "\nGenerically Identified Tables: " ..gennum .."\n" ..monum .." Monitor" ..moplural .." configured (" ..concat(moray, ",") .. ")" .. lintIndicator)
  for _, v in pairs(tl.lint.lintErrors) do tl.logitech:putNoLCD("\n" .. v) end
  for _, v in pairs(tl.lint.configLintErrors) do tl.logitech:putNoLCD("\n" .. v) end
end

---send shutdown message, abort all tasks, and set mode back to 1.
local function _shutDown()
  tl.scriptStates.exitingScript = true
  if tl.activeProfile.assign.exit and #tl.assign.exit ~= 0 then
  if tl.activeProfile.bindings.exit then tl.activeProfile.bindings.start:run() end 
end
  tl.logitech:putNoLCD("Profile '" .. tl.activeProfile.name .. "' deactivated.")
  if tl.activeProfile.config.outputLCD then ClearLCD() end
  if tl.activeProfile.config.clearLog then ClearLog() end
  tl.coroutines:multiAbort("")
  tl.logitech:modeWrapper(1, nil, "all", true)
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num number
---@param fam string
---@return Event
local function _collectKeyStats(num, fam)
  local event = {family = fam, keyNum = num} ---@type Event
  if num == tl.activeProfile.deviceState[fam].sKey or not tl.eventHandler.pressed then return end
  if tl.activeProfile.config.logLevel ~= 0 and #tl.keyStates.lastKeysDown ~= 0 and
  ((tl.activeProfile.config.logLevel > 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == nil) or
  (tl.activeProfile.config.logLevel == 2 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == 0))
  then tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown] = nil end

  local currentDir = tl.activeProfile.deviceState[fam].dir
  local keyNum = fam .. num
  event.keyName = keyNum
  if #tl.keyStates.lastKeysDown ~= 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].name ~= keyNum then
    if tl.keyStates.lastKeysDown.family == fam then
      tl.helperUtils.wipe(tl.activeProfile.deviceState[fam].unstable)
    elseif not tl.activeProfile.config.separateDeviceCycles then
      for g = 1, #tl.stringPresets.families do local cFam = tl.str:token(tl.stringPresets.families[g])
        tl.helperUtils.wipe(tl.activeProfile.deviceState[cFam].unstable)
      end
    end
    for m, p in pairs(tl.coroutines.taskList) do if p.isTemp ~= nil then tl.coroutines:taskAbort(m) end end
  end
  tl.keyStates.keysDown[keyNum] = tl.keyStates.keysDown[keyNum] or {}
  local saver = tl.keyStates.keysDown[keyNum]
  if currentDir == "down" then
    saver.name = keyNum
    saver.reName = keyNum
    saver.shift = tl.activeProfile.deviceState[fam].shift
    saver.mode = tl.activeProfile.deviceState[fam].modus
    saver.modKeys = tl.scriptStates.mods
    saver.family = fam
  elseif currentDir == "up" then
    saver.shiftUp = tl.activeProfile.deviceState[fam].shift
    saver.modeUp = tl.activeProfile.deviceState[fam].modus
    saver.modKeysUp = tl.scriptStates.mods
    tl.keyStates.keysDown[keyNum] = nil
  end
  event.direction = currentDir
  event.mode = saver.mode or saver.modeUp
  event.modifiers = saver.modKeys or saver.modKeysUp
  event.shift = saver.shift or saver.shiftUp
  tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown + 1] = saver
  if #tl.keyStates.lastKeysDown > tl.activeProfile.config.historyDepth + 1 then
    remove(tl.keyStates.lastKeysDown, 1)
  end
  return event
end

---IDs for modifiers are set here
---@param ev string
---@param ar string
---@param fam string
local function _setModifiers(ev, ar, fam)
  local famto = tl.str:token(fam)
  tl.scriptStates.mods = ""
  tl.activeProfile.deviceState[famto].conKey = 0
  local morail = {
    { "ralt", "ra" },
    { "lalt", "la" },
    { "alt", "ga" },
    { "rshift", "rs" },
    { "lshift", "ls" },
    { "shift", "gs" },
    { "rctrl", "rc" },
    { "lctrl", "lc" },
    { "ctrl", "gc" }
  }

  local lorail = {
    { "scrolllock", "sl" },
    { "capslock", "cl" },
    { "numlock", "nl" }
  }

  for i = 1, #morail do local obj = morail[i]
    if IsModifierPressed(obj[1]) then tl.scriptStates.mods = tl.scriptStates.mods .. obj[2] end
  end

  for f = 1, #lorail do local obj = lorail[f]
    if IsKeyLockOn(obj[1]) then tl.scriptStates.mods = tl.scriptStates.mods .. obj[2] end
  end

  if ev == "MOUSE_BUTTON_PRESSED" then
    tl.activeProfile.deviceState[famto].dir = "down"
    tl.eventHandler.pressed = true
  elseif ev == "MOUSE_BUTTON_RELEASED" then
    tl.activeProfile.deviceState[famto].dir = "up"
  end

  if ar == tl.activeProfile.deviceState[famto].sKey then
    tl.scriptStates.currentButton = 0
    if tl.activeProfile.deviceState[famto].dir == "down" then tl.activeProfile.deviceState[famto].shift = 1
    elseif tl.activeProfile.deviceState[famto].dir == "up" then tl.activeProfile.deviceState[fam].shift = 0 end
  else tl.scriptStates.currentButton = ar end
end

---Logs event properties to the console
---@param ar number
---@param fam string
local function _logEvent(ar, fam)
  local mads, tabs, mem
  if not tl.scriptStates.mods or #tl.scriptStates.mods == 0 then mads = ""
  else mads = " , modifiers active: " .. tl.scriptStates.mods end
  tabs = ""
  for k, _ in pairs(tl.keyStates.keysDown) do
    if tabs == "" then tabs = " , Keys Down = " .. k
    else tabs = tabs .. ", " .. k end
  end
  local logKey = tl.activeProfile.config.customNames and " (" .. (tl.activeProfile.config.rename[fam .. ar] or fam .. ar) .. ")" or ""
  local downList = {}
  local upList = {}
  for m = 1, #tl.keyStates.lastKeysDown do local el = tl.keyStates.lastKeysDown[m]
    downList[#downList + 1] = el.name
  end

  local lKey = " , Last Keys: " .. concat(downList, ",") .. "(down) , " .. concat(upList, ",") .. "(up)"
  mem = ""
  if tl.activeProfile.config.logMemory then
    mem = ", Memory in use: "
    local memUnit = "kB"
    local memKb = ceil(collectgarbage("count"))
    if (memKb > 1024) then
      memKb = format("%2f", (memKb / 1024))
      memUnit = "mB"
    end
    mem = mem .. memKb .. memUnit
  end
  tl.logitech:putNoLCD("Key-Event = " ..tl.activeProfile.deviceState[fam].dir ..", Current Key = " ..fam ..ar ..logKey ..", G-Shift = "
  ..tl.activeProfile.deviceState[fam].shift ..", Mode = " .. tl.activeProfile.deviceState[fam].modus .. tabs .. mads .. lKey .. mem)
end

local function _getPath()
  local pathTable = {
    tl.paths.extPaths[tl.paths.fileLocation] or "",
    gsub(tl.paths.profileName, "%.lua$", "") .. ".lua"
  }
  if tl.paths.childPaths then insert(pathTable, 1, tl.paths.path) end
  local finalPath = concat(pathTable, "/")
  if tl.paths.fileLocation ~= 0 then
    tl.scriptStates.locationIndicator = "Running on external configs [" .. finalPath .. "]"
    return finalPath
  elseif tl.paths.fileLocation ~= 0 then
    tl.scriptStates.locationIndicator = "Running on internal configs, external file missing or broken. [" .. finalPath .. "]"
  end
  return nil
end


---set how to react to the differend kind of events
---@param event string
---@param arg number
---@param family string
local function _EventReceiver(event, arg, family)
  if family == "" then
    if event == "PROFILE_ACTIVATED" then
      ClearLog()
      if #tl.scriptStates.errors ~= 0 then return end
      ---@type AssignmentTable
      EnablePrimaryMouseButtonEvents(1)
      local macroList = {}
      local path = _getPath()
      local profileName = path or tl.paths.profileName
      tl.keys:constructKeyTable()
      tl.activeProfile = ProfileDefinition:new(path,profileName,nil,true)
      tl.polling:initPolling()
      tl.polling:onPollEventIni()
      if tl.activeProfile.config.showCompiled then
        for k in pairs(tl.macroImports) do macroList[#macroList+1] = k end
        tl.tbl:prettyTab(macroList, "Used Macro Classes:")
        tl:put("Assignments:\n\n"..tl.activeProfile:buildTree())
        if tl.activeProfile.assign.start  then tl.tbl:prettyTab(tl.activeProfile.assign.start, "Start Function:") end
        if tl.activeProfile.assign.exit  then tl.tbl:prettyTab(tl.activeProfile.assign.exit, "Exit Function:") end
        if tl.activeProfile.assign.library  then tl.tbl:prettyTab(tl.activeProfile.assign.library, "Macro Library:") end
      end
      _launchFramework()
      collectgarbage()
    elseif event == "PROFILE_DEACTIVATED" then _shutDown() end
    elseif family ~= tl.activeProfile.config.pollFamily then
      local famName = tl.str:token(family)
      _setModifiers(event, arg, famName)
      local currentEvent = _collectKeyStats(arg, famName)
      local macroID = tl.activeProfile.bindings[(currentEvent or {}).keyName]
      if macroID then tl.activeProfile.macroIndex[macroID]:run(currentEvent) end
      if tl.activeProfile.config.logEvents then _logEvent(arg, famName) end
      tl.logitech:undoTempMode(famName)
      tl.activeProfile.deviceState[famName].conKey = 0
      if arg ~= tl.activeProfile.deviceState[famName].sKey then
        tl.scriptStates.keyCount = tl.scriptStates.keyCount + 1 --counting keys for temporary cycles
        if tl.scriptStates.keyCount % 50 == 0 then collectgarbage() end
    end
  end
end

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event string
---@param arg number
---@param family string
function OnEvent(event, arg, family)
  if tl.activeProfile and family == tl.activeProfile.config.pollFamily then
    tl.polling:poll(event, arg)
  else
    _EventReceiver(event, arg, family)
    if tl.activeProfile then
      local fam = tl.str:token(family)
      if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == tl.activeProfile.deviceState[fam].sKey then
        tl.activeProfile.deviceState[fam].mBeforeG = tl.activeProfile.deviceState[fam].modus
      elseif
      tl.activeProfile.deviceState[fam] and arg == tl.activeProfile.deviceState[fam].sKey and
      tl.activeProfile.deviceState[fam].mBeforeG ~= tl.activeProfile.deviceState[fam].modus
      then
        tl.logitech:syncModes(tl.activeProfile.deviceState[fam].modus, tl.activeProfile.deviceState[fam].mBeforeG, fam)
        tl.activeProfile.deviceState[fam].mBeforeG = tl.activeProfile.deviceState[fam].modus
      end
    end
  end
  tl.polling:doTasks()
end
local OnEvent = OnEvent

return EventHandler