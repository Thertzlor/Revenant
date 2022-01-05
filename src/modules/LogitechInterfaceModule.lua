local rv = ...---@type Revenant
local OutputLCDMessage, PlayMacro, AbortMacro, OutputLogMessage, sub, gsub, type, concat, tostring, SetBacklightColor, ClearLCD, arg, tonumber, error = OutputLCDMessage, PlayMacro, AbortMacro, OutputLogMessage, string.sub, string.gsub, type, table.concat, tostring, SetBacklightColor, ClearLCD, arg, tonumber, error
--=============================================================
local LogitechInterfaceModule = rv.baseClass:new()---@class LogitechInterfaceModule:BaseClass Functions that interact directly with the LGS software
LogitechInterfaceModule.unToken = { m = "Mouse", k = "Keyboard", l = "LHC" }
LogitechInterfaceModule.unLogiToken = { m = "mouse", k = "kb", l = "lhc" }
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
    if type(fam) == "string" and fam == "all" then
        local famArr = { "m", "l", "k" }
        for g = 1, #famArr do self:_modeSelect(targ, famArr[g]) end
    elseif type(fam) == "table" then for g = 1, #fam do self:_modeSelect(targ, fam[g]) end
    else
        fam = rv.str:token(fam)
        if deviceState[fam] then
            if type(targ) == "table" then targ = targ[1] end
            targ = rv.tbl:cycleIndex(deviceState[fam].modeCount, targ, deviceState[fam].modus)
            if type(targ) ~= "number" or deviceState[fam].modeCount < 2 or deviceState[fam].modus == targ then return end
            if ((rv.profile.config.globalGShift and rv.profile.globalState.shift) or deviceState[fam].shift) == 0 then self:syncModes(targ, nil, fam) end
            if targ == nil or targ == 0 then --if the target mode is 0, just cycle to the next mode
                _cycleMode(fam)
            elseif targ <= deviceState[fam].modeCount then --else cycle until you reach the target mode
                while targ ~= deviceState[fam].modus do _cycleMode(fam) end
            else self:_modeSelect(self.profile.deviceState[fam].modeCount, fam) end
            rv.lcd:displayOnLCD('__' .. fam .. '_m' .. deviceState[fam].modus, nil, rv.profile.config.LCDMessageDuration)
            if deviceState[fam].modeConfig[targ] and deviceState[fam].modeConfig[targ][2] then
                self:backLightControl(deviceState[fam].modeConfig[targ][2], fam)
            end
        end
    end
end

---toggling a different mouse mode as long as a button is held down
---@private
---@param md number | string
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
            self:_modeSelect(self.profile.deviceState[fam].lastMod, fam)
            deviceState[fam].lastMod = 0
        end
    end
end

---Change the mode temporarily, revert after a certain number of button presses.
---@private
---@param md number | string
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
---@param nam table|string
function LogitechInterfaceModule:_playExternalMacro(nam)
    local c
    if type(nam) == "table" then
        nam = nam[1]
        c = nam.blocking
    end
    if c == 2 or c == 3 then
        AbortMacro()
        self.macPlay = false
    end
    PlayMacro(nam)
end

---toggle an external LGS macro
---@private
---@param nam table|string
---@param direction string
function LogitechInterfaceModule:_toggleExternalMacro(nam, direction)
    local c
    if type(nam) == "table" then
        nam = nam[1]
        c = nam.blocking
    end
    if direction and direction ~= "down" then return end
    if self.macPlay == false then
        if c == 2 or c == 3 then
            AbortMacro()
            self.macPlay = false
        end
        PlayMacro(nam)
        self.macPlay = true
    else
        AbortMacro()
        self.macPlay = false
    end
end

---@param mod number
local function _iterateMode(mod)
    AbortMacro()
    PlayMacro("Mode Switch (G600)")
    return mod + 1
end

---Outputs messages to the Logitech lua log
---@vararg string
function rv:put(...)
    for i = 1, arg.n do if type(arg[i]) ~= "string" then arg[i] = tostring(arg[i]) end end
    local fin = concat(arg, " ")
    OutputLogMessage(fin .. "\n")
end

function rv:pipe(...)
    rv:put(...)
    return ...
end

---Outputs messages to the Logitech lua log but not the LCD display
---@vararg string
function LogitechInterfaceModule:putNoLCD(...)
    for i = 1, arg.n do if type(arg[i]) ~= "string" then arg[i] = tostring(arg[i]) end end
    local fin = concat(arg, " ")
    OutputLogMessage(fin .. "\n")
end

--TODO:Test HEX backlighting on an actual mouse
---Set the backlight of compatible logitech devices to a specific color
---@param vals number[]|string[]
---@param fam string
function LogitechInterfaceModule:backLightControl(vals, fam)
    local finVals
    if #vals == 3 and rv.tbl:isSingleTypeTable(vals, "number") then finVals = vals
    elseif #vals == 1 and type(vals[1]) == "string" then
        local vols, _ = gsub(vals[1], "^#", "")
        if #vols == 6 or #vols == 3 then
            if #vols == 3 then vols = gsub(vols, "(.)", "%1%1") end
            finVals = { tonumber(sub(vols, 1, 2)), tonumber(sub(vols, 3, 4)), tonumber(sub(vols, 5)) }
        end
    end
    if not finVals then error("invalid color value") end
    SetBacklightColor(finVals[1], finVals[2], finVals[3], self.unLogiToken[fam])
end

---This function keeps the internal script mode in synch with the hardware's mode
---@type fun (torg, orig, fam)
---@param torg number
---@param orig number
---@param fam string
function LogitechInterfaceModule:syncModes(torg, orig, fam)
    local deviceState = rv.profile.deviceState
    if deviceState[fam].modeCount > 3 or (not deviceState[fam].bindHardwareModes) or deviceState[fam].modeCount < 2 then return end
    local mod = orig or deviceState[fam].modus
    local targ = torg or mod + 1
    if targ == 0 then targ = mod + 1 end
    if targ > deviceState[fam].modeCount then targ = 1 end
    if mod == targ then return end
    if mod > targ then
        while deviceState[fam].modeCount >= mod do mod = _iterateMode(mod) end
        if deviceState[fam].modeCount == 2 then _iterateMode(mod) end
        mod = 1
    end
    while targ > mod do mod = _iterateMode(mod) end
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
            self:putNoLCD("mode reset")
        end
    end
end

---Wrapper function for internal macro control methods
---@param cmd table
---@param options ExternalMacroOptions
---@param dir string
---@param dirMatch boolean
function LogitechInterfaceModule:externalMacroWrapper(cmd, options, dir, dirMatch)
    if type(cmd) == "table" and cmd.play then
        if options.play == "toggle" then self:_toggleExternalMacro(cmd)
        elseif options.play == "hold" then self:_toggleExternalMacro(cmd, dir) end
    elseif dirMatch then self:_playExternalMacro(cmd) end
end

---Wrapper for internal mode changing functions
---@type ModeWrapper
---@param target number|string|table
---@param mod number
---@param fam string
---@param dirMatch boolean
function LogitechInterfaceModule:modeWrapper(target, mod, fam, dirMatch)
    mod = mod or "normal"
    if mod == "normal" then if dirMatch then self:_modeSelect(target, fam) end
    elseif mod == "toggle" then self:_toggleMode(target, fam)
    else self:_temporaryMode(target, mod, fam) end
end

return LogitechInterfaceModule