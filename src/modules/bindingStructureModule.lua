local tl, Base = ...---@type MainLibObject
local abs, sub, match, find, type, remove, tostring, pairs, gmatch, insert =
    math.abs,string.sub,string.match,string.find,type,table.remove,tostring,pairs,string.gmatch,table.insert
--=============================================================
---@class BindingStructureModule
---: The main framework functions for the script, controls parsing and execution of user defined bindings
local BindingStructureModule = Base:new()
---Property override for linked macros
---//TODO remove deprecated
---@param u1 table
---@param u2 table
---@param button string
local function _mergeLinkUpdate(u1, u2, button)
    if u1 == nil and u2 == nil then
        return false
    end
    u1 = tl.helperUtils.deepCopy((u1 or {}), nil, button)
    if tl.tbl:isSingleTypeTable(u1, "table") == false then
        u1 = {u1}
    end
    if tl.tbl:isSingleTypeTable(u2, "table") == false then
        u2 = {u2}
    end
    for i = 1, #u2 do
        insert(u1, 1, u2[i])
    end
    return u1
end

local function _tabulate(tbl, startTable, noOff, fallbackTable)
    local minus = noOff or 1
    local position = startTable or fallbackTable or {}
    local finalValue = tbl[#tbl]
    for p = 1, #tbl - minus do
        if type(tbl[p]) == "number" and tbl[p] < 1 then
            tbl[p] = #position + tbl[p]
        end
        position = position[tbl[p]]
    end
    return position, finalValue
end

---Resolves and updates the references in "l" type macros.
---@param link LinkMacro
---@param button string
---@param parentUpdate table
---@return GenericMacro
local function _resolveLink(link, button, parentUpdate)
    if tl.config.cacheLinks and link._meta.resolved then
        return tl.macroIndex[link._meta.resolved]
    end
    local lock = link
    local combinedID = ""
    local metaUpdate = parentUpdate
    while (lock.type == "l") and not tl.macroIndex[lock[1]]._dummy do -- If the binding is a link we override the original binding's properties with any new ones
        local lockTarget = lock[1]
        local rideNum = (lock.keepExisting == 1) and 4 or 3
        local lack
        local unlock = tl.macroIndex[lockTarget]
        combinedID = combinedID .. lock.pID .. unlock.pID
        if tl.tbl:isContainer(lock) then
            lack = tl.helperUtils.deepCopy(lock)
            for i = 1, #lack do
                lack[i] = _resolveLink(lack[i], button, metaUpdate)
            end
            lack.pID = combinedID
            ---@type MacroStatContainer
            tl.macroIndex[combinedID] = tl.macroIndex[combinedID] or lack
            return lack
        else
            local currentUpdate = metaUpdate or lock.update
            metaUpdate = _mergeLinkUpdate(currentUpdate, unlock.update, button)
            lock = tl.tbl:intersect(unlock, lock, rideNum, lock.keepExisting)
            lack = tl.helperUtils.deepCopy(lock, nil, button)
            if metaUpdate ~= false and lack.type ~= "l" then
                if type(metaUpdate) == "table" then
                    local function _replaceCycle(reptable)
                        local h = reptable[1]
                        if type(h) ~= "table" then
                            h = {h}
                        end
                        local targTab, valName = _tabulate(h, nil, nil, lack)
                        local endInsert = reptable[2]
                        if type(reptable[4]) == "string" then
                            if type(reptable[2]) ~= "table" then
                                reptable[2] = {reptable[2]}
                            end
                            local importer = _resolveLink(tl.macroIndex[reptable[4]], button)
                            endInsert, _ = _tabulate(reptable[2], importer, 0, lack)
                        end

                        if reptable[3] == nil or reptable[3] == "replace" then
                            targTab[valName] = endInsert
                        elseif reptable[3] == "insert" then
                            insert(targTab, valName, endInsert)
                        elseif reptable[3] == "remove" then
                            local g = reptable[2]
                            if type(g) == "string" then
                                targTab[valName][g] = nil
                            elseif g > 1 then
                                local posi = valName - 1
                                for _ = 1, abs(g) do
                                    remove(targTab, posi)
                                    posi = posi - 1
                                end
                            else
                                local posi = valName
                                for _ = 1, g do
                                    remove(targTab, posi)
                                end
                            end
                        end
                    end

                    if tl.tbl:isSingleTypeTable(metaUpdate, "table") == false then
                        _replaceCycle(metaUpdate)
                    else
                        for i = 1, #metaUpdate do
                            _replaceCycle(metaUpdate[i])
                        end
                    end
                    lock = lack
                end
            end
            lock.pID = combinedID
            ---@type MacroStatContainer
            tl.macroIndex[combinedID] = tl.macroIndex[combinedID] or lock
        end
    end
    if tl.config.cacheLinks then
        lock._meta.resolved = combinedID
        setmetatable(link, getmetatable(lock))
    end
    return lock
end

---Parse collection of macros into separate macro calls
---@private
---@param keyN number
---@param fam string
---@param lock table<integer,GenericMacro>|GenericMacro
---@param virt number
---@param virtrect string
---@param originator string
function BindingStructureModule:_unwrapMacro(keyN, fam, lock, virt, virtrect, originator)
    if tl.tbl:isContainer(lock) then
        for num = 1, #lock do
            local coms = lock[num]
            self:_unwrapMacro(keyN, fam, coms, virt, virtrect, originator)
        end
    else
        self:launchMacro(keyN, fam, lock, virt, virtrect, originator)
    end
end

local function _testShift(stat, shifted, lShift)
    stat.conditions.shiftPass = type(shifted) == "number" and (shifted == 2 or (shifted == lShift))
    return stat.conditions.shiftPass
end

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
        local modeRay = tl.deviceState[fam].modeConfig
        if modeRay[lMod] and modeRay[lMod][1] == moTest then
            stat.conditions.modePass = rVal
            return rVal
        end
        return not rVal
    elseif type(moTest) == "table" then
        rVal = false
        for i = 1, #moTest do
            local obj = moTest[i]
            if (type(obj) == "number" and obj < 0) or (type(obj) == "string" and sub(obj, 1, 1) == "-") then
                if _testMode(stat, modi, lMod, fam, obj) == false then
                    return false
                end
            elseif _testMode(stat, modi, lMod, fam, obj) then
                rVal = true
            end
        end
        return rVal
    end
end

---function for testing if the correct modifiers are pressed.
---@param stat MacroStatContainer
---@param mkeys string
---@param lModif number
local function _testKey(stat, mkeys, lModif)
    local okayK = false
    if
        (mkeys == "no" and (lModif == nil or lModif == 0 or #lModif == 0)) or
            (mkeys ~= "no" and (mkeys == nil or mkeys == 0 or mkeys == "" or lModif == mkeys))
     then
        okayK = true
    elseif type(lModif) == "string" and type(mkeys) == "string" then
        local typeComb = false
        local keyComb = false
        local comTab = {}
        local recTab = {}

        for i in gmatch(mkeys, "%a%a") do
            comTab[#comTab + 1] = i
        end
        for i in gmatch(lModif, "%a%a") do
            recTab[#recTab + 1] = i
        end

        for i = 1, #comTab do
            local obj = comTab[i]
            typeComb = false
            for d = 1, #recTab do
                local abj = recTab[d]
                if match(obj, "%a$") == match(abj, "%a$") then
                    typeComb = true
                end
                if typeComb == true then
                    break
                end
            end
        end

        for i = 1, #comTab do
            local obj = comTab[i]
            keyComb = false
            for d = 1, #recTab do
                local abj = recTab[d]
                if abj == obj or (match(obj, "%a") == "g" and match(obj, "%a$") == match(abj, "%a$")) then
                    keyComb = true
                end
                if keyComb == false then
                    break
                end
            end
        end
        if keyComb and typeComb then
            okayK = true
        end
    end
    stat.conditions.keyPass = okayK
    return okayK
end

---Wrapper for area test
---@param stat MacroStatContainer
---@param area AreaContainer
local function _testArea(stat, area)
    stat.conditions.areaPass = (area == nil or tl.mouseMonitorUtils:areaCheckWrapper(area))
    return stat.conditions.areaPass
end

local function _testAttributes(subject, subRay)
    if #subject == 1 then
        return true
    end
    for o = 1, #subject do
        local unit = tl.helperUtils.splitter(subject[o], "=")
        local key = unit[1]
        local val = unit[2]
        if tostring(subRay[key]) ~= val then
            return false
        end
    end
    return true
end

local function _testSequence(t, neg)
    local tres = (neg == nil)
    if tl.coroutines.taskList[t] ~= nil and not tl.coroutines.taskList[t].paused then
        return tres
    end
    return not tres
end

local function _testFlags(varString, neg)
    local tres = (neg == nil)
    local varSplit = tl.helperUtils.splitter(varString, "=")
    if #varSplit == 2 then
        if tl.scriptStates.flags[varSplit[1]] == varSplit[2] then
            return tres
        end
    elseif tl.scriptStates.flags[varString] then
        return tres
    end
    return not tres
end

local function _singleTest(subString, arr, fam)
    subString = tl.activeProfile.unRename[subString] or subString
    if sub(subString, 1, 1) == "#" then
        local faRay = {}
        for h = 1, #tl.stringPresets.families do
            faRay[#faRay + 1] = tl.str.token(tl.stringPresets.families[h]) .. sub(subString, 2)
        end
        for d = 1, #faRay do
            if _singleTest(faRay[d], arr, fam) then
                return true
            end
        end
        return false
    elseif find(subString, "^%a") == nil then
        subString = fam .. subString
    end
    if sub(subString, -1) == "#" then
        return sub(arr.name, 1, 1) == sub(subString, 1, 1)
    end
    subString = tl.activeProfile.unRename[subString] or subString
    return (arr.name == subString)
end

---Check custom conditions as defined on keys
---@param t_test TestStruct
---@param mouse number
---@param virtu number
---@param fam string
---@param t_dir string
---@param t_ident string
local function _testEvaluation(t_test, mouse, virtu, fam, t_dir, t_ident)
    ---@type MacroStatContainer
    local stat = tl.macroIndex[t_ident]._meta
    local tes = t_test

    local function _recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
        local hasAttribute
        local recTest = ind or tes
        if type(ind) == "boolean" then
            return ind
        end

        if type(recTest) == "table" then --recursively testing arrays
            local m = recTest.logic or "or"
            local sucs = {}
            for i = 1, #recTest do
                local obj = recTest[i]
                local subtest = _recursiveTest(obj)
                if m == "and" and subtest == false then
                    return false
                end
                if m == "or" and subtest == true then
                    return true
                elseif subtest == true then
                    sucs[#sucs + 1] = 1
                end
            end

            if #sucs == 0 and (m == "nor" or m == "nand" or m == "xnor") then
                return true
            end
            if #sucs == #recTest and (m == "and" or m == "xnor") then
                return true
            end
            if #sucs > 0 and #sucs ~= #recTest and (m == "nand" or m == "xor") then
                return true
            end

            return false
        elseif type(recTest) == "number" then
            if recTest > 0 then
                recTest = fam .. recTest
            else
                recTest = "-" .. fam .. abs(recTest)
            end
        end

        local function testCurrentlyPressed(t, neg)
            local attriT
            if hasAttribute then
                attriT = tl.helperUtils.splitter(t, "@")
                t = remove(attriT, 1)
            end
            local tres = (neg == nil)
            t = tl.activeProfile.unRename[t] or t
            if sub(t, 1, 1) == "#" then
                local faRay = {}
                for h = 1, #tl.stringPresets.families do
                    faRay[#faRay + 1] = tl.str.token(tl.stringPresets.families[h]) .. sub(t, 2)
                end
                faRay.mode = "or"
                if _recursiveTest(faRay) == false then
                    tres = not tres
                end
            elseif find(t, "^%a") == nil then
                t = fam .. t
            end
            if sub(t, -1) == "#" then
                local sFam = sub(t, 1, 1)
                for k, v in pairs(tl.keyStates.keysDown) do
                    if
                        type(k) == "string" and k ~= fam .. mouse and sub(k, 1, 1) == sFam and
                            ((not hasAttribute) or _testAttributes(attriT, v))
                     then
                        return tres
                    end
                end
                return not tres
            end
            t = tl.activeProfile.unRename[t] or t
            if
                tl.keyStates.keysDown[t] == nil or
                    (hasAttribute and _testAttributes(t, tl.keyStates.keysDown[t]) == false)
             then
                tres = not tres
            end
            return tres
        end

        local function testPreviouslyPressed(t, neg)
            local tres = (neg == nil)
            local virtoff = 0
            if virtu and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].name == fam .. mouse then
                virtoff = 1
            end
            local testRay = tl.helperUtils.splitter(t, "-")
            if #testRay > #tl.keyStates.lastKeysDown - 1 then
                return not tres
            end
            local truthRay = {}

            for g = 1, #testRay do
                local i = #testRay - g + 1
                local unit = testRay[i]
                local attriT
                if hasAttribute then
                    attriT = tl.helperUtils.splitter(unit, "@")
                    unit = remove(attriT, 1)
                end
                local nopster = sub(unit, 1, 1) == "|"
                if nopster then
                    unit = sub(unit, 2)
                end
                if
                    (nopster == false and
                        _singleTest(unit, tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff], fam) and
                        (not hasAttribute or
                            _testAttributes(attriT, tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff]))) or
                        (nopster == true and
                            (not _singleTest(
                                unit,
                                tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff],
                                fam
                            ) or
                                (hasAttribute and
                                    _testAttributes(
                                        attriT,
                                        tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff]
                                    ) == false)))
                 then
                    truthRay[#truthRay + 1] = 1
                end
            end
            return (#truthRay == #testRay) == tres
        end

        if type(recTest) == "string" then
            hasAttribute = (#tl.helperUtils.splitter(recTest, "@") > 1)
            local desig = sub(recTest, 1, 1)
            if desig == "-" then
                return testCurrentlyPressed(sub(recTest, 2), 1)
            elseif desig == "^" then
                return testPreviouslyPressed(sub(recTest, 2))
            elseif desig == "|" then
                return testPreviouslyPressed(sub(recTest, 2), 1)
            elseif desig == ":" then
                return _testSequence(sub(recTest, 2))
            elseif desig == "~" then
                return _testSequence(sub(recTest, 2), 1)
            elseif desig == "." then
                return _testFlags(sub(recTest, 2))
            elseif desig == "*" then
                return _testFlags(sub(recTest, 2), 1)
            else
                return testCurrentlyPressed(recTest)
            end
        end
    end
    if _recursiveTest(tes) then
        stat.conditions.testPass = true
        return true
    end
    return false
end

---Wrapper for custom test conditions
---@param t_test TestStruct
---@param t_mouse number
---@param t_virt number
---@param t_fam string
---@param t_dir string
---@param t_ident string
local function _triggerTest(t_test, t_mouse, t_virt, t_fam, t_dir, t_ident)
    return (t_test == nil) or _testEvaluation(t_test, t_mouse, t_virt, t_fam, t_dir, t_ident)
end

function BindingStructureModule:getMacroClass(def)
  local type = tl.tbl:identifyTableType(def)
  if type == "group" then
    return tl:classImport("MacroGroup")
  elseif type == "macro" then
    local macroType = tl.classMap[def.type]
    return tl:classImport(macroType)
  end
  return false
end

---quick and dirty keyGen call
---@param bar GenericMacro
---@param fam string
function BindingStructureModule:quickMacro(bar, fam)
    if tl.tbl:isContainer(bar) == false then
        self:launchMacro(0, fam, bar, 5)
    else
        for g = 1, #bar do
            local com = bar[g]
            self:launchMacro(0, fam, com, 5)
        end
    end
end

---the main program for parsing key commands
---@param keyNum number
---@param fam string
---@param macro table<integer,GenericMacro>|GenericMacro
---@param virtualState number
---@param simDirection string
---@param originator string
function BindingStructureModule:launchMacro(keyNum, fam, macro, virtualState, simDirection, originator)
    local pKey = tl.activeProfile.assign.key[(fam or "") .. keyNum]
    if not macro then
        macro = pKey
    end
    if virtualState then
        pKey = macro
    end
    if macro == nil then
        return
    end
    local playState = "played"
    local playStorage = (((not fam) or virtualState) and {}) or tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown]
    fam = fam or "m"
    playStorage[playState] = (playStorage[playState] or 0)
    if type(macro) ~= "table" then
        macro = {macro}
    elseif tl.tbl:isContainer(macro) then
        return self:_unwrapMacro(keyNum, fam, macro, virtualState, simDirection, originator)
    end
    local played = 0
    if
        (tl.scriptStates.currentButton == keyNum or virtualState) and
            (virtualState or tl.deviceState[fam].conKey ~= keyNum)
     then --starting the process to test if the right modifiers are down.
        ---@type MouseEventContainer
        local ev = {
            type = macro.type,
            unlock = macro.unlock or pKey.unlock,
            ID = macro.pID or pKey.pID,
            mkeys = macro.mkey or pKey.mkey,
            area = macro.area or pKey.area,
            simDirection = macro.simDir or pKey.simDir or simDirection,
            testCondition = macro.test or pKey.test,
            mode = macro.mode or pKey.mode,
            shifted = macro.gshift or pKey.gshift,
            pDir = macro.direction or pKey.direction or "normal"
        }

        local mouseDir = (virtualState and ev.simDirection) or tl.deviceState[fam].dir
        local meta = macro.state or {}
        local lShift = tl.deviceState[fam].shift
        local lMod = tl.deviceState[fam].modus
        local buttonCheck = false

        meta.matchUp = mouseDir == "down" and ev.pDir == "normal"
        meta.matchDown = mouseDir == "up" and ev.pDir == "up"

        if meta.matchUp or mouseDir == "down" or virtualState then
            meta.conditions = {}
        end

        if not virtualState then
            if mouseDir == "down" then
                buttonCheck =
                    _testShift(meta, ev.shifted or tl.activeProfile.config.defaultShift, lShift) and
                    _testMode(meta, ev.mode or tl.activeProfile.config.defaultMode, lMod, fam) and
                    _testKey(meta, ev.mkeys, tl.scriptStates.mods) and
                    _testArea(meta, ev.area) and
                    _triggerTest(ev.testCondition, keyNum, virtualState, fam, mouseDir, ev.ID)
            elseif (mouseDir == "up" and meta.allPassed) then
                buttonCheck =
                    (((ev.unlock == nil or not tl.tbl:find(ev.unlock, "shift")) and meta.conditions.shiftPass) or
                    _testShift(meta, ev.shifted, lShift)) and
                    (((ev.unlock == nil or not tl.tbl:find(ev.unlock, "mode")) and meta.conditions.modePass) or
                        _testMode(meta, ev.mode, lMod, fam)) and
                    (((ev.unlock == nil or not tl.tbl:find(ev.unlock, "mkeys")) and meta.conditions.keyPass) or
                        _testKey(meta, ev.mkeys, tl.scriptStates.mods)) and
                    (((ev.unlock == nil or not tl.tbl:find(ev.unlock, "area")) and meta.conditions.areaPass) or
                        _testArea(meta, ev.area)) and
                    (((ev.unlock == nil or not tl.tbl:find(ev.unlock, "test")) and meta.conditions.testPass) or
                        _triggerTest(ev.testCondition, keyNum, virtualState, fam, mouseDir, ev.ID))
            end
        else
            buttonCheck =
                (not ev.shifted or _testShift(meta, ev.shifted or tl.config.defaultShift, lShift)) and
                ((not ev.mode) or _testMode(meta, ev.mode or tl.config.defaultMode, lMod, fam)) and
                ((not ev.mkeys) or _testKey(meta, ev.mkeys, tl.scriptStates.mods)) and
                ((not ev.area) or _testArea(meta, ev.area)) and
                ((not ev.testCondition) or _triggerTest(ev.testCondition, keyNum, virtualState, fam, mouseDir, ev.ID))
        end
        if buttonCheck then
            if mouseDir == "down" then
                meta.allPassed = true
            elseif mouseDir == "up" then
                meta.allPassed = nil
            end
            if ev.type == "l" then
                return self:launchMacro(keyNum, fam, _resolveLink(macro), virtualState, ev.simDirection, originator)
            end
            local simFam = macro.family or pKey.family
            local consume = macro.consume or pKey.consume
            if tl.config.enableLinting and tl.lint.lintErrors[fam .. keyNum] then
                if tl.lint.lintErrors._lastDisplayedMessage ~= tl.lint.lintErrors[fam .. keyNum] then
                    tl:put(tl.lint.lintErrors[fam .. keyNum])
                    tl.lint.lintErrors._lastDisplayedMessage = tl.lint.lintErrors[fam .. keyNum]
                end
                if tl.config.abortOnLintError then
                    return
                end
            end
            if tl.scriptStates.docMode and not virtualState and macro.type ~= "doc" then
                tl.macros:documentKey(macro, fam, keyNum)
            end
            ev.type = ev.type or "k"
            local tabs =
                (((virtualState and virtualState ~= 2 and ev.simDirection == nil) or meta.matchUp or meta.matchDown) and
                tl.wrapperFunctions.funcRayD) or
                tl.wrapperFunctions.defaultFuncs
            if (virtualState and virtualState ~= 2 and ev.simDirection == nil) then
                mouseDir = nil
            end
            if tabs[ev.type] then
                tabs[ev.type].macro(
                    macro,
                    mouseDir,
                    keyNum,
                    virtualState,
                    fam,
                    simFam,
                    originator,
                    ev.pDir,
                    meta.matchUp or meta.matchDown
                )
                played = 1
            end
            tl.deviceState[fam].conKey = (not (not virtualState and (consume == 1 or consume == 3)) and 0) or keyNum
        end
    end
    playStorage[playState] = played
end

return BindingStructureModule
