local rv = ...---@type Revenant
local PlayMacro, AbortMacro, OutputLogMessage, sub, gsub, type, concat, tostring, SetBacklightColor, arg, tonumber, error, SetMKeyState, GetMKeyState = PlayMacro, AbortMacro, OutputLogMessage, string.sub, string.gsub, type, table.concat, tostring, SetBacklightColor, arg, tonumber, error, SetMKeyState, GetMKeyState
--=============================================================
local LogitechInterfaceModule = rv.baseClass:new()---@class LogitechInterfaceModule:BaseClass Functions that interact directly with the LGS software
--local unToken = { m = "Mouse", k = "Keyboard", l = "LHC" }
local unLogiToken = { m = "mouse", k = "kb", l = "lhc" }
LogitechInterfaceModule.macPlay = false---@private
LogitechInterfaceModule.lastModC = 0 ---@private

local function _cycleMode(fam) --sub function to make sure the modes cycle back correctly
    local deviceState = rv.profile.deviceState
    deviceState[fam].modus = (deviceState[fam].modus < deviceState[fam].modeCount) and deviceState[fam].modus + 1 or 1
end

---Put the mouse in a specific mode.
---@private
---@param targ number | string | table
---@param fam string
function LogitechInterfaceModule:_modeSelect(targ, fam)
    local deviceState = rv.profile.deviceState
    if fam == "all" then
        local famArr = { "m", "l", "k" }
        for g = 1, #famArr do self:_modeSelect(targ, famArr[g]) end
    elseif type(fam) == "table" then for g = 1, #fam do self:_modeSelect(targ, fam[g]) end
    else
        fam = rv.str:token(fam)
        local state = deviceState[fam]
        if state then
            local config = rv.profile.config
            if type(targ) == "table" then targ = targ[1] end
            if type(targ) == "string" then
                for i = 1, state.modeCount do local mod = state.modeConfig[i]
                    if mod and mod == targ or type(mod) == "table" and mod[1] == targ then
                        targ = i
                        break
                    end
                end
            end
            targ = rv.tbl:cycleIndex(state.modeCount, targ, state.modus)
            if type(targ) ~= "number" or state.modeCount < 2 or state.modus == targ then return end
            if ((config.globalGShift and rv.profile.globalState.shift) or state.shift) == 0 then self:syncModes(targ, nil, fam) end
            if targ == nil or targ == 0 then --if the target mode is 0, just cycle to the next mode
                _cycleMode(fam)
            elseif targ <= state.modeCount then --else cycle until you reach the target mode
                while targ ~= state.modus do _cycleMode(fam) end
            else self:_modeSelect(state.modeCount, fam) end
            if state.bindHardwareModes and state.family ~= config.pollFamily then SetMKeyState(targ, unLogiToken[state.token]) end
            rv.lcd:displayOnLCD('__' .. fam .. '_m' .. state.modus, nil, config.LCDMessageDuration)
            self:setModeBacklight(targ, fam)
        end
    end
end

---toggling a different mouse mode as long as a button is held down
---@private
---@param md number | string|table
---@param fam string
function LogitechInterfaceModule:_toggleMode(md, fam)
    local deviceState = rv.profile.deviceState
    if type(fam) == "string" and fam == "all" then
        local famArr = { "m", "l", "k" }
        for g = 1, #famArr do self:_toggleMode(md, famArr[g]) end
    elseif type(fam) == "table" then for g = 1, #fam do self:_toggleMode(md, fam[g]) end
    else
        if deviceState[fam].dir == "down" then
            deviceState[fam].lastMod = deviceState[fam].modus
            self:_modeSelect(md, fam)
        else
            self:_modeSelect(rv.profile.deviceState[fam].lastMod, fam)
            deviceState[fam].lastMod = 0
        end
    end
end

--Makes sure all modes are sensible on startup
function LogitechInterfaceModule:initModes()
    local config = rv.profile.config
    local globalTarget = config.globalModes and next(config.globalModes) and GetMKeyState(unLogiToken[rv.str:token(config.globalModeFamily)])
    for k, v in pairs(rv.profile.deviceState) do
        local currentMode = GetMKeyState(unLogiToken[k])
        v.modus = currentMode
        if config.modeReset and currentMode ~= 1 then
            self:syncModes(1, currentMode, k)
            if not v.family ~= config.pollFamily then SetMKeyState(1, unLogiToken[k]) end
            v.modus = 1
        elseif (not config.modeReset) and globalTarget and currentMode ~= globalTarget then
            self:syncModes(globalTarget, currentMode, k)
            if not v.family ~= config.pollFamily then SetMKeyState(globalTarget, unLogiToken[k]) end
            v.modus = globalTarget
        end
        local cmc = v.modeConfig[v.modus]
        if type(cmc) == "table" and cmc[2] then self:backLightControl(cmc[2], k) end
    end
end

---Change the mode temporarily, revert after a certain number of button presses.
---@private
---@param md number | string |table
---@param num number
---@param fam string
function LogitechInterfaceModule:_temporaryMode(md, num, fam)
    local deviceState = rv.profile.deviceState
    if fam == "all" then
        local famArr = { "m", "l", "k" }
        for g = 1, #famArr do self:_temporaryMode(md, num, famArr[g]) end
    elseif type(fam) == "table" then
        for g = 1, #fam do self:_temporaryMode(md, num, fam[g]) end
    else
        if deviceState[fam].lastModN == 0 and deviceState[fam].dir == "down" then
            deviceState[fam].lastModN = deviceState[fam].modus
            self.lastModC = rv.scriptStates.keyCount + ((num and num + ((num > 2 and 1) or -1)) or 0)
            self:_modeSelect(md, fam)
        end
    end
end

---Play an external LGS macro
---@private
---@param nam {blocking:boolean}|string
---@param blocking? 1|2|3
function LogitechInterfaceModule:_playExternalMacro(nam, blocking)
    if blocking == 2 or blocking == 3 then
        AbortMacro()
        self.macPlay = false
    end
    PlayMacro(nam)
    return true
end

---toggle an external LGS macro
---@private
---@param nam MacroOptions|string
---@param direction? string
---@param blocking? 1|2|3
function LogitechInterfaceModule:_toggleExternalMacro(nam, direction, blocking)
    if direction and direction ~= "down" then return end
    if self.macPlay == false then
        self:_playExternalMacro(nam, blocking)
        self.macPlay = true
        return true
    else
        AbortMacro()
        self.macPlay = false
        return false
    end
end

---@param mod number
local function _iterateMode(mod, fam)
    if fam == "m" then
        AbortMacro()
        PlayMacro("Mode Switch (" .. rv.profile.deviceState[fam].name .. ")")
    end
    return mod + 1
end

---Outputs messages to the Logitech lua log
---@vararg string
function rv:put(...)---@cast arg {n:number}
    for i = 1, arg.n do if type(arg[i]) ~= "string" then arg[i] = tostring(arg[i]) end end
    local fin = concat(arg, " ")
    OutputLogMessage(fin .. "\n")
end

function rv:pipe(...)
    rv:put(...)
    return ...
end

--TODO:Test HEX backlighting on G300
---Set the backlight of compatible logitech devices to a specific color
---@param vals number[]|string[]
---@param fam string
function LogitechInterfaceModule:backLightControl(vals, fam)
    local finVals
    if #vals == 3 and rv.tbl:isSingleTypeTable(vals, "number") then finVals = vals
    elseif type(vals) == "string" or (#vals == 1 and type(vals[1]) == "string") then---@cast vals string[]
        local vols, _ = gsub((type(vals) == "table" and vals[1] or vals), "^#", "")
        if #vols == 6 or #vols == 3 then
            if #vols == 3 then vols = gsub(vols, "(.)", "%1%1") end
            finVals = { tonumber(sub(vols, 1, 2), 16), tonumber(sub(vols, 3, 4), 16), tonumber(sub(vols, 5), 16) }
        end
    end
    if not finVals then error("invalid color value") end
    SetBacklightColor(finVals[1], finVals[2], finVals[3], unLogiToken[fam])
end

function LogitechInterfaceModule:setModeBacklight(modeNum, fam)
    if (not modeNum) or (not fam) then return end
    local modeConf = rv.profile.deviceState[fam].modeConfig[modeNum]
    if not modeConf or type(modeConf) ~= "table" or not modeConf[2] then return end
    self:backLightControl(modeConf[2], fam)
end

---This function keeps the internal script mode in synch with the hardware's mode
---@type fun (torg, orig, fam)
---@param targetMode number
---@param orig? number
---@param fam string
function LogitechInterfaceModule:syncModes(targetMode, orig, fam)
    local deviceState = rv.profile.deviceState
    if deviceState[fam].modeCount > 3 or (not deviceState[fam].bindHardwareModes) or deviceState[fam].modeCount < 2 then return end
    local mod = orig or deviceState[fam].modus
    local targ = targetMode or mod + 1
    if targ == 0 then targ = mod + 1 end
    if targ > deviceState[fam].modeCount then targ = 1 end
    if mod == targ then return end
    if mod > targ then
        while deviceState[fam].modeCount >= mod do mod = _iterateMode(mod, fam) end
        if deviceState[fam].modeCount == 2 then _iterateMode(mod, fam) end
        mod = 1
    end
    while targ > mod do mod = _iterateMode(mod, fam) end
end

---set the mode back to the standard mode once a enough button presses have been executed.
---@param fam string
function LogitechInterfaceModule:undoTempMode(fam)
    local deviceState = rv.profile.deviceState
    if type(fam) == "string" and fam == "all" then
        local famArr = { "m", "l", "k" }
        for g = 1, #famArr do self:undoTempMode(famArr[g]) end
    elseif type(fam) == "table" then
        for g = 1, #fam do self:undoTempMode(fam[g]) end
    else
        if deviceState[fam].lastModN ~= 0 and (rv.scriptStates.keyCount - self.lastModC) > 2 then
            self:_modeSelect(deviceState[fam].lastModN, fam)
            deviceState[fam].lastModN = 0
            rv:put("mode reset")
        end
    end
end

---Wrapper function for internal macro control methods
---@param cmd table
---@param options _ExternalMacroOptions
---@param dir string
function LogitechInterfaceModule:externalMacroWrapper(cmd, options, dir)
    local block = options.macroBlocking
    if options.play == "toggle" then return self:_toggleExternalMacro(cmd, nil, block)
    elseif options.play == "hold" then return self:_toggleExternalMacro(cmd, dir, block) end
    return self:_playExternalMacro(cmd, block)
end

---Wrapper for internal mode changing functions
---@param target number|string|table
---@param mod number
---@param fam string
function LogitechInterfaceModule:modeWrapper(target, mod, fam)
    mod = mod or "normal"
    if mod == "normal" then self:_modeSelect(target, fam)
    elseif mod == "toggle" then self:_toggleMode(target, fam)
    else self:_temporaryMode(target, mod, fam) end
end

return LogitechInterfaceModule