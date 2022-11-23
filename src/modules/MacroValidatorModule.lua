local rv = ... ---@type Revenant
local abs, sub, match, find, type, gmatch, tonumber, next = math.abs, string.sub, string.match, string.find, type, string.gmatch, tonumber, next

--[[=============================================================]] --
---@alias LogicMode "and"|"or"|"xor"|"xnor"|"nand"|"nor"
--[[=============================================================]] --
---@class MacroValidatorModule:BaseClass controls parsing and execution of user defined bindings
local MacroValidatorModule = rv.baseClass:new()
---check if the g-shift is in the right state
---@param stat MacroStatContainer Statistics of the current macro
---@param shifted number Shift option of the event
---@param lShift number Shift state of the device
local function _testShift(stat, shifted, lShift)
    stat.conditions.shiftPass = type(shifted) == "number" and (shifted == 2 or (shifted == lShift)) ---if the shift option is 2 it always passes
    return stat.conditions.shiftPass
end

---Check if the mode is in the right state
---@param stat MacroStatContainer Statistics of the current macro
---@param modi l<string|integer> mode selector of the macro
---@param lMod integer current mode of the device
---@param fam FamilyToken the device to check
---@param manual? integer|string check for a manual mode that might not be the mode of the event
---@return boolean? #true if the mode is in the right state
local function _testMode(stat, modi, lMod, fam, manual)
    local moTest = manual or modi
    local rVal = true ---return value
    if type(moTest) == "number" then
        if moTest < 0 then ---negative search values negate the result and excludes modes
            rVal = false
            moTest = abs(moTest)
        end
        if moTest == 0 or moTest == tonumber(lMod) then ---a mode of 0 always passes
            stat.conditions.modePass = rVal
            return rVal
        end
        return not rVal
    elseif type(moTest) == "string" then --checking mode strings
        if sub(moTest, 1, 1) == "-" then
            rVal = false ---"negative" search strings negate the result and excludes modes
            moTest = sub(moTest, 2)
        end
        local modeRay = rv.profile.deviceState[fam].modeConfig
        if modeRay[lMod] and modeRay[lMod][1] == moTest then --resolving mode names for the device
            stat.conditions.modePass = rVal
            return rVal
        end
        return not rVal
    elseif type(moTest) == "table" then ---checking multiple modes
        ---negative mode checks on the current macro
        local negs = {} ---@type (string|integer)[]
        ---positive mode checks on the current macro
        local posis = {} ---@type (string|integer)[]
        for i = 1, #moTest do local obj = moTest[i] ---separating mode cheks into positive and negative checks
            local target = posis
            if type(obj) == "number" and obj < 0 then target = negs
            elseif type(obj) == "string" and sub(obj, 1, 1) == "-" then target = negs end
            target[#target + 1] = obj
        end
        local pnum, nnum = #posis, #negs
        --checking negative modes before positive ones, short circuiting as fast as possible
        for i = 1, nnum do if _testMode(stat, modi, lMod, fam, negs[i]) == false then return false end end
        for i = 1, pnum do if _testMode(stat, modi, lMod, fam, posis[i]) == true then return true end end
        return pnum == 0 or nnum ~= 0
    end
end

---function for testing if the correct modifiers are pressed.
---@param stat MacroStatContainer Stats of the current macro
---@param mkeys string combination of modifier names
---@param lModif table<string,true> modifiers of the current event
---@return boolean #true if the right modifiers are pressed
local function _testKey(stat, mkeys, lModif)
    local okayK = false
    if (mkeys == "no" and (lModif == nil or lModif == 0 or not next(lModif))) or
        (mkeys ~= "no" and (mkeys == nil or mkeys == 0 or mkeys == "")) then
        okayK = true --true if no modifier is pressed or required
    elseif type(lModif) == "table" and type(mkeys) == "string" then
        local strict = rv.profile.config.strictModifiers
        if not strict and lModif[mkeys] == true then okayK = true else
            okayK = true
            local comTab = {} ---@type table<string,true>

            for mod in gmatch(mkeys, "%a%a") do
                if lModif[mod] ~= true then okayK = false break end --false if q requirement isn't met
                if strict then comTab[mod] = true end ---no strict mode, no need to save
            end

            if strict then --making sure no additional modifiers are pressed, ignoring "lock" type modifiers
                for kMod in pairs(lModif) do
                    if sub(kMod, 1, 1) ~= "g" and sub(kMod, 2, 2) ~= "l" and comTab[kMod] ~= true then okayK = false break end
                end
            end

        end
    end
    stat.conditions.mkeyPass = okayK
    return okayK
end

---Wrapper for area test
---@param stat MacroStatContainer Statistics of the current macro
---@param area RectDefinition The rectangle that needs to contain the mouse (or not if negative)
---@param id string the macro id
---@return boolean #true if test was passed
local function _testArea(stat, area, id)
    stat.conditions.areaPass = (area == nil or rv.mouseMonitorUtils:areaCheckWrapper(area, id)) --forwarding to monitor utils
    return stat.conditions.areaPass
end

---Check if a sequence of a certain name is running
---@param t string the name of the sequence
---@param neg true? negate the result
---@return boolean #true if test was passed
local function _testSequence(t, neg)
    local tres = (neg == nil)
    local k = rv.profile.nameMap[t] ---the id corresponding to the name
    if rv.threading:taskStatus(k) == 1 then return tres end --if the sequence is running there'll be a task with its id
    return not tres
end

---check if a flag is active
---@param varString string the name of the flag
---@param neg true? negate the result
---@return boolean #true if test was passed
local function _testFlags(varString, neg)
    local tres = (neg == nil)
    --In case we ever do non- binary flags, currently useless
    local varSplit = rv.utils.splitter(varString, "=")
    if #varSplit == 2 then if rv.scriptStates.flags[varSplit[1]] == varSplit[2] then return tres end
    elseif rv.scriptStates.flags[varString] then return tres end
    return not tres
end

---test if a key matchcode fits a specific event
---@param subString string the event code of an event, can include the # wildcard
---@param eventInfo EventInfo record of a key event
---@param fam HardwareFamily family that triggered the test
---@return boolean #true if the matchcode fits the event
local function _singleTest(subString, eventInfo, fam)
    if subString == "##" then return true end
    subString = rv.profile.unRename[subString] or subString
    if sub(subString, 1, 1) == "#" then --the character # designates that we are including all possible families
        local faRay = {} ---@type string[]
        for h = 1, #rv.stringPresets.families do faRay[#faRay + 1] = rv.str:token(rv.stringPresets.families[h]) .. sub(subString, 2) end
        for d = 1, #faRay do if _singleTest(faRay[d], eventInfo, fam) then return true end end --short circuit after first positive
        return false
    elseif find(subString, "^%a") == nil then subString = fam .. subString end
    if sub(subString, -1) == "#" then return eventInfo.familyToken == sub(subString, 1, 1) end --if the last character is a wildcard only the family counts
    subString = rv.profile.unRename[subString] or subString
    return (eventInfo.name == subString)
end

---simulates a circuit-like logic gate
---@param truthTable any[] An array of either boolean values or values that will be processed into boolean values
---@param mode LogicMode The evaluation mode to after compiling all truth values
---@param eval fun(...:any):boolean the function to process all values that aren't already boolean
---@return boolean #the final truth value
local function logicGate(truthTable, mode, eval)
    if type(truthTable) ~= "table" then truthTable = { truthTable } end
    mode = mode or "or" --setting the default mode
    ---keeping track of succesful passes
    local sucs = {} ---@type 1[]
    for i = 1, #truthTable do local obj = truthTable[i] --iterating through all results
        if type(obj) ~= "boolean" then obj = eval(obj) end
        if mode == "and" and obj == false then return false end --both 'and' and 'or' short circuit after a single result
        if mode == "or" and obj == true then return true
        elseif obj == true then sucs[#sucs + 1] = 1 end
    end --now we go through all the other logic configurations
    if #sucs == 0 and (mode == "nor" or mode == "nand" or mode == "xnor") then return true end
    if #sucs == #truthTable and (mode == "and" or mode == "xnor") then return true end
    if #sucs > 0 and #sucs ~= #truthTable and (mode == "nand" or mode == "xor") then return true end
    return false
end

---Test if a button is currently pressed
---@param t integer|string number or name of a key
---@param neg? true if true negate the result
---@return boolean #true if key is pressed
local function testCurrentlyPressed(t, neg)
    local tres = (neg == nil)
    t = rv.profile.unRename[t] or t --resolving key name
    if rv.keyStates.keysDown[t] == nil then tres = not tres end
    return tres
end

---Check custom conditions as defined on keys
---@param t_cond (fun():boolean)[]|_ConditionOptions|fun():boolean any sort of condition
---@param key integer the number of the pressed key
---@param virtu? integer the virtual state of the key
---@param fam HardwareFamily the device family of the key
---@param t_ident string the current macro id
local function _conditionEvaluation(t_cond, key, virtu, fam, t_ident)
    local stat = rv.profile.macroIndex[t_ident].state
    local con = t_cond
    ---comment
    ---@param ind string|(fun():boolean)[]|_ConditionOptions|fun():boolean
    ---@return boolean
    local function _recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
        local recTest = ind or con
        if type(ind) == "boolean" then return ind end
        if type(recTest) == "function" then return recTest() end
        if type(recTest) == "table" then --recursively testing arrays
            return logicGate(recTest, (recTest--[[@as _ConditionOptions]]).logic or (recTest--[[@as _ConditionOptions]]).l, _recursiveTest)
        elseif type(recTest) == "number" then
            if recTest > 0 then recTest = fam .. recTest
            else recTest = "-" .. fam .. abs(recTest) end
        end

        ---checks on or more previously pressed keys
        ---@param t string name of a key
        ---@param neg? true reverse the result
        ---@return boolean #true if previously pressed
        local function testPreviouslyPressed(t, neg)
            local tres = (neg == nil)
            local virtoff = 0 ---virtual offset
            if virtu and rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown].name == fam .. key then virtoff = 1 end
            local testRay = rv.utils.splitter(t, "-") ---multiple pressed keys can be queried separated with "-"
            if #testRay > #rv.keyStates.lastKeysDown - 1 then return not tres end --if we don't have enough keys saved, the test fails
            ---array of successful checks
            local truthRay = {} ---@type 1[]

            for g = 1, #testRay do
                local i = #testRay - g + 1 --iterating all test cases
                local unit = testRay[i]
                local nopster = sub(unit, 1, 1) == "|" --if prepended with "|", the test is negative
                if nopster then unit = sub(unit, 2) end --removing the "|"
                if (nopster == false and _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtoff], fam))
                    or (nopster == true and (not _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtoff], fam))) then
                    truthRay[#truthRay + 1] = 1 --adding a successful check to the array
                end
            end
            return (#truthRay == #testRay) == tres
        end

        if type(recTest) == "string" then
            local prefix = sub(recTest, 1, 1) --If the first character is a special prefix, we trigger the specific checks.
            if prefix == "-" then return testCurrentlyPressed(sub(recTest, 2), true)
            elseif prefix == "^" then return testPreviouslyPressed(sub(recTest, 2))
            elseif prefix == "|" then return testPreviouslyPressed(sub(recTest, 2), true)
            elseif prefix == ":" then return _testSequence(sub(recTest, 2))
            elseif prefix == "~" then return _testSequence(sub(recTest, 2), true)
            elseif prefix == "." then return _testFlags(sub(recTest, 2))
            elseif prefix == "*" then return _testFlags(sub(recTest, 2), true)
            else return testCurrentlyPressed(recTest) end --Just executing the normal test
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
---@param t_test? (fun():boolean)[]|_ConditionOptions|fun():boolean|string[]
---@param t_mouse integer number of the key
---@param t_virt? integer virtual state of the event
---@param t_fam string family of the event
---@param t_ident string the macro id
local function _triggerTest(t_test, t_mouse, t_virt, t_fam, t_ident)
    return (t_test == nil) or _conditionEvaluation(t_test, t_mouse, t_virt, t_fam, t_ident)
end

---Checking basic conditions like key number and directions but skipping all user defined conditions
---@param event Event
---@param macroID string
---@param singleTrigger boolean
---@return boolean?
function MacroValidatorModule:skipConditions(event, macroID, singleTrigger)
    local fam, virtualState, keyNum = event.family, event.virtualType, event.keyNum
    local state = rv.profile.deviceState
    local macro = rv.profile.macroIndex[macroID]

    fam = fam or "m"
    if (rv.scriptStates.currentButton == keyNum or virtualState) and (virtualState or state[fam].blockedKey ~= keyNum) then
        --starting the process to test if the right modifiers are down.
        local mouseDir = event.direction or state[fam].dir
        local meta = macro.state
        --comparing data on the macro to the current mouse state
        meta.matchUp = mouseDir == "down" and macro.direction == "normal"
        meta.matchDown = mouseDir == "up" and macro.direction == "up"

        if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
        if mouseDir == "down" then meta.allPassed = true
        elseif mouseDir == "up" then meta.allPassed = nil end
        return (not singleTrigger) or meta.matchDown or meta.matchUp
    end
end

---The main evaluation function all macros need to satisfy before executing
---@param event Event The current event
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
                buttonCheck = (
                    ((options.unlock == nil or not rv.tbl:find(options.unlock, "shift")) and meta.conditions.shiftPass) or
                        _testShift(meta, options.gshift, lShift)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "mode")) and meta.conditions.modePass) or
                        _testMode(meta, options.mode, lMod, fam)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "mkeys")) and meta.conditions.mkeyPass) or
                        _testKey(meta, options.mkey, rv.scriptStates.mods)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "area")) and meta.conditions.areaPass) or
                        _testArea(meta, options.area, macroID)) and
                    (((options.unlock == nil or not rv.tbl:find(options.unlock, "condition")) and meta.conditions.testPass) or
                        _triggerTest(options.condition, keyNum, virtualState, fam, macroID)
                    )
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