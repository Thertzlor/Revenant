local rv = ... ---@type Revenant
local abs, sub, match, find, type, gmatch, tonumber = math.abs, string.sub, string.match, string.find, type, string.gmatch, tonumber
local MacroValidatorModule = rv.baseClass:new() ---@class MacroValidatorModule:BaseClass controls parsing and execution of user defined bindings

---check if the gshift is in the right state
---@param stat MacroStatContainer
---@param shifted number
---@param lShift number
local function _testShift(stat, shifted, lShift)
    stat.conditions.shiftPass = type(shifted) == "number" and (shifted == 2 or (shifted == lShift))
    return stat.conditions.shiftPass
end

---Check if the mdoe is in the right state
---@param stat MacroStatContainer
---@param modi string|number|(string|number)[]
---@param lMod number
---@param fam HardwareFamily
---@param manual? string
---@return boolean?
local function _testMode(stat, modi, lMod, fam, manual)
    local moTest = manual or modi
    local rVal = true
    if type(moTest) == "number" then
        if moTest < 0 then
            rVal = false
            moTest = abs(moTest)
        end
        if moTest == 0 or moTest == tonumber(lMod) then
            stat.conditions.modePass = rVal
            return rVal
        end
        return not rVal
    elseif type(moTest) == "string" then
        if sub(moTest, 1, 1) == "-" then
            rVal = false
            moTest = sub(moTest, 2)
        end
        local modeRay = rv.profile.deviceState[fam].modeConfig
        if modeRay[lMod] and modeRay[lMod][1] == moTest then
            stat.conditions.modePass = rVal
            return rVal
        end
        return not rVal
    elseif type(moTest) == "table" then
        local negs = {}
        local posis = {}
        for i = 1, #moTest do local obj = moTest[i]
            local target = posis
            if type(obj) == "number" and obj < 0 then target = negs
            elseif type(obj) == "string" and sub(obj, 1, 1) == "-" then target = negs end
            target[#target + 1] = obj
        end
        local pnum, nnum = #posis, #negs

        for i = 1, nnum do if _testMode(stat, modi, lMod, fam, negs[i]) == false then return false end end
        for i = 1, pnum do if _testMode(stat, modi, lMod, fam, posis[i]) == true then return true end end
        return pnum == 0 or nnum ~= 0
    end
end

---function for testing if the correct modifiers are pressed.
---@param stat MacroStatContainer
---@param mkeys string
---@param lModif number|string
local function _testKey(stat, mkeys, lModif)
    local okayK = false
    if (mkeys == "no" and (lModif == nil or lModif == 0 or #lModif == 0)) or
        (mkeys ~= "no" and (mkeys == nil or mkeys == 0 or mkeys == "" or lModif == mkeys)) then
        okayK = true
    elseif type(lModif) == "string" and type(mkeys) == "string" then
        local typeComb = false
        local keyComb = false
        local comTab = {}
        local recTab = {}

        for i in gmatch(mkeys, "%a%a") do comTab[#comTab + 1] = i end
        for i in gmatch(lModif, "%a%a") do recTab[#recTab + 1] = i end

        for i = 1, #comTab do
            local obj = comTab[i]
            typeComb = false
            for d = 1, #recTab do local abj = recTab[d]
                if match(obj, "%a$") == match(abj, "%a$") then typeComb = true end
                if typeComb == true then break end
            end
        end

        for i = 1, #comTab do local obj = comTab[i]
            keyComb = false
            for d = 1, #recTab do
                local abj = recTab[d]
                if abj == obj or (match(obj, "%a") == "g" and match(obj, "%a$") == match(abj, "%a$")) then keyComb = true end
                if keyComb == false then break end
            end
        end
        if keyComb and typeComb then okayK = true end
    end
    stat.conditions.mkeyPass = okayK
    return okayK
end

---Wrapper for area test
---@param stat MacroStatContainer
---@param area RectDefinition
---@param id string
local function _testArea(stat, area, id)
    stat.conditions.areaPass = (area == nil or rv.mouseMonitorUtils:areaCheckWrapper(area, id))
    return stat.conditions.areaPass
end

---Check if a sequence of a certain name is runnign
---@param t string
---@param neg true?
---@return boolean
local function _testSequence(t, neg)
    local tres = (neg == nil)
    local k = rv.profile.nameMap[t]
    if rv.threading:taskStatus(k) == 1 then return tres end
    return not tres
end

---check if a flag is active
---@param varString string
---@param neg true?
---@return boolean
local function _testFlags(varString, neg)
    local tres = (neg == nil)
    --In case we ever do non- binary flags
    local varSplit = rv.utils.splitter(varString, "=")
    if #varSplit == 2 then if rv.scriptStates.flags[varSplit[1]] == varSplit[2] then return tres end
    elseif rv.scriptStates.flags[varString] then return tres end
    return not tres
end

---@param subString string
---@param arr EventInfo
---@param fam HardwareFamily
local function _singleTest(subString, arr, fam)
    if subString == "##" then return true end
    subString = rv.profile.unRename[subString] or subString
    if sub(subString, 1, 1) == "#" then
        local faRay = {}
        for h = 1, #rv.stringPresets.families do faRay[#faRay + 1] = rv.str:token(rv.stringPresets.families[h]) .. sub(subString, 2) end
        for d = 1, #faRay do if _singleTest(faRay[d], arr, fam) then return true end end
        return false
    elseif find(subString, "^%a") == nil then subString = fam .. subString end
    if sub(subString, -1) == "#" then return sub(arr.name, 1, 1) == sub(subString, 1, 1) end
    subString = rv.profile.unRename[subString] or subString
    return (arr.name == subString)
end

local function logicGate(truthTable, mode, eval)
    if type(truthTable) ~= "table" then truthTable = { truthTable } end
    mode = mode or "or"
    local sucs = {}
    for i = 1, #truthTable do local obj = truthTable[i]
        if type(obj) ~= "boolean" then obj = eval(obj) end
        if mode == "and" and obj == false then return false end
        if mode == "or" and obj == true then return true
        elseif obj == true then sucs[#sucs + 1] = 1 end
    end
    if #sucs == 0 and (mode == "nor" or mode == "nand" or mode == "xnor") then return true end
    if #sucs == #truthTable and (mode == "and" or mode == "xnor") then return true end
    if #sucs > 0 and #sucs ~= #truthTable and (mode == "nand" or mode == "xor") then return true end
    return false
end

---Test if a button is currently pressed
---@param t string
---@param neg? true
---@return boolean
local function testCurrentlyPressed(t, neg)
    local tres = (neg == nil)
    t = rv.profile.unRename[t] or t
    if rv.keyStates.keysDown[t] == nil then tres = not tres end
    return tres
end

---Check custom conditions as defined on keys
---@param t_cond (fun():boolean)[]|_ConditionOptions|fun():boolean
---@param mouse number
---@param virtu number
---@param fam string
---@param t_ident string
local function _conditionEvaluation(t_cond, mouse, virtu, fam, t_ident)
    local stat = rv.profile.macroIndex[t_ident].state
    local con = t_cond
    ---comment
    ---@param ind (fun():boolean)[]|_ConditionOptions|fun():boolean
    ---@return boolean
    local function _recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
        local recTest = ind or con
        if type(ind) == "boolean" then return ind end
        if type(recTest) == "function" then return recTest() end
        if type(recTest) == "table" then --recursively testing arrays ---@c
            return logicGate(recTest, (recTest--[[@as _ConditionOptions]]).logic or (recTest--[[@as _ConditionOptions]]).l, _recursiveTest)
        elseif type(recTest) == "number" then
            if recTest > 0 then recTest = fam .. recTest
            else recTest = "-" .. fam .. abs(recTest) end
        end

        local function testPreviouslyPressed(t, neg)
            local tres = (neg == nil)
            local virtoff = 0
            if virtu and rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown].name == fam .. mouse then virtoff = 1 end
            local testRay = rv.utils.splitter(t, "-")
            if #testRay > #rv.keyStates.lastKeysDown - 1 then return not tres end
            local truthRay = {}

            for g = 1, #testRay do
                local i = #testRay - g + 1
                local unit = testRay[i]
                local nopster = sub(unit, 1, 1) == "|"
                if nopster then unit = sub(unit, 2) end
                if (nopster == false and _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtoff], fam))
                    or (nopster == true and (not _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtoff], fam))) then
                    truthRay[#truthRay + 1] = 1
                end
            end
            return (#truthRay == #testRay) == tres
        end

        if type(recTest) == "string" then
            local desig = sub(recTest, 1, 1)
            if desig == "-" then return testCurrentlyPressed(sub(recTest, 2), true)
            elseif desig == "^" then return testPreviouslyPressed(sub(recTest, 2))
            elseif desig == "|" then return testPreviouslyPressed(sub(recTest, 2), 1)
            elseif desig == ":" then return _testSequence(sub(recTest, 2))
            elseif desig == "~" then return _testSequence(sub(recTest, 2), true)
            elseif desig == "." then return _testFlags(sub(recTest, 2))
            elseif desig == "*" then return _testFlags(sub(recTest, 2), true)
            else return testCurrentlyPressed(recTest) end
        end
        return false
    end

    if _recursiveTest(con) then
        stat.conditions.testPass = true
        return true
    end
    return false
end

---Wrapper for custom test conditions
---@param t_test (fun():boolean)[]|_ConditionOptions|fun():boolean|string[]
---@param t_mouse number
---@param t_virt number
---@param t_fam string
---@param t_ident string
local function _triggerTest(t_test, t_mouse, t_virt, t_fam, t_ident)
    return (t_test == nil) or _conditionEvaluation(t_test, t_mouse, t_virt, t_fam, t_ident)
end

---@param event Event
function MacroValidatorModule:skipConditions(event, _, _, macroID, singleTrigger)
    local fam, virtualState, keyNum = event.family, event.virtualType, event.keyNum
    local state = rv.profile.deviceState
    local macro = rv.profile.macroIndex[macroID]

    fam = fam or "m"
    if (rv.scriptStates.currentButton == keyNum or virtualState) and (virtualState or state[fam].blockedKey ~= keyNum) then
        --starting the process to test if the right modifiers are down.
        local mouseDir = event.direction or state[fam].dir
        local meta = macro.state

        meta.matchUp = mouseDir == "down" and macro.direction == "normal"
        meta.matchDown = mouseDir == "up" and macro.direction == "up"

        if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
        if mouseDir == "down" then meta.allPassed = true
        elseif mouseDir == "up" then meta.allPassed = nil end
        return (not singleTrigger) or meta.matchDown or meta.matchUp
    end
end

---@param event Event
---@param options MacroOptions|TimingStats
---@param macroID string
---@param singleTrigger boolean
function MacroValidatorModule:validateConditions(event, options, macroID, singleTrigger)
    local fam, virtualState, keyNum = event.family, event.virtualType, event.keyNum
    local config = rv.profile.config
    local state = rv.profile.deviceState
    local macro = rv.profile.macroIndex[macroID]

    fam = fam or "m"
    if (rv.scriptStates.currentButton == keyNum or virtualState) and (virtualState or state[fam].blockedKey ~= keyNum) then
        --starting the process to test if the right modifiers are down.
        local mouseDir = event.direction or state[fam].dir
        local meta = macro.state
        local lShift = (config.globalGShift and rv.profile.globalState.shift) or state[fam].shift
        local lMod = state[fam].modus
        local buttonCheck = false ---@type boolean|nil
        meta.matchUp = mouseDir == "down" and macro.direction == "normal"
        meta.matchDown = mouseDir == "up" and macro.direction == "up"

        if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
        if not virtualState then
            if mouseDir == "down" then
                buttonCheck = _testShift(meta, options.gshift or config.defaultShift, lShift) and
                    _testMode(meta, options.mode or config.defaultMode, lMod, fam) and
                    _testKey(meta, options.mkey, rv.scriptStates.mods) and
                    _testArea(meta, options.area, macroID) and
                    _triggerTest(options.condition, keyNum, virtualState, fam, macroID)
            elseif (mouseDir == "up" and meta.allPassed) then
                buttonCheck = (((options.unlock == nil or not rv.tbl:find(options.unlock, "shift")) and meta.conditions.shiftPass) or
                    _testShift(meta, options.gshift, lShift)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "mode")) and meta.conditions.modePass) or
                        _testMode(meta, options.mode, lMod, fam)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "mkeys")) and meta.conditions.mkeyPass) or
                        _testKey(meta, options.mkey, rv.scriptStates.mods)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "area")) and meta.conditions.areaPass) or
                        _testArea(meta, options.area, macroID)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "condition")) and meta.conditions.testPass) or
                        _triggerTest(options.condition, keyNum, virtualState, fam, macroID))
            end
        else
            buttonCheck = ((not options.gshift) or _testShift(meta, options.gshift or config.defaultShift, lShift)) and
                ((not options.mode) or _testMode(meta, options.mode or config.defaultMode, lMod, fam)) and
                ((not options.mkey) or _testKey(meta, options.mkey, rv.scriptStates.mods)) and
                ((not options.area) or _testArea(meta, options.area, macroID)) and
                ((not options.condition) or _triggerTest(options.condition, keyNum, virtualState, fam, macroID))
        end

        if buttonCheck then
            if mouseDir == "down" then meta.allPassed = true
            elseif mouseDir == "up" then meta.allPassed = nil end
            return meta.matchUp or meta.matchDown or not singleTrigger
        else return false
        end
    end
end

return MacroValidatorModule
