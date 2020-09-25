---@type MainLibObject
local tl, Base = ...
local ceil, IsKeyLockOn, IsModifierPressed, format, concat, remove, pairs, ClearLCD, ClearLog, collectgarbage = math.ceil, IsKeyLockOn, IsModifierPressed, string.format, table.concat, table.remove, pairs, tl.config.hubMode and tl.helperUtils.dummy or ClearLCD, ClearLog, collectgarbage
-->>>> Functions that directly listen to events =================================================================================================
---@class EventHandlerModule
local EventHandler = Base:new()
EventHandler.pressed = false
---compile and display stats on script startup
local function _launchFramework()
    if tl.config.outputLCD then
        tl:put("")
    end
    tl.bindings:quickMacro(tl.assign.start)
    local defnum = 0
    local gennum = 0
    local monum = #tl.config.resolutions
    local moray = {}
    local moplural = ""
    local lintIndicator = tl.config.enableLinting and "\nLinting Enabled" or ""
    if monum > 1 then
        moplural = "s"
    end
    for k, _ in pairs(tl.assign.key) do
        if k ~= "pID" then
            defnum = defnum + 1
        end
    end
    for _, _ in pairs(tl.macroIndex) do
        gennum = gennum + 1
    end
    for g = 1, #tl.config.resolutions do
        local mon = tl.config.resolutions[g]
        moray[#moray + 1] = mon.w .. "x" .. mon.h
    end
    tl.logitech:putNoLCD(
    "\nG600 Profile '" ..
    tl.config.profileName ..
    "' powered by T-lib v" ..
    tl.scriptStates.version ..
    " successfully launched.\n" ..
    tl.scriptStates.locationIndicator ..
    "\nCurrent stats:\nButtons Assigned: " ..
    defnum ..
    "\nNamed Sequences: " ..
    tl.scriptStates.namedTables ..
    "\nGenerically Identified Tables: " ..
    gennum ..
    "\n" ..
    monum ..
    " Monitor" ..
    moplural ..
    " configured (" ..
    concat(moray, ",") .. ")" .. lintIndicator
    )
    for _, v in pairs(tl.lint.lintErrors) do
        tl.logitech:putNoLCD("\n" .. v)
    end
    for _, v in pairs(tl.lint.configLintErrors) do
        tl.logitech:putNoLCD("\n" .. v)
    end
end

---send shutdown message, abort all tasks, and set mode back to 1.
local function _shutDown()
    tl.scriptStates.exitingScript = true
    if tl.assign.exit and #tl.assign.exit ~= 0 then
        tl.bindings:quickMacro(tl.assign.exit)
    end
    tl.logitech:putNoLCD("Profile '" .. tl.config.profileName .. "' deactivated.")
    if tl.config.outputLCD then
        ClearLCD()
    end
    if tl.config.clearLog then
        ClearLog()
    end
    tl.coroutines:multiAbort("")
    tl.logitech:modeWrapper(1, nil, "all", true)
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num number
---@param fam string
local function _collectKeyStats(num, fam)
    if num == tl.deviceState[fam].sKey or not tl.eventHandler.pressed then
        return
    end
    if
    tl.config.logLevel ~= 0 and #tl.keyStates.lastKeysDown ~= 0 and
    ((tl.config.logLevel > 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == nil) or
    (tl.config.logLevel == 2 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].played == 0))
    then
        tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown] = nil
    end
    local currentDir = tl.deviceState[fam].dir
    local keyNum = fam .. num
    if #tl.keyStates.lastKeysDown ~= 0 and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].name ~= keyNum then
        if tl.keyStates.lastKeysDown.family == fam then
            tl.helperUtils.wipe(tl.deviceState[fam].unstable)
        elseif not tl.config.separateDeviceCycles then
            for g = 1, #tl.stringPresets.families do
                local cFam = tl.str:token(tl.stringPresets.families[g])
                tl.helperUtils.wipe(tl.deviceState[cFam].unstable)
            end
        end
        for m, p in pairs(tl.coroutines.taskList) do
            if p.isTemp ~= nil then
                tl.coroutines:taskAbort(m)
            end
        end
    end
    tl.keyStates.keysDown[keyNum] = tl.keyStates.keysDown[keyNum] or {}
    local saver = tl.keyStates.keysDown[keyNum]
    if currentDir == "down" then
        saver.name = keyNum
        saver.reName = keyNum
        saver.shift = tl.deviceState[fam].shift
        saver.mode = tl.deviceState[fam].modus
        saver.modKeys = tl.scriptStates.mods
        saver.family = fam
    elseif currentDir == "up" then
        saver.shiftUp = tl.deviceState[fam].shift
        saver.modeUp = tl.deviceState[fam].modus
        saver.modKeysUp = tl.scriptStates.mods
        tl.keyStates.keysDown[keyNum] = nil
    end
    tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown + 1] = saver
    if #tl.keyStates.lastKeysDown > tl.config.historyDepth + 1 then
        remove(tl.keyStates.lastKeysDown, 1)
    end
end

---IDs for modifiers are set here
---@param ev string
---@param ar string
---@param fam string
local function _setModifiers(ev, ar, fam)
    local famto = tl.str:token(fam)
    tl.scriptStates.mods = ""
    tl.deviceState[famto].conKey = 0
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

    for i = 1, #morail do
        local obj = morail[i]
        if IsModifierPressed(obj[1]) then
            tl.scriptStates.mods = tl.scriptStates.mods .. obj[2]
        end
    end

    for f = 1, #lorail do
        local obj = lorail[f]
        if IsKeyLockOn(obj[1]) then
            tl.scriptStates.mods = tl.scriptStates.mods .. obj[2]
        end
    end

    if ev == "MOUSE_BUTTON_PRESSED" then
        tl.deviceState[famto].dir = "down"
        tl.eventHandler.pressed = true
    elseif ev == "MOUSE_BUTTON_RELEASED" then
        tl.deviceState[famto].dir = "up"
    end

    if ar == tl.deviceState[famto].sKey then
        tl.scriptStates.currentButton = 0
        if tl.deviceState[famto].dir == "down" then
            tl.deviceState[famto].shift = 1
        elseif tl.deviceState[famto].dir == "up" then
            tl.deviceState[fam].shift = 0
        end
    else
        tl.scriptStates.currentButton = ar
    end
end

---Logs event properties to the console
---@param ar number
---@param fam string
local function _logEvent(ar, fam)
    local mads, tabs, mem
    if not tl.scriptStates.mods or #tl.scriptStates.mods == 0 then
        mads = ""
    else
        mads = " , modifiers active: " .. tl.scriptStates.mods
    end
    tabs = ""
    for k, _ in pairs(tl.keyStates.keysDown) do
        if tabs == "" then
            tabs = " , Keys Down = " .. k
        else
            tabs = tabs .. ", " .. k
        end
    end
    local logKey = tl.config.customNames and " (" .. (tl.config.rename[fam .. ar] or fam .. ar) .. ")" or ""
    local downList = {}
    local upList = {}
    for m = 1, #tl.keyStates.lastKeysDown do
        local el = tl.keyStates.lastKeysDown[m]
        downList[#downList + 1] = el.name
    end

    local lKey = " , Last Keys: " .. concat(downList, ",") .. "(down) , " .. concat(upList, ",") .. "(up)"
    mem = ""
    if tl.config.logMemory then
        mem = ", Memory in use: "
        local memUnit = "kB"
        local memKb = ceil(collectgarbage("count"))
        if (memKb > 1024) then
            memKb = format("%2f", (memKb / 1024))
            memUnit = "mB"
        end
        mem = mem .. memKb .. memUnit
    end
    tl.logitech:putNoLCD(
    "Key-Event = " ..
    tl.deviceState[fam].dir ..
    ", Current Key = " ..
    fam ..
    ar ..
    logKey ..
    ", G-Shift = " ..
    tl.deviceState[fam].shift ..
    ", Mode = " .. tl.deviceState[fam].modus .. tabs .. mads .. lKey .. mem
    )
end

---set how to react to the differend kind of events
---@param event string
---@param arg number
---@param family string
local function _EventReceiver(event, arg, family)
    if family == "" then
        if event == "PROFILE_ACTIVATED" then
            if #tl.scriptStates.errors ~= 0 then
                return
            end
            ---@type AssignmentTable
            tl.assign = {}
            EnablePrimaryMouseButtonEvents(1)
            tl.wrapperFunctions.funcRayD =             tl.tbl:intersect(tl.wrapperFunctions.upDownFuncs, tl.wrapperFunctions.defaultFuncs)
            tl.keys:constructKeyTable()
            tl.profileCompiler:buildBindings()
            tl.polling:initPolling()
            tl.polling:onPollEventIni()
            if tl.config.showCompiled then
                tl.tbl:prettyTab(tl.assign.key, "Assignments:")
                if #tl.assign.start ~= 0 then
                    tl.tbl:prettyTab(tl.assign.start, "Start Function:")
                end
                if #tl.assign.exit ~= 0 then
                    tl.tbl:prettyTab(tl.assign.exit, "Exit Function:")
                end
                if #tl.assign.library ~= 0 then
                    tl.tbl:prettyTab(tl.assign.library, "Macro Library:")
                end
            end
            _launchFramework()
            collectgarbage()
        elseif event == "PROFILE_DEACTIVATED" then
            _shutDown()
        end
    elseif family ~= tl.config.pollFamily then
        local famName = tl.str:token(family)
        _setModifiers(event, arg, famName)
        _collectKeyStats(arg, famName)
        tl.bindings:launchMacro(arg, famName)
        if tl.config.logEvents then
            _logEvent(arg, famName)
        end
        tl.logitech:undoTempMode(famName)
        tl.deviceState[famName].conKey = 0
        if arg ~= tl.deviceState[famName].sKey then
            tl.scriptStates.keyCount = tl.scriptStates.keyCount + 1 --counting keys for temporary cycles
            if tl.scriptStates.keyCount % 50 == 0 then
                collectgarbage()
            end
        end
    end
end

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event string
---@param arg number
---@param family string
function OnEvent(event, arg, family)
    if family == tl.config.pollFamily then
        tl.polling:poll(event, arg)
    else
        _EventReceiver(event, arg, family)
        local fam = tl.str:token(family)
        if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == tl.deviceState[fam].sKey then
            tl.deviceState[fam].mBeforeG = tl.deviceState[fam].modus
        elseif
        tl.deviceState[fam] and arg == tl.deviceState[fam].sKey and
        tl.deviceState[fam].mBeforeG ~= tl.deviceState[fam].modus
        then
            tl.logitech:syncModes(tl.deviceState[fam].modus, tl.deviceState[fam].mBeforeG, fam)
            tl.deviceState[fam].mBeforeG = tl.deviceState[fam].modus
        end
    end
    tl.polling:doTasks()
end
local OnEvent = OnEvent

return EventHandler