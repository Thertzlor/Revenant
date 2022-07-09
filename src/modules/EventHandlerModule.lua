local rv = ... ---@type Revenant
local ProfileDefinition = rv:classImport("ProfileDefinition") ---@type ProfileDefinition
local ceil, IsKeyLockOn, IsModifierPressed, concat, pairs, ClearLCD, ClearLog, collectgarbage, gsub, insert, format, sub, type, remove = math.ceil, IsKeyLockOn, IsModifierPressed, table.concat, pairs, ClearLCD, ClearLog, collectgarbage, string.gsub, table.insert, string.format, string.sub, type, table.remove
local first = true

--[[=============================================================]] --
---@alias HardwareFamily "mouse"|"kb"|"lhc" all family strings supported by LGS
--[[=============================================================]] --
---@class Event
---@field keyNum number
---@field keyName string
---@field family HardwareFamily
---@field modifiers string|table|number
---@field area  AreaContainer
---@field virtualType number
---@field testCondition ConfigDefinition
---@field mode string|number
---@field link boolean
---@field shift number
---@field direction  string
---@field originator string
--[[=============================================================]] --
---@class EventInfo
---@field name string
---@field shift number
---@field shiftUp number
---@field mode number
---@field modeUp number
---@field modKeys string|number
---@field modKeysUp string|number
---@field fam string
--[[=============================================================]] --
local EventHandler = rv.baseClass:new() ---@class EventHandlerModule:BaseClass Functions that directly listen to events
EventHandler.pressed = false

local function _launchFramework()
    local config = rv.profile.config
    if config.outputLCD then rv:put("") end
    if config.enableLinting then rv.lint:configLinter(config) end
    local defnum = 0
    local gennum = 0
    local monum = #rv.mouseMonitorUtils.screens
    local moniRay = {} ---@type string[]
    local moplural = ""
    local lintIndicator = config.enableLinting and "\nLinting Enabled" or ""
    if monum > 1 then moplural = "s" end
    local devices = {}
    local deviceString = ''
    for _, v in pairs(rv.profile.deviceState) do if v.name then devices[#devices + 1] = { v.name, v.family } end end
    if #devices ~= 0 then deviceString = "\nDevices: " end
    for i = 1, #devices do local dev = devices[i]
        deviceString = deviceString .. (i == 1 and '' or ', ') .. dev[1] .. ' (' .. dev[2] .. ')'
    end
    for _ in pairs(rv.profile.assign.key or {}) do defnum = defnum + 1 end
    for _ in pairs(rv.profile.macroIndex) do gennum = gennum + 1 end
    for g = 1, #rv.mouseMonitorUtils.screens do local mon = rv.mouseMonitorUtils.screens[g]
        moniRay[#moniRay + 1] = mon.w .. "x" .. mon.h
    end
    rv:put("\nG600 Profile '" .. rv.profile.name .. "' powered by Revenant v" .. rv.scriptStates.version .. " successfully launched.\n" ..
        rv.scriptStates.locationIndicator .. "\nCurrent stats:\nButtons Assigned: " .. defnum .. "\nNamed Sequences: " .. 0 ..
        "\nGenerically Identified Tables: " .. gennum .. "\n" .. monum .. " Monitor" .. moplural .. " configured (" .. concat(moniRay, ",") .. ")" .. lintIndicator .. deviceString)
    local confLint = rv.lint.configLintErrors
    for i = 1, #rv.lint.lintErrors do rv:put("\n" .. rv.lint.lintErrors[i]) end
    for i = 1, #confLint do rv:put("\n" .. confLint[i]) end
    if #confLint ~= 0 and config.abortOnLintError then return false end
    rv.lcd:parseToDisplayDefinition(config.description or "", '_profileDefault', 1, nil, false, true)
    return true
end

---send shutdown message, abort all tasks, and set mode back to 1.
local function _shutDown()
    rv.scriptStates.exitingScript = true
    if rv.profile.bindings.exit then rv.profile.macroIndex[rv.profile.bindings.exit]:run({ virtualType = 4, keyNum = 0, family = "m" }) end
    rv:put("Profile '" .. rv.profile.name .. "' deactivated.")
    if rv.profile.config.outputLCD then ClearLCD() end
    if rv.profile.config.clearLog then ClearLog() end
    rv.threading:multiAbort("")
end

---compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
---@param num number
---@param fam HardwareFamily
---@return Event?
local function _collectKeyStats(num, fam)
    local event = { family = fam, keyNum = num } ---@type Event
    local config = rv.profile.config
    if num == rv.profile.deviceState[fam].sKey or not rv.eventHandler.pressed then return end

    local currentDir = rv.profile.deviceState[fam].dir
    local keyNum = fam .. num
    event.keyName = keyNum
    if #rv.keyStates.lastKeysDown ~= 0 and rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown].name ~= keyNum then
        if rv.profile.typedIndex["cycle"] then local cycleDex = rv.profile.typedIndex["cycle"]
            local dex = rv.profile.macroIndex ---@type table<string,CycleMacro>
            if rv.keyStates.lastKeysDown.family == fam then
                for i = 1, #cycleDex do local mac = dex[cycleDex[i]]
                    if mac.unstable and mac.sourceDevice == fam then mac.state.position = nil end
                end
            elseif not config.separateDeviceCycles then
                for i = 1, #cycleDex do local mac = dex[cycleDex[i]]
                    if mac.unstable then mac.state.position = nil end
                end
            end
        end
        rv.threading:tempCancel()
    end
    rv.keyStates.keysDown[keyNum] = rv.keyStates.keysDown[keyNum] or {}
    local saver = rv.keyStates.keysDown[keyNum]
    local shift = (config.globalGShift and rv.profile.globalState.shift) or rv.profile.deviceState[fam].shift
    if currentDir == "down" then
        saver.name = keyNum
        saver.shift = shift
        saver.mode = rv.profile.deviceState[fam].modus
        saver.modKeys = rv.scriptStates.mods
        saver.family = fam
        rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown + 1] = saver
    elseif currentDir == "up" then
        saver.shiftUp = shift
        saver.modeUp = rv.profile.deviceState[fam].modus
        saver.modKeysUp = rv.scriptStates.mods
        rv.keyStates.keysDown[keyNum] = nil
    end
    event.direction = currentDir
    event.mode = saver.mode or saver.modeUp
    event.modifiers = saver.modKeys or saver.modKeysUp
    event.shift = saver.shift or saver.shiftUp
    if #rv.keyStates.lastKeysDown > config.historyDepth + 1 then remove(rv.keyStates.lastKeysDown, 1) end
    return event
end

---IDs for modifiers are set here
---@param ev string
---@param ar number
---@param fam string TOKEN family name
local function _setModifiers(ev, ar, fam)
    rv.scriptStates.mods = ""
    rv.profile.deviceState[fam].blockedKey = 0
    local modShorts = {
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

    for i = 1, #modShorts do local obj = modShorts[i]
        if IsModifierPressed(obj[1]) then rv.scriptStates.mods = rv.scriptStates.mods .. obj[2] end
    end

    for f = 1, #lorail do local obj = lorail[f]
        if IsKeyLockOn(obj[1]) then rv.scriptStates.mods = rv.scriptStates.mods .. obj[2] end
    end

    if ev == "MOUSE_BUTTON_PRESSED" then
        rv.profile.deviceState[fam].dir = "down"
        rv.eventHandler.pressed = true
    elseif ev == "MOUSE_BUTTON_RELEASED" then
        rv.profile.deviceState[fam].dir = "up"
    end

    if ar == rv.profile.deviceState[fam].sKey then
        rv.scriptStates.currentButton = 0
        if rv.profile.deviceState[fam].dir == "down" then ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift = 1
        elseif rv.profile.deviceState[fam].dir == "up" then ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift = 0 end
    else rv.scriptStates.currentButton = ar end
end

---Logs event properties to the console
---@param ar number
---@param fam string
local function _logEvent(ar, fam)
    local mads, tabs, mem
    if not rv.scriptStates.mods or #rv.scriptStates.mods == 0 then mads = ""
    else mads = " , modifiers active: " .. rv.scriptStates.mods end
    tabs = ""
    for k, _ in pairs(rv.keyStates.keysDown) do
        if tabs == "" then tabs = " , Keys Down = " .. k
        else tabs = tabs .. ", " .. k end
    end
    local logKey = " (" .. (rv.profile.config.rename[fam .. ar] or fam .. ar) .. ")"
    local downList = {}
    local upList = {}
    for m = 1, #rv.keyStates.lastKeysDown do local el = rv.keyStates.lastKeysDown[m]
        downList[#downList + 1] = el.name
    end

    local lKey = " , Last Keys: " .. concat(downList, ",") .. "(down) , " .. concat(upList, ",") .. "(up)"
    mem = ""
    if rv.profile.config.logMemory then
        mem = ", Memory in use: "
        local memUnit = "kB"
        local memKb = ceil(collectgarbage("count")) ---@type integer|string
        if (memKb > 1024) then
            memKb = format("%2f", (memKb / 1024))
            memUnit = "mB"
        end
        mem = mem .. memKb .. memUnit
    end
    rv:put("Key-Event = " .. rv.profile.deviceState[fam].dir .. ", Current Key = " .. fam .. ar .. logKey .. ", G-Shift = "
        .. ((rv.profile.config.globalGShift and rv.profile.globalState) or rv.profile.deviceState[fam]).shift .. ", Mode = " .. rv.profile.deviceState[fam].modus .. tabs .. mads .. lKey .. mem)
end

local function _getPath()
    local proPaths = rv.paths.profilePaths
    local pathTable = { ((type(proPaths) == "string" and proPaths) or (proPaths[rv.paths.fileLocation or 1])) or "",
        gsub(rv.paths.profileName, "%.lua$", "") .. ".lua" }
    if (not rv.paths.absoluteProfilePaths) then insert(pathTable, 1, rv.paths.path) end
    local finalPath = concat(pathTable, "/")
    if rv.paths.fileLocation ~= 0 then
        rv.scriptStates.locationIndicator = "Running on external configs [" .. finalPath .. "]"
        return finalPath
    elseif rv.paths.fileLocation ~= 0 then
        rv.scriptStates.locationIndicator = "Running on internal configs, external file missing or broken. [" .. finalPath .. "]"
    end
    return nil
end

---Triggers whenever a mouse button is pressed, virtual or real.
---@param event string
---@param arg number
---@param family string
local function _OnEventHook(event, arg, family)
    if (rv.profile.config.pollMKeysOnly and (event == "M_Pressed" or event == "M_Released")) or family == rv.profile.config.pollFamily then
        rv.threading:poll(event, arg)
    elseif sub(event, 1, 2) ~= "M_" then
        if rv.profile.config.enableDebounce and rv.debouncer:debounceEvent(family, arg, event) then return end
        EventHandler:EventReceiver(event, arg, family)
        local state = rv.profile.deviceState
        local fam = rv.str:token(family) or ''
        if (event == "MOUSE_BUTTON_PRESSED" or event == "G_PRESSED") and arg == state[fam].sKey then
            state[fam].mBeforeG = state[fam].modus
        elseif state[fam] and arg == state[fam].sKey and
            state[fam].mBeforeG ~= state[fam].modus
        then
            rv.logitech:syncModes(state[fam].modus, state[fam].mBeforeG, fam)
            state[fam].mBeforeG = state[fam].modus
        end
    end
    rv.threading:doTasks()
end

local function _launcher()
    if not first then return end
    first = false
    if #rv.scriptStates.errors ~= 0 then return end
    local macroList = {} ---@type string[]
    local path = _getPath()
    local profileName = path or rv.paths.profileName
    rv.keys:constructKeyTable()
    rv.profile = ProfileDefinition:new(path, profileName, nil, true)
    rv.keys:loadKeyboard(rv.profile.config.keyboardLocale)
    local config = rv.profile.config
    if config.clearLog then ClearLog() end
    if config.monitors then rv.mouseMonitorUtils:compileScreenCoordinates(config.monitors) end
    rv.profile:parseBindings()
    if #rv.scriptStates.errors ~= 0 then rv:crash("Failed loading Revenant, profile could not be compiled. Errors:") end
    if config.showCompiled then
        for k in pairs(rv.macroImports) do macroList[#macroList + 1] = k end
        rv.tbl:prettyTab(macroList, "Used Macro Classes:")
        rv:put("Assignments:\n\n" .. rv.profile:buildTree())
    end

    EnablePrimaryMouseButtonEvents(rv.profile.config.primaryButtons)
    if _launchFramework() then
        rv.logitech:initModes()
        rv.threading:initLagSettings()
        rv.threading:initPolling()
        rv.threading:onPollEventIni()
        if config.enableDebounce then rv.debouncer:setupDebounce() end
        rv.threading:initRandom()
        rv.mouseMonitorUtils:initLagSettings()
        OnEvent = _OnEventHook
        local hook = rv.profile.hooks.onInitHook
        local hookAsync = rv.profile.hooks.onInitHookAsync
        if hook then hook() end
        if hookAsync then rv.threading:taskRun(nil, nil, nil, hookAsync) end
        if rv.profile.bindings.start then rv.profile.macroIndex[rv.profile.bindings.start]:run({ virtualType = 4, keyNum = 0, family = "m" }) end
    end
    if rv.macroImports.DocToggleMacro then
        rv:put('Parsing Documentation.\n')
        for _, v in pairs(rv.profile.macroIndex) do v:parseDocs() end
    else rv:put('') end
    for _, v in pairs(rv.profile.deviceState) do
        for i = 1, #v.modeConfig do
            rv.lcd:parseToDisplayDefinition('Mode set to ' .. v.modeConfig[i][1], '__' .. v.token .. '_m' .. i)
        end
    end
    collectgarbage()
end

---set how to react to the differend kind of events
---@param event string
---@param arg number
---@param family HardwareFamily
function EventHandler:EventReceiver(event, arg, family)
    if family == "" then if event == "PROFILE_DEACTIVATED" then _shutDown() end
    elseif rv.profile.config.pollMKeysOnly or family ~= rv.profile.config.pollFamily then
        local profile = rv.profile
        local hook = profile.hooks.onEventHook
        local hookAsync = profile.hooks.onEventHookAsync
        if hook then hook(event, arg, family) end
        if hookAsync then rv.threading:taskRun(nil, nil, nil, hookAsync, event or false, arg or false, family or false) end
        local famName = rv.str:token(family)
        _setModifiers(event, arg, famName)
        local currentEvent = _collectKeyStats(arg, famName)
        local macroID = profile.bindings[(currentEvent or {}).keyName]
        if macroID and currentEvent then profile.macroIndex[macroID]:run(currentEvent) end
        if profile.config.logEvents then _logEvent(arg, famName) end
        rv.logitech:undoTempMode(famName)
        profile.deviceState[famName].blockedKey = 0
        if arg ~= profile.deviceState[famName].sKey then
            rv.scriptStates.keyCount = rv.scriptStates.keyCount + 1 --counting keys for temporary cycles
            if rv.scriptStates.keyCount % 50 == 0 then collectgarbage() end
        end
    end
end

OnEvent = _launcher

return EventHandler
