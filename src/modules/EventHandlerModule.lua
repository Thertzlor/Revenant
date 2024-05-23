local rv = ... ---@type Revenant
local ProfileDefinition = rv.importer:classImport("ProfileDefinition")
local ceil, IsKeyLockOn, IsModifierPressed, concat, pairs, ClearLCD, ClearLog, collectgarbage, gsub, insert, format, sub, type, remove, next = math.ceil, IsKeyLockOn, IsModifierPressed, table.concat, pairs, ClearLCD, ClearLog, collectgarbage, string.gsub, table.insert, string.format, string.sub, type, table.remove, next

--[[=============================================================]] --
---@alias HardwareFamily "mouse"|"kb"|"lhc" #all family strings supported by LGS
---@alias FamilyToken "m"|"k"|"l" #all family token strings supported by Revenant
--[[=============================================================]] --
---@class Event #An event received by LGS or simulated by a macro
---@field keyNum integer #The numeric code of the key
---@field keyName? string #the name of the key
---@field family FamilyToken #The family of the device this key belongs to
---@field modifiers? string|table|number #Modifiers pressed while this event was triggered
---@field virtualType? integer #Shows if the event is virtual and how it was virtualized
---@field mode? string|integer #The mode that was active when the event was triggered
---@field link? boolean #Is this Event linked to another event
---@field shift? integer #shift state active when this event was triggered
---@field direction?  string #Key direction of this event
---@field originator? string #if the event is virtual, the id of the macro that spawned it
--[[=============================================================]] --
---@class EventInfo #compiled stats about an event for testing and logging
---@field name string #designation of the button
---@field shift integer #g-shift state when the button was pressed
---@field shiftUp integer #g-shift state when the button was released
---@field mode integer #ctive mode when the button was pressed
---@field modeUp integer #active mode when the button was released
---@field modKeys table<string,true> #modifier keys active when the button was pressed
---@field modKeysUp table<string,true> #modifier keys active when the button was released
---@field family HardwareFamily #Device family the event originated from
---@field familyToken string #token of the device family the event originated from
--[[=============================================================]] --
---Functions that directly listen to events
---@class EventHandlerModule
local EventHandler = rv.baseClass:new()
EventHandler.pressed = false
local firstLaunch = true

---Starts up the framework after succesful profile launch, including device and screen settings
---@return boolean #true if the launch was successful and without errors
---@async
local function _launchFramework()
   local config = rv.profile.config
   if config.outputLCD then rv:put("") end
   if config.enableLinting then rv.lint:configLinter(config) end -- making sure the general configurations are valid
   local keyNo = 0 ---number of assigned keys
   local macroNo = 0 ---number of defined macros
   local screenNo = #rv.mouseMonitorUtils.screens
   local moniRay = {} ---@type string[]
   local pluralize = "" ---plural string for monitors
   local lintIndicator = config.enableLinting and "\nLinting Enabled" or "" ---visual indication if linting is enabled
   if screenNo > 1 then pluralize = "s" end
   local devices = {} ---@type string[][]
   local deviceString = ""
   for _, v in pairs(rv.profile.deviceState) do if v.name then devices[#devices + 1] = {v.name, v.family} end end
   if #devices ~= 0 then deviceString = "\nDevices: " end
   for i = 1, #devices do
      local dev = devices[i]
      deviceString = deviceString .. (i == 1 and "" or ", ") .. dev[1] .. " (" .. dev[2] .. ")" -- outputting devices to string
   end -- compiling profile stats for output
   for _ in pairs(rv.profile.assign.key or {}) do keyNo = keyNo + 1 end
   for _ in pairs(rv.profile.macroIndex) do macroNo = macroNo + 1 end
   for g = 1, #rv.mouseMonitorUtils.screens do
      local monitor = rv.mouseMonitorUtils.screens[g]
      moniRay[#moniRay + 1] = monitor.w .. "x" .. monitor.h -- outputting defined monitors
   end
   if config.useHIDKeys then rv.keys:useHID() end
   rv:put("\nG600 Profile '" .. rv.profile.name .. "' powered by Revenant v" .. rv.states.scriptStates.version .. " successfully launched.\n" .. rv.states.scriptStates.locationIndicator .. "\nCurrent stats:\nButtons Assigned: " .. keyNo .. "\nNamed Sequences: " .. 0 .. "\nGenerically Identified Tables: " .. macroNo .. "\n" .. screenNo .. " Monitor" .. pluralize .. " configured (" .. concat(moniRay, ",") .. ")" .. lintIndicator .. deviceString) -- the final log output of profile stats
   local configLint = rv.lint.configLintErrors ---config lint errors
   for i = 1, #rv.lint.lintErrors do rv:put("\n" .. rv.lint.lintErrors[i]) end -- logging lint errors
   for i = 1, #configLint do rv:put("\n" .. configLint[i]) end -- logging lint errors of the configs
   if #configLint ~= 0 and config.abortOnLintError then return false end -- aborting to be safe
   rv.lcd:parseToTextDisplay(config.description or "", "_profileDefault", 1, nil, false, true)
   return true
end

---send shutdown message, abort all tasks, and set mode back to 1.
---@async
local function _shutDown()
   rv.states.scriptStates.exitingScript = true -- making sure every part of the script knows we're shutting down
   if rv.profile.bindings.exit then rv.profile.macroIndex[rv.profile.bindings.exit]:run({virtualType = 4, keyNum = 0, family = "m"}) end -- execute exit binding
   rv:put("Profile '" .. rv.profile.name .. "' deactivated.") -- output ending log message
   if rv.profile.config.outputLCD then ClearLCD() end -- clearing lcd and log
   if rv.profile.config.clearLog then ClearLog() end
   rv.threading:multiAbort("") -- aborting all tasks
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num integer #the number of the button
---@param fam FamilyToken #the family of the button
---@return Event? #compiled standardized Event
---@async
local function _collectKeyStats(num, fam)
   local event = {family = fam, keyNum = num} ---@type Event
   local config = rv.profile.config
   if num == rv.profile.deviceState[fam].sKey or not rv.eventHandler.pressed then return end -- g-shift keys do not trigger events
   if config.logPrimaryButtonState and not config.primaryButtons then for i = 1, 2 do rv.states.keyStates.primaryButtonsDown["m" .. i] = IsMouseButtonPressed(i + ((i == 1 and 1 or 2) - 1)) end end -- checking primary buttons. for some reason right click is 3.

   local currentDir = rv.profile.deviceState[fam].dir ---event direction
   local keyNum = fam .. num ---@type string #combined button name
   event.keyName = keyNum
   if #rv.states.keyStates.lastKeysDown ~= 0 and rv.states.keyStates.lastKeysDown[#rv.states.keyStates.lastKeysDown].name ~= keyNum then
      local index = rv.profile.macroIndex
      if rv.profile.hasUnstableCycles then
         local cycleDex = rv.profile.typedIndex.__unstableCycles -- processing cycles
         if rv.states.keyStates.lastKeysDown.family == fam then
            for i = 1, #cycleDex do
               local mac = index[cycleDex[i]] -- resetting cycles set to auto-cancel
               if mac.sourceDevice.token == fam then rv.profile.macroStates[cycleDex[i]].position = nil end
            end
         elseif not config.separateDeviceCycles then -- same thing but globally
            for i = 1, #cycleDex do rv.profile.macroStates[cycleDex[i]].position = nil end
         end
      end
      if rv.profile.hasUnstableSequences then
         local seqDex = rv.profile.typedIndex.__unstableSequences -- processing cycles
         if rv.states.keyStates.lastKeysDown.family == fam then
            for i = 1, #seqDex do
               local mac = index[seqDex[i]] -- resetting cycles set to auto-cancel
               if mac.sourceDevice.token == fam then mac:control() end
            end
         elseif not config.separateDeviceSequences then -- same thing but globally
            for i = 1, #seqDex do index[seqDex[i]]:control() end
         end
      end
      rv.threading:tempCancel() -- canceling cancellable tasks
   end
   rv.states.keyStates.keysDown[keyNum] = rv.states.keyStates.keysDown[keyNum] or {} -- adding key to pressed keys
   local savedStats = rv.states.keyStates.keysDown[keyNum]
   local shift = (config.globalGShift and rv.profile.globalState.shift) or rv.profile.deviceState[fam].shift -- g-shift state
   if currentDir == "down" then -- collection key press info
      savedStats.name = keyNum
      savedStats.shift = shift
      savedStats.mode = rv.profile.deviceState[fam].modus
      savedStats.family = rv.logitech.unlogiToken[fam]
      savedStats.familyToken = fam
      savedStats.modKeys = rv.states.scriptStates.mods
      rv.states.keyStates.lastKeysDown[#rv.states.keyStates.lastKeysDown + 1] = savedStats
   elseif currentDir == "up" then -- collecting key release info
      savedStats.shiftUp = shift
      savedStats.modeUp = rv.profile.deviceState[fam].modus
      savedStats.modKeysUp = rv.states.scriptStates.mods
      rv.states.keyStates.keysDown[keyNum] = nil
   end -- collecting neutral info
   event.direction = currentDir
   event.mode = savedStats.mode or savedStats.modeUp
   event.modifiers = savedStats.modKeys or savedStats.modKeysUp
   event.shift = savedStats.shift or savedStats.shiftUp
   if #rv.states.keyStates.lastKeysDown > config.historyDepth + 1 then remove(rv.states.keyStates.lastKeysDown, 1) end -- trimming history array
   return event
end

---IDs for modifiers are set here
---@param ev EventType #Logitech Event name
---@param ar number #key number
---@param fam FamilyToken #family name
local function _setModifiers(ev, ar, fam)
   rv.states.scriptStates.mods = {}
   rv.profile.deviceState[fam].blockedKey = 0 -- resetting key block
   local modShorts = { ---shortcuts for modifiers used in mod string
      {"rshift", "rs"}, {"lshift", "ls"}, {"rctrl", "rc"}, {"lctrl", "lc"}, {"ralt", "ra"}, {"lalt", "la"}
      -- { "ctrl", "gc" }, --no longer needed, saves 3 function calls
      -- { "shift", "gs" },
      -- { "alt", "ga" }
   }

   local locks = { ---shortcuts for lock keys used in mod string
      {"scrolllock", "sl"}, {"capslock", "cl"}, {"numlock", "nl"}
   }

   for i = 1, #modShorts do
      local obj = modShorts[i] -- using LGS checks to compile modifiers
      if IsModifierPressed(obj[1]) then
         rv.states.scriptStates.mods[obj[2]] = true
         rv.states.scriptStates.mods["g" .. sub(obj[2], 2, 2)] = true
      end
   end

   for f = 1, #locks do
      local obj = locks[f] -- using LGS checks to compile locks
      if IsKeyLockOn(obj[1]) then rv.states.scriptStates.mods[obj[2]] = true end
   end

   if ev == "MOUSE_BUTTON_PRESSED" then -- updating device state
      rv.profile.deviceState[fam].dir = "down"
      rv.eventHandler.pressed = true
   elseif ev == "MOUSE_BUTTON_RELEASED" then
      rv.profile.deviceState[fam].dir = "up"
   end

   if ar == rv.profile.deviceState[fam].sKey then -- special treatment for the g-shift key
      rv.states.scriptStates.currentButton = 0
      if rv.profile.deviceState[fam].dir == "down" then
         ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift = 1
      elseif rv.profile.deviceState[fam].dir == "up" then
         ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift = 0
      end
   else
      rv.states.scriptStates.currentButton = ar
   end
end

---Logs event properties to the console
---@param ar number #the number of the key
---@param fam FamilyToken #the device the key belongs to
local function _logEvent(ar, fam)
   local activeModifiers, keys, memory ---@type string, string, string #collection arrays
   if not rv.states.scriptStates.mods or not next(rv.states.scriptStates.mods) then
      activeModifiers = "" -- there are no modes on the current profile
   else
      activeModifiers = " , modifiers active: " .. concat(rv.tbl:getKeys(rv.states.scriptStates.mods), "")
   end
   keys = ""
   for k, _ in pairs(rv.states.keyStates.keysDown) do -- string for pressed keys
      if keys == "" then
         keys = " , Keys Down = " .. k
      else
         keys = keys .. ", " .. k
      end
   end
   local logKey = " (" .. (rv.profile.config.rename[fam .. ar] or fam .. ar) .. ")" ---key name
   local downList = {} ---@type string[] #keys pressed with this event
   local upList = {} ---@type string[] #keys released with this event
   for m = 1, #rv.states.keyStates.lastKeysDown do
      local el = rv.states.keyStates.lastKeysDown[m] -- compiling list
      downList[#downList + 1] = el.name
   end

   local lastKey = " , Last Keys: " .. concat(downList, ",") .. "(down) , " .. concat(upList, ",") .. "(up)" ---string for key history
   memory = ""
   if rv.profile.config.logMemory then -- compiling memory usage stats
      memory = ", Memory in use: "
      local memUnit = "kB"
      local memKb = ceil(collectgarbage("count")) ---@type integer|string
      if (memKb > 1024) then
         memKb = format("%2f", (memKb / 1024)) -- formatting
         memUnit = "mB"
      end
      memory = memory .. memKb .. memUnit
   end
   rv:put("Key-Event = " .. rv.profile.deviceState[fam].dir .. ", Current Key = " .. fam .. ar .. logKey .. ", G-Shift = " .. ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift .. ", Mode = " .. rv.profile.deviceState[fam].modus .. keys .. activeModifiers .. lastKey .. memory) -- final output
end

---Get the path of an external profile file
---@return string? #path of the profile file, if there is one
local function _getPath()
   local profilePath = rv.paths.profilePath ---paths read from settings
   local pathTable = {((type(profilePath) == "string" and profilePath)) or "", gsub(rv.paths.profileName, "%.lua$", "") .. ".lua"}
   if (not rv.paths.absoluteProfilePaths) then insert(pathTable, 1, rv.paths.path) end -- handling absolute and relative paths
   local finalPath = concat(pathTable, "/")
   if rv.paths.externalProfile then -- file is running on external profile
      rv.states.scriptStates.locationIndicator = "Running on external configs [" .. finalPath .. "]" -- setting indicator
      return finalPath
   elseif rv.paths.externalProfile then -- this only happens if there should be a file but there isn't
      rv.states.scriptStates.locationIndicator = "Running on internal configs, external file missing or broken. [" .. finalPath .. "]"
   end
   return nil
end

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event EventType #The type of LGS event we are receiving
---@param arg integer #the number of the key
---@param family HardwareFamily #the device on which the key was pressed
---@async
local function _OnEventHook(event, arg, family)
   if (rv.profile.config.pollMKeysOnly and (event == "M_Pressed" or event == "M_Released")) or family == rv.profile.config.pollFamily then
      rv.threading:poll(event, arg) -- separating poll events from the rest
   elseif sub(event, 1, 2) ~= "M_" then
      if rv.profile.config.enableDebounce and rv.debouncer:debounceEvent(family, arg, event) then return end -- applying debounce if enabled
      EventHandler:EventReceiver(event, arg, family) -- macros are triggered here
      local state = rv.profile.deviceState
      local fam = rv.str:token(family) --[[@as FamilyToken]] or ""
      if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == state[fam].sKey then
         state[fam].mBeforeG = state[fam].modus ---setting g-shift specific mode state
      elseif state[fam] and arg == state[fam].sKey and state[fam].mBeforeG ~= state[fam].modus then
         rv.logitech:syncModes(state[fam].modus, state[fam].mBeforeG, fam) ---syncing modes, if g-shift messed them up
         state[fam].mBeforeG = state[fam].modus
      end
   end
   rv.threading:doTasks() ---we'll trigger a task continuation even when we're not polling, just because we can
end

---general launch function, called on activation
---@async
local function _launcher()
   if not firstLaunch then return end -- Revenant is already launched, abort.
   firstLaunch = false
   if #rv.states.scriptStates.errors ~= 0 then return end -- not bothering if there are already errors
   local macroList = {} ---@type string[]
   local path = _getPath()
   local profileName = path or rv.paths.profileName
   rv.keys:constructKeyTable() -- setting up keys
   rv.profile = ProfileDefinition:new(path, profileName, nil, true) -- initializing the profile we will be using.
   rv.profile:deLag()
   rv.keys:loadKeyboard(rv.profile.config.keyboardLocale) -- loading the keyboard based on profile configs
   local config = rv.profile.config
   if config.clearLog then ClearLog() end -- resetting logs
   if config.monitors then rv.mouseMonitorUtils:compileScreenCoordinates(config.monitors) end -- setting up all monitors
   rv.profile:parseBindings() -- compiling all macros
   if #rv.states.scriptStates.errors ~= 0 then rv:crash("Failed loading Revenant, profile could not be compiled. Errors:") end -- crash if the profile is broken
   if config.showCompiled then -- outputting a tree representation of the profile
      for k in pairs(rv.importer.macroImports) do macroList[#macroList + 1] = k end
      rv.tbl:prettyTab(macroList, "Used Macro Classes:")
      rv:put("Assignments:\n\n" .. rv.profile:buildTree())
   end

   EnablePrimaryMouseButtonEvents(rv.profile.config.primaryButtons)
   -- if rv.profile.config.primaryButtons and IsMouseButtonPressed(1) then
   --     ReleaseMouseButton(1)

   -- end
   if _launchFramework() then -- initializing the rest of the framework now that we have the profile
      rv.logitech:initModes() -- setting up all modes and threads and so on
      rv.threading:initLagSettings()
      rv.threading:initPolling()
      rv.threading:onPollEventIni()
      if config.enableDebounce then rv.debouncer:setupDebounce() end
      rv.threading:initRandom()
      rv.mouseMonitorUtils:initLagSettings()
      OnEvent = _OnEventHook -- redirecting events to the actual event receiver since macros are ready
      local hook = rv.profile.hooks.onInitHook
      local hookAsync = rv.profile.hooks.onInitHookAsync
      if hook then hook() end -- executing initiation hooks
      if hookAsync then rv.threading:taskRun(nil, nil, nil, hookAsync) end
      if rv.profile.bindings.start then rv.profile.macroIndex[rv.profile.bindings.start]:run({virtualType = 4, keyNum = 0, family = "m"}) end -- triggering start macro
   end
   if rv.importer.macroImports.DocToggleMacro then -- we don't parse documentation if we know that the profile can't activate doc mode
      rv:put("Parsing Documentation.\n")
      for _, v in pairs(rv.profile.macroIndex) do v:parseDocs() end
   else
      rv:put("")
   end
   for _, v in pairs(rv.profile.deviceState) do
      for i = 1, #v.modeConfig do rv.lcd:parseToTextDisplay("Mode set to " .. v.modeConfig[i][1], "__" .. v.token .. "_m" .. i) end -- setting up mode change displays
   end
   collectgarbage("collect") -- probably unnecessary but doesn't hurt
end

---set how to react to the differend kind of events, activated after launch
---@param event EventType #Type of Logitech event
---@param arg integer #key number
---@param family HardwareFamily #Event family
---@async
function EventHandler:EventReceiver(event, arg, family)
   if family == "" then
      if event == "PROFILE_DEACTIVATED" then _shutDown() end -- shut down framework, LGS may abort before this
   elseif rv.profile.config.pollMKeysOnly or family ~= rv.profile.config.pollFamily then
      local profile = rv.profile
      local hook = profile.hooks.onEventHook
      local hookAsync = profile.hooks.onEventHookAsync
      if hook then hook(event, arg, family) end -- trigger event hook functions
      if hookAsync then rv.threading:taskRun(nil, nil, nil, hookAsync, event or false, arg or false, family or false) end
      local famName = rv.str:token(family) --[[@as FamilyToken]]
      _setModifiers(event, arg, famName) -- collecting modifier info
      local currentEvent = _collectKeyStats(arg, famName) ---compiled Event information
      local macroID = profile.bindings[(currentEvent or {}).keyName or ""] ---getting the ID of the macro binding if one exists
      if macroID and currentEvent then profile.macroIndex[macroID]:run(currentEvent) end -- triggering the macro
      if profile.config.logEvents then _logEvent(arg, famName) end -- after the macro, we log the event contents
      rv.logitech:undoTempMode(famName) -- if we were in a temporary mode we undo it now
      profile.deviceState[famName].blockedKey = 0 -- resetting blocked keys
      if arg ~= profile.deviceState[famName].sKey then -- g-shift is not counted for statistics
         rv.states.scriptStates.keyCount = rv.states.scriptStates.keyCount + 1 -- counting keys for temporary cycles
         if rv.states.scriptStates.keyCount % 50 == 0 then collectgarbage("collect") end -- collecting garbage every 50 key presses in case junk piles up
      end
   end
end

OnEvent = _launcher -- making sure the launcher will handle the first event.

return EventHandler
