local tl = ...---@type MainLibObject
local ceil, IsKeyLockOn, IsModifierPressed, concat, pairs, ClearLCD, ClearLog, collectgarbage, gsub, insert, running, format, sub, OutputLCDMessage, next = math.ceil, IsKeyLockOn, IsModifierPressed, table.concat, pairs, ClearLCD, ClearLog, collectgarbage, string.gsub, table.insert, coroutine.running, string.format, string.sub, OutputLCDMessage, next
local remove = table.remove---@type fun(): any

local ProfileDefinition = tl:classImport("ProfileDefinition")---@type ProfileDefinition
local onlyPoll = false
local lastClick = false
local first = true
-->>>> =================================================================================================
---@class Event
---@field keyNum number
---@field keyName string
---@field family  string
---@field modifiers  string|table
---@field area  AreaContainer
---@field virtualType number
---@field testCondition  TestStruct
---@field mode  string|number
---@field shift number
---@field direction  string
---@field originator string 
--=============================================================
local EventHandler = tl.baseClass:new()---@class EventHandlerModule:BaseClass Functions that directly listen to events 
EventHandler.pressed = false

local function _launchFramework()
    local config = tl.profile.config
    if config.outputLCD then tl:put("") end
    if config.enableLinting then tl.lint:configLinter(config, tl.profile.name) end
    if tl.profile.bindings.start then tl.profile.bindings.start:run() end
    local defnum = 0
    local gennum = 0
    local monum = #tl.mouseMonitorUtils.screens
    local moray = {}
    local moplural = ""
    local lintIndicator = config.enableLinting and "\nLinting Enabled" or ""
    if monum > 1 then moplural = "s" end
    for _ in pairs(tl.profile.assign.key or {}) do defnum = defnum + 1 end
    for _ in pairs(tl.profile.macroIndex) do gennum = gennum + 1 end
    for g = 1, #tl.mouseMonitorUtils.screens do local mon = tl.mouseMonitorUtils.screens[g]
        moray[#moray + 1] = mon.w .. "x" .. mon.h
    end
    tl.logitech:putNoLCD("\nG600 Profile '" .. tl.profile.name .. "' powered by Revenant v" .. tl.scriptStates.version .. " successfully launched.\n" ..
    tl.scriptStates.locationIndicator .. "\nCurrent stats:\nButtons Assigned: " .. defnum .. "\nNamed Sequences: " .. 0 ..
    "\nGenerically Identified Tables: " .. gennum .. "\n" .. monum .. " Monitor" .. moplural .. " configured (" .. concat(moray, ",") .. ")" .. lintIndicator)
    local confLint = tl.lint.configLintErrors
    for i = 1, #tl.lint.lintErrors do tl:put("\n" .. tl.lint.lintErrors[i]) end
    for i = 1, #confLint do tl:put("\n" .. confLint[i]) end
    if #confLint ~= 0 and config.abortOnLintError then return false end
    if config.description and config.description ~= "" then
        tl.lcd:parseToDisplayDefinition(config.description, '_profileDefault', 1, nil, true, true)
    end
    return true
end

---send shutdown message, abort all tasks, and set mode back to 1.
local function _shutDown()
    tl.scriptStates.exitingScript = true
    if tl.profile.assign.exit and #tl.profile.assign.exit ~= 0 then if tl.profile.bindings.exit then tl.profile.bindings.start:run() end end
    tl.logitech:putNoLCD("Profile '" .. tl.profile.name .. "' deactivated.")
    if tl.profile.config.outputLCD then ClearLCD() end
    if tl.profile.config.clearLog then ClearLog() end
    tl.coroutines:multiAbort("")
    tl.logitech:modeWrapper(1, nil, "all", true)
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num number
---@param fam string
---@return Event
local function _collectKeyStats(num, fam)
    local event = { family = fam, keyNum = num } ---@type Event
    if num == tl.profile.deviceState[fam].sKey or not tl.eventHandler.pressed then return end
    if tl.profile.config.logLevel ~= 0 and #tl.keyStates.lastKeysDown ~= 0 and
    ((tl.profile.config.logLevel > 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == nil) or
    (tl.profile.config.logLevel == 2 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == 0))
    then tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown] = nil end

    local currentDir = tl.profile.deviceState[fam].dir
    local keyNum = fam .. num
    event.keyName = keyNum
    if #tl.keyStates.lastKeysDown ~= 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].name ~= keyNum then
        if tl.profile.typedIndex["cycle"] then local cycleDex = tl.profile.typedIndex["cycle"]
            if tl.keyStates.lastKeysDown.family == fam then
                for i = 1, #cycleDex do local mac = tl.profile.macroIndex[cycleDex[i]] ---@type CycleMacro
                    if mac.unstable and mac.sourceDevice == fam then mac.state.position = nil end
                end
            elseif not tl.profile.config.separateDeviceCycles then
                for i = 1, #cycleDex do local mac = tl.profile.macroIndex[cycleDex[i]] ---@type CycleMacro
                    if mac.unstable then mac.state.position = nil end
                end
            end
        end
        for m, p in pairs(tl.coroutines.taskList) do if p.isTemp ~= nil then tl.coroutines:taskAbort(m) end end
    end
    tl.keyStates.keysDown[keyNum] = tl.keyStates.keysDown[keyNum] or {}
    local saver = tl.keyStates.keysDown[keyNum]
    if currentDir == "down" then
        saver.name = keyNum
        saver.reName = keyNum
        saver.shift = tl.profile.deviceState[fam].shift
        saver.mode = tl.profile.deviceState[fam].modus
        saver.modKeys = tl.scriptStates.mods
        saver.family = fam
    elseif currentDir == "up" then
        saver.shiftUp = tl.profile.deviceState[fam].shift
        saver.modeUp = tl.profile.deviceState[fam].modus
        saver.modKeysUp = tl.scriptStates.mods
        tl.keyStates.keysDown[keyNum] = nil
    end
    event.direction = currentDir
    event.mode = saver.mode or saver.modeUp
    event.modifiers = saver.modKeys or saver.modKeysUp
    event.shift = saver.shift or saver.shiftUp
    tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown + 1] = saver
    if #tl.keyStates.lastKeysDown > tl.profile.config.historyDepth + 1 then remove(tl.keyStates.lastKeysDown, 1) end
    return event
end

---IDs for modifiers are set here
---@param ev string
---@param ar number
---@param fam string
local function _setModifiers(ev, ar, fam)
    local famto = tl.str:token(fam)
    tl.scriptStates.mods = ""
    tl.profile.deviceState[famto].conKey = 0
    local morail = {
        { "rshift", "rs" },
        { "lshift", "ls" },
        { "shift", "gs" },
        { "rctrl", "rc" },
        { "lctrl", "lc" },
        { "ctrl", "gc" },
        { "ralt", "ra" },
        { "lalt", "la" },
        { "alt", "ga" }
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
        tl.profile.deviceState[famto].dir = "down"
        tl.eventHandler.pressed = true
    elseif ev == "MOUSE_BUTTON_RELEASED" then
        tl.profile.deviceState[famto].dir = "up"
    end

    if ar == tl.profile.deviceState[famto].sKey then
        tl.scriptStates.currentButton = 0
        if tl.profile.deviceState[famto].dir == "down" then tl.profile.deviceState[famto].shift = 1
        elseif tl.profile.deviceState[famto].dir == "up" then tl.profile.deviceState[fam].shift = 0 end
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
    local logKey = tl.profile.config.customNames and " (" .. (tl.profile.config.rename[fam .. ar] or fam .. ar) .. ")" or ""
    local downList = {}
    local upList = {}
    for m = 1, #tl.keyStates.lastKeysDown do local el = tl.keyStates.lastKeysDown[m] downList[#downList + 1] = el.name end

    local lKey = " , Last Keys: " .. concat(downList, ",") .. "(down) , " .. concat(upList, ",") .. "(up)"
    mem = ""
    if tl.profile.config.logMemory then
        mem = ", Memory in use: "
        local memUnit = "kB"
        local memKb = ceil(collectgarbage("count"))
        if (memKb > 1024) then
            memKb = format("%2f", (memKb / 1024))
            memUnit = "mB"
        end
        mem = mem .. memKb .. memUnit
    end
    tl.logitech:putNoLCD("Key-Event = " .. tl.profile.deviceState[fam].dir .. ", Current Key = " .. fam .. ar .. logKey .. ", G-Shift = "
    .. tl.profile.deviceState[fam].shift .. ", Mode = " .. tl.profile.deviceState[fam].modus .. tabs .. mads .. lKey .. mem)
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

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event string
---@param arg number
---@param family string
local function _OnEventHook(event, arg, family)
    if (tl.profile.config.pollMKeysOnly and (event == "M_Pressed" or event == "M_Released")) or family == tl.profile.config.pollFamily then
        tl.polling:poll(event, arg)
    else
        if tl.debouncer:debounceEvent(family, arg, event) then return end
        EventHandler:EventReceiver(event, arg, family)
        local fam = tl.str:token(family)
        if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == tl.profile.deviceState[fam].sKey then
            tl.profile.deviceState[fam].mBeforeG = tl.profile.deviceState[fam].modus
        elseif
        tl.profile.deviceState[fam] and arg == tl.profile.deviceState[fam].sKey and
        tl.profile.deviceState[fam].mBeforeG ~= tl.profile.deviceState[fam].modus
        then
            tl.logitech:syncModes(tl.profile.deviceState[fam].modus, tl.profile.deviceState[fam].mBeforeG, fam)
            tl.profile.deviceState[fam].mBeforeG = tl.profile.deviceState[fam].modus
        end
    end
    tl.polling:doTasks()
end

local function _launcher()
    if not first then return end
    first = false
    if #tl.scriptStates.errors ~= 0 then return end
    local macroList = {}
    local path = _getPath()
    local profileName = path or tl.paths.profileName
    tl.keys:constructKeyTable()
    tl.profile = ProfileDefinition:new(path, profileName, nil, true)
    local config = tl.profile.config
    if config.resolutions then tl.mouseMonitorUtils:compileScreenCoordinates(config.resolutions) end
    tl.profile:parseBindings()
    if #tl.scriptStates.errors ~= 0 then tl:crash("Failed loading Revenant, profile could not be compiled. Errors:") end
    if config.showCompiled then
        for k in pairs(tl.macroImports) do macroList[#macroList + 1] = k end
        tl.tbl:prettyTab(macroList, "Used Macro Classes:")
        tl:put("Assignments:\n\n" .. tl.profile:buildTree())
        if tl.profile.assign.start then tl.tbl:prettyTab(tl.profile.assign.start, "Start Function:") end
        if tl.profile.assign.exit then tl.tbl:prettyTab(tl.profile.assign.exit, "Exit Function:") end
        if next(tl.profile.assign.library) then tl.tbl:prettyTab(tl.profile.assign.library, "Macro Library:") end
    end

    EnablePrimaryMouseButtonEvents(tl.profile.config.primaryButtons)
    if _launchFramework() then
        tl.keys:loadKeyboard(tl.profile.config.keyboardLocale)
        tl.polling:initPolling()
        tl.polling:onPollEventIni()
        tl.debouncer:setupDebouncer()
        OnEvent = _OnEventHook
    end
    if tl.macroImports['DocToggleMacro'] then
        tl:put('Parsing Documentation.\n')
        for _, v in pairs(tl.profile.macroIndex) do v:parseDocs() end
    else tl:put('') end
    collectgarbage()
end

---@param event string
---@param arg number
---@param family string
local function _OnlyPollHook(event, arg, family)
    if (tl.profile.config.pollMKeysOnly and sub(event, 1, 2) == "M_") or family == tl.profile.config.pollFamily then tl.polling:poll(event, arg)
    else tl:put("nope:" .. event .. "," .. arg) end
    tl.polling:doTasks()
end

---set how to react to the differend kind of events
---@param event string
---@param arg number
---@param family string
function EventHandler:EventReceiver(event, arg, family)
    if family == "" then if event == "PROFILE_DEACTIVATED" then _shutDown() end
    elseif tl.profile.config.pollMKeysOnly or family ~= tl.profile.config.pollFamily then
        local famName = tl.str:token(family)
        _setModifiers(event, arg, famName)
        local currentEvent = _collectKeyStats(arg, famName)
        local macroID = tl.profile.bindings[(currentEvent or {}).keyName]
        if macroID then tl.profile.macroIndex[macroID]:run(currentEvent) end
        if tl.profile.config.logEvents then _logEvent(arg, famName) end
        tl.logitech:undoTempMode(famName)
        tl.profile.deviceState[famName].conKey = 0
        if arg ~= tl.profile.deviceState[famName].sKey then
            tl.scriptStates.keyCount = tl.scriptStates.keyCount + 1 --counting keys for temporary cycles
            if tl.scriptStates.keyCount % 50 == 0 then collectgarbage() end
        end
    end
end

function EventHandler:swallowKeys()
    if onlyPoll then return end
    OnEvent = _OnlyPollHook
    onlyPoll = true
    if running() then return end
    tl.coroutines:taskRun(nil, nil, nil, function()
        tl.coroutines:wait(1, 0, false)
        tl.coroutines:wait(1, 0, false)
        if not onlyPoll then return -1 end
        tl:put("restoring 0")
        onlyPoll = false
        OnEvent = _OnEventHook
    end)
end

function EventHandler:unswallowKeys()
    OnEvent = _OnEventHook
    onlyPoll = false
    tl:put("restoring 1")
end

OnEvent = _launcher

return EventHandler