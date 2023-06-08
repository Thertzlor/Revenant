local rv = ... ---@type Revenant
local abs, sub, find, type, gmatch, tonumber, next = math.abs, string.sub, string.find, type, string.gmatch, tonumber, next

--[[=============================================================]] --
---@alias LogicMode "and"|"or"|"xor"|"xnor"|"nand"|"nor"
--[[=============================================================]] --
---@class MacroValidatorModule:BaseClass #controls parsing and execution of user defined bindings
local MacroValidatorModule = rv.baseClass:new()
---check if the g-shift is in the right state
---@param stat MacroStatContainer #Statistics of the current macro
---@param shifted number Shift #option of the event
---@param lShift number Shift #state of the device
local function _testShift(stat, shifted, lShift)
   stat.conditions.shiftPass = type(shifted) == "number" and (shifted == 2 or (shifted == lShift)) ---if the shift option is 2 it always passes
   return stat.conditions.shiftPass
end

---Check if the mode is in the right state
---@param stat MacroStatContainer #Statistics of the current macro
---@param modi l<string|integer> #mode selector of the macro
---@param lMod integer #current mode of the device
---@param fam FamilyToken #the device to check
---@param manual? integer|string #check for a manual mode that might not be the mode of the event
---@return boolean? #true if the mode is in the right state
local function _testMode(stat, modi, lMod, fam, manual)
   local testMode = manual or modi
   local retVal = true ---return value
   if type(testMode) == "number" then
      if testMode < 0 then ---negative search values negate the result and excludes modes
         retVal = false
         testMode = abs(testMode)
      end
      if testMode == 0 or testMode == tonumber(lMod) then ---a mode of 0 always passes
         stat.conditions.modePass = retVal
         return retVal
      end
      return not retVal
   elseif type(testMode) == "string" then -- checking mode strings
      if sub(testMode, 1, 1) == "-" then
         retVal = false ---"negative" search strings negate the result and excludes modes
         testMode = sub(testMode, 2)
      end
      local modeRay = rv.profile.deviceState[fam].modeConfig
      if modeRay[lMod] and modeRay[lMod][1] == testMode then -- resolving mode names for the device
         stat.conditions.modePass = retVal
         return retVal
      end
      return not retVal
   elseif type(testMode) == "table" then ---checking multiple modes
      ---negative mode checks on the current macro
      local negatives = {} ---@type (string|integer)[]
      ---positive mode checks on the current macro
      local positives = {} ---@type (string|integer)[]
      for i = 1, #testMode do
         local obj = testMode[i] ---separating mode cheks into positive and negative checks
         local target = positives
         if type(obj) == "number" and obj < 0 then
            target = negatives
         elseif type(obj) == "string" and sub(obj, 1, 1) == "-" then
            target = negatives
         end
         target[#target + 1] = obj
      end
      local posNum, negNum = #positives, #negatives
      -- checking negative modes before positive ones, short circuiting as fast as possible
      for i = 1, negNum do if _testMode(stat, modi, lMod, fam, negatives[i]) == false then return false end end
      for i = 1, posNum do if _testMode(stat, modi, lMod, fam, positives[i]) == true then return true end end
      return posNum == 0 or negNum ~= 0
   end
end

---function for testing if the correct modifiers are pressed.
---@param stat MacroStatContainer Stats of the current macro
---@param modifierString string combination of modifier names
---@param modifiers table<string,true> modifiers of the current event
---@return boolean #true if the right modifiers are pressed
local function _testKey(stat, modifierString, modifiers)
   local testPass = false
   if (modifierString == "no" and (modifiers == nil or modifiers == 0 or not next(modifiers))) or (modifierString ~= "no" and (modifierString == nil or modifierString == 0 or modifierString == "")) then
      testPass = true -- true if no modifier is pressed or required
   elseif type(modifiers) == "table" and type(modifierString) == "string" then
      local strict = rv.profile.config.strictModifiers
      if not strict and modifiers[modifierString] == true then
         testPass = true
      else
         testPass = true
         local matchedCombinations = {} ---@type table<string,true>

         for mod in gmatch(modifierString, "%a%a") do
            if modifiers[mod] ~= true then
               testPass = false
               break
            end -- false if q requirement isn't met
            if strict then matchedCombinations[mod] = true end ---no strict mode, no need to save
         end

         if strict then -- making sure no additional modifiers are pressed, ignoring "lock" type modifiers
            for modKey in pairs(modifiers) do
               if sub(modKey, 1, 1) ~= "g" and sub(modKey, 2, 2) ~= "l" and matchedCombinations[modKey] ~= true then
                  testPass = false
                  break
               end
            end
         end

      end
   end
   stat.conditions.mkeyPass = testPass
   return testPass
end

---Wrapper for area test
---@param stat MacroStatContainer Statistics of the current macro
---@param area RectDefinition The rectangle that needs to contain the mouse (or not if negative)
---@param id string the macro id
---@return boolean #true if test was passed
local function _testArea(stat, area, id)
   stat.conditions.areaPass = (area == nil or rv.mouseMonitorUtils:areaCheckWrapper(area, id)) -- forwarding to monitor utils
   return stat.conditions.areaPass
end

---Check if a sequence of a certain name is running
---@param t string the name of the sequence
---@param negate true? negate the result
---@return boolean #true if test was passed
local function _testSequence(t, negate)
   local testResult = (negate == nil)
   local k = rv.profile.nameMap[t] ---the id corresponding to the name
   if rv.threading:taskStatus(k) == 1 then return testResult end -- if the sequence is running there'll be a task with its id
   return not testResult
end

---check if a flag is active
---@param flagName string the name of the flag
---@param negate true? negate the result
---@return boolean #true if test was passed
local function _testFlags(flagName, negate)
   local tres = (negate == nil)
   -- In case we ever do non- binary flags, currently useless
   local varSplit = rv.utils.splitter(flagName, "=")
   if #varSplit == 2 then
      if rv.scriptStates.flags[varSplit[1]] == varSplit[2] then return tres end
   elseif rv.scriptStates.flags[flagName] then
      return tres
   end
   return not tres
end

---test if a key matchcode fits a specific event
---@param subString string the event code of an event, can include the # wildcard
---@param eventInfo EventInfo record of a key event
---@param fam FamilyToken family that triggered the test
---@return boolean #true if the matchcode fits the event
local function _singleTest(subString, eventInfo, fam)
   if subString == "##" then return true end
   subString = rv.profile.unRename[subString] or subString
   if sub(subString, 1, 1) == "#" then -- the character # designates that we are including all possible families
      local famList = {} ---@type string[]
      for h = 1, #rv.stringPresets.families do famList[#famList + 1] = rv.str:token(rv.stringPresets.families[h]) .. sub(subString, 2) end
      for d = 1, #famList do if _singleTest(famList[d], eventInfo, fam) then return true end end -- short circuit after first positive
      return false
   elseif find(subString, "^%a") == nil then
      subString = fam .. subString
   end
   if sub(subString, -1) == "#" then return eventInfo.familyToken == sub(subString, 1, 1) end -- if the last character is a wildcard only the family counts
   subString = rv.profile.unRename[subString] or subString
   return (eventInfo.name == subString)
end

---simulates a circuit-like logic gate
---@param truthTable any[] An array of either boolean values or values that will be processed into boolean values
---@param mode LogicMode The evaluation mode to after compiling all truth values
---@param eval fun(...:any):boolean the function to process all values that aren't already boolean
---@return boolean #the final truth value
local function logicGate(truthTable, mode, eval)
   if type(truthTable) ~= "table" then truthTable = {truthTable} end
   mode = mode or "or" -- setting the default mode
   ---keeping track of succesful passes
   local passes = {} ---@type 1[]
   for i = 1, #truthTable do
      local obj = truthTable[i] -- iterating through all results
      if type(obj) ~= "boolean" then obj = eval(obj) end
      if mode == "and" and obj == false then return false end -- both 'and' and 'or' short circuit after a single result
      if mode == "or" and obj == true then
         return true
      elseif obj == true then
         passes[#passes + 1] = 1
      end
   end -- now we go through all the other logic configurations
   if #passes == 0 and (mode == "nor" or mode == "nand" or mode == "xnor") then return true end
   if #passes == #truthTable and (mode == "and" or mode == "xnor") then return true end
   if #passes > 0 and #passes ~= #truthTable and (mode == "nand" or mode == "xor") then return true end
   return false
end

---Test if a button is currently pressed
---@param key integer|string number or name of a key
---@param negate? true if true negate the result
---@return boolean #true if key is pressed
local function testCurrentlyPressed(key, negate)
   local testResult = (negate == nil)
   key = rv.profile.unRename[key] or key -- resolving key name
   if rv.keyStates.keysDown[key] == nil then testResult = not testResult end
   return testResult
end

---Check custom conditions as defined on keys
---@param t_cond (fun():boolean)[]|_ConditionOptions|fun():boolean any sort of condition
---@param key integer the number of the pressed key
---@param virtu? integer the virtual state of the key
---@param fam FamilyToken the device family of the key
---@param t_ident string the current macro id
local function _conditionEvaluation(t_cond, key, virtu, fam, t_ident)
   local stat = rv.profile.macroIndex[t_ident].state
   local macroCondition = t_cond
   ---comment
   ---@param testInput string|(fun():boolean)[]|_ConditionOptions|fun():boolean
   ---@return boolean
   local function _recursiveTest(testInput) -- evaluating the "test" conditions of a key.(recursive)
      local testDefinition = testInput or macroCondition
      if type(testInput) == "boolean" then return testInput end -- some tests are already evaluated at this point
      if type(testDefinition) == "function" then return testDefinition() end
      if type(testDefinition) == "table" then -- recursively testing arrays
         return logicGate(testDefinition, (testDefinition --[[@as _ConditionOptions]] ).logic or (testDefinition --[[@as _ConditionOptions]] ).l, _recursiveTest)
      elseif type(testDefinition) == "number" then
         if testDefinition > 0 then
            testDefinition = fam .. testDefinition
         else
            testDefinition = "-" .. fam .. abs(testDefinition)
         end
      end

      ---checks on or more previously pressed keys
      ---@param keyName string name of a key
      ---@param negate? true reverse the result
      ---@return boolean #true if previously pressed
      local function testPreviouslyPressed(keyName, negate)
         local testResult = (negate == nil)
         local virtualOffset = 0 ---Virtual keys are excluded from pressed keys
         if virtu and rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown].name == fam .. key then virtualOffset = 1 end
         local testRay = rv.utils.splitter(keyName, "-") ---multiple pressed keys can be queried separated with "-"
         if #testRay > #rv.keyStates.lastKeysDown - 1 then return not testResult end -- if we don't have enough keys saved, the test fails
         ---array of successful checks
         local truthRay = {} ---@type 1[]

         for g = 1, #testRay do
            local i = #testRay - g + 1 -- iterating all test cases
            local unit = testRay[i]
            local nopster = sub(unit, 1, 1) == "|" -- if prepended with "|", the test is negative
            if nopster then unit = sub(unit, 2) end -- removing the "|"
            if (nopster == false and _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtualOffset], fam)) or (nopster == true and (not _singleTest(unit, rv.keyStates.lastKeysDown[#rv.keyStates.lastKeysDown - g + virtualOffset], fam))) then
               truthRay[#truthRay + 1] = 1 -- adding a successful check to the array
            end
         end
         return (#truthRay == #testRay) == testResult
      end

      if type(testDefinition) == "string" then
         local prefix = sub(testDefinition, 1, 1) -- If the first character is a special prefix, we trigger the specific checks.
         if prefix == "-" then
            return testCurrentlyPressed(sub(testDefinition, 2), true)
         elseif prefix == "^" then
            return testPreviouslyPressed(sub(testDefinition, 2))
         elseif prefix == "|" then
            return testPreviouslyPressed(sub(testDefinition, 2), true)
         elseif prefix == ":" then
            return _testSequence(sub(testDefinition, 2))
         elseif prefix == "~" then
            return _testSequence(sub(testDefinition, 2), true)
         elseif prefix == "." then
            return _testFlags(sub(testDefinition, 2))
         elseif prefix == "*" then
            return _testFlags(sub(testDefinition, 2), true)
         else
            return testCurrentlyPressed(testDefinition)
         end -- Just executing the normal test
      end
      return false
   end

   if _recursiveTest(macroCondition) then
      stat.conditions.testPass = true
      return true
   end
   return false
end

---Wrapper for custom test conditions
---@param t_test? (fun():boolean)[]|_ConditionOptions|fun():boolean|string[]
---@param t_mouse integer number of the key
---@param t_virt? integer virtual state of the event
---@param t_fam FamilyToken family of the event
---@param t_ident string the macro id
local function _triggerTest(t_test, t_mouse, t_virt, t_fam, t_ident) return (t_test == nil) or _conditionEvaluation(t_test, t_mouse, t_virt, t_fam, t_ident) end

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
      -- starting the process to test if the right modifiers are down.
      local mouseDir = event.direction or state[fam].dir
      local meta = macro.state
      -- comparing data on the macro to the current mouse state
      meta.matchUp = mouseDir == "down" and macro.direction == "normal"
      meta.matchDown = mouseDir == "up" and macro.direction == "up"

      if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
      if mouseDir == "down" then
         meta.allPassed = true
      elseif mouseDir == "up" then
         meta.allPassed = nil
      end
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
      -- starting the process to test if the right modifiers are down.
      local buttonDirection = event.direction or state[fam].dir
      local meta = macro.state
      local lastShift = (config.globalGShift and rv.profile.globalState.shift) or state[fam].shift
      local lastMode = state[fam].modus
      local buttonCheck = false ---@type boolean|nil
      meta.matchUp = buttonDirection == "down" and macro.direction == "normal"
      meta.matchDown = buttonDirection == "up" and macro.direction == "up"

      if meta.matchUp or buttonDirection == "down" or virtualState then meta.conditions = {} end
      if not virtualState then -- executing all checks for the macro conditions
         if buttonDirection == "down" then
            buttonCheck = _testShift(meta, options.gshift or config.defaultShift, lastShift) and _testMode(meta, options.mode or config.defaultMode, lastMode, fam) and _testKey(meta, options.mkey, rv.scriptStates.mods) and _testArea(meta, options.area, macroID) and _triggerTest(options.condition, keyNum, virtualState, fam, macroID)
         elseif (buttonDirection == "up" and meta.allPassed) then
            buttonCheck = (((options.unlock == nil or not rv.tbl:find(options.unlock, "shift")) and meta.conditions.shiftPass) or _testShift(meta, options.gshift, lastShift)) and (((options.unlock == nil or not rv.tbl:find(options.unlock, "mode")) and meta.conditions.modePass) or _testMode(meta, options.mode, lastMode, fam)) and (((options.unlock == nil or not rv.tbl:find(options.unlock, "mkeys")) and meta.conditions.mkeyPass) or _testKey(meta, options.mkey, rv.scriptStates.mods)) and (((options.unlock == nil or not rv.tbl:find(options.unlock, "area")) and meta.conditions.areaPass) or _testArea(meta, options.area, macroID)) and (((options.unlock == nil or not rv.tbl:find(options.unlock, "condition")) and meta.conditions.testPass) or _triggerTest(options.condition, keyNum, virtualState, fam, macroID))
         end
      else
         buttonCheck = ((not options.gshift) or _testShift(meta, options.gshift or config.defaultShift, lastShift)) and ((not options.mode) or _testMode(meta, options.mode or config.defaultMode, lastMode, fam)) and ((not options.mkey) or _testKey(meta, options.mkey, rv.scriptStates.mods)) and ((not options.area) or _testArea(meta, options.area, macroID)) and ((not options.condition) or _triggerTest(options.condition, keyNum, virtualState, fam, macroID))
      end

      if buttonCheck then
         if buttonDirection == "down" then -- saving the result of the check in the macro metadata for future reference
            meta.allPassed = true
         elseif buttonDirection == "up" then -- resetting for the next press
            meta.allPassed = nil
         end
         return meta.matchUp or meta.matchDown or not singleTrigger
      else
         return false
      end
   end
end

return MacroValidatorModule
