local tl = ...---@type MainLibObject
local abs, sub, match, find, type, remove, tostring, pairs, gmatch,tonumber =
  math.abs,string.sub,string.match,string.find,type,table.remove,tostring,pairs,string.gmatch,tonumber
--=============================================================
---@class ButtonChecks
---@field shiftPass boolean
---@field modePass boolean
---@field mkeysPass boolean
---@field areaPass boolean
---@field testPass boolean

---@class MacroStatContainer
---@field macro GenericMacro
---@field cycleTimer number
---@field cyclesComplete number
---@field check ButtonChecks
---@field allPassed boolean
---@field multiClick number
---@field stagTimer number
---@field seqPosition number
---@field multiTimer number
---@field referenced boolean
local MacroValidatorModule = tl.baseClass:new()---@class MacroValidatorModule:BaseClass controls parsing and execution of user defined bindings

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
    local modeRay = tl.profile.deviceState[fam].modeConfig
    if modeRay[lMod] and modeRay[lMod][1] == moTest then
      stat.conditions.modePass = rVal
      return rVal
    end
    return not rVal
  elseif type(moTest) == "table" then
    rVal = false
    for i = 1, #moTest do local obj = moTest[i]
      if (type(obj) == "number" and obj < 0) or (type(obj) == "string" and sub(obj, 1, 1) == "-") then
        if _testMode(stat, modi, lMod, fam, obj) == false then return false end
      elseif _testMode(stat, modi, lMod, fam, obj) then rVal = true end
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
  if(mkeys == "no" and (lModif == nil or lModif == 0 or #lModif == 0)) or
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
---@param area AreaContainer
local function _testArea(stat, area,id)
  stat.conditions.areaPass = (area == nil or tl.mouseMonitorUtils:areaCheckWrapper(area,id))
  return stat.conditions.areaPass
end

local function _testAttributes(subject, subRay)
  if #subject == 1 then return true end
  for o = 1, #subject do
    local unit = tl.helperUtils.splitter(subject[o], "=")
    local key = unit[1]
    local val = unit[2]
    if tostring(subRay[key]) ~= val then return false end
  end
  return true
end

local function _testSequence(t, neg)
  local tres = (neg == nil)
  if tl.coroutines.taskList[t] ~= nil and not tl.coroutines.taskList[t].paused then return tres end
  return not tres
end

local function _testFlags(varString, neg)
  local tres = (neg == nil)
  local varSplit = tl.helperUtils.splitter(varString, "=")
  if #varSplit == 2 then
    if tl.scriptStates.flags[varSplit[1]] == varSplit[2] then return tres end
  elseif tl.scriptStates.flags[varString] then return tres end
  return not tres
end

local function _singleTest(subString, arr, fam)
  subString = tl.profile.unRename[subString] or subString
  if sub(subString, 1, 1) == "#" then
    local faRay = {}
    for h = 1, #tl.stringPresets.families do
      faRay[#faRay + 1] = tl.str.token(tl.stringPresets.families[h]) .. sub(subString, 2)
    end
    for d = 1, #faRay do
      if _singleTest(faRay[d], arr, fam) then return true end
    end
    return false
  elseif find(subString, "^%a") == nil then subString = fam .. subString end
  if sub(subString, -1) == "#" then return sub(arr.name, 1, 1) == sub(subString, 1, 1) end
  subString = tl.profile.unRename[subString] or subString
  return (arr.name == subString)
end

local function logicGate(truthTable,mode,eval)
  if type(truthTable) ~= "table" then truthTable = {truthTable} end
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

---Check custom conditions as defined on keys
---@param t_test TestStruct
---@param mouse number
---@param virtu number
---@param fam string
---@param t_dir string
---@param t_ident string
local function _testEvaluation(t_test, mouse, virtu, fam, t_dir, t_ident)
  ---@type MacroStatContainer
  local stat = tl.profile.macroIndex[t_ident].state
  local tes = t_test

  local function _recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
    local hasAttribute
    local recTest = ind or tes
    if type(ind) == "boolean" then return ind end

    if type(recTest) == "table" then --recursively testing arrays
     return logicGate(recTest,recTest.logic,_recursiveTest)
    elseif type(recTest) == "number" then
      if recTest > 0 then recTest = fam .. recTest
      else recTest = "-" .. fam .. abs(recTest) end
    end

    local function testCurrentlyPressed(t, neg)
      local attriT
      if hasAttribute then
        attriT = tl.helperUtils.splitter(t, "@")
        t = remove(attriT, 1)
      end
      local tres = (neg == nil)
      t = tl.profile.unRename[t] or t
      if sub(t, 1, 1) == "#" then
        local faRay = {}
        for h = 1, #tl.stringPresets.families do faRay[#faRay + 1] = tl.str.token(tl.stringPresets.families[h]) .. sub(t, 2) end
        faRay.mode = "or"
        if _recursiveTest(faRay) == false then tres = not tres end
      elseif find(t, "^%a") == nil then t = fam .. t end
      if sub(t, -1) == "#" then
        local sFam = sub(t, 1, 1)
        for k, v in pairs(tl.keyStates.keysDown) do
          if type(k) == "string" and k ~= fam .. mouse and sub(k, 1, 1) == sFam and
          ((not hasAttribute) or _testAttributes(attriT, v)) then return tres end
        end
        return not tres
      end
      t = tl.profile.unRename[t] or t
      if tl.keyStates.keysDown[t] == nil or (hasAttribute and _testAttributes(t, tl.keyStates.keysDown[t]) == false) then tres = not tres end
      return tres
    end

    local function testPreviouslyPressed(t, neg)
      local tres = (neg == nil)
      local virtoff = 0
      if virtu and tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown].name == fam .. mouse then virtoff = 1 end
      local testRay = tl.helperUtils.splitter(t, "-")
      if #testRay > #tl.keyStates.lastKeysDown - 1 then return not tres end
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
        if nopster then unit = sub(unit, 2) end
        if (nopster == false and _singleTest(unit, tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff], fam) and
          (not hasAttribute or _testAttributes(attriT, tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff]))) 
          or(nopster == true and (not _singleTest(unit,tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff],fam) 
          or (hasAttribute and _testAttributes( attriT, tl.keyStates.lastKeysDown[#tl.keyStates.lastKeysDown - g + virtoff] ) == false))) then 
            truthRay[#truthRay + 1] = 1 
          end
        end
      return (#truthRay == #testRay) == tres
    end

    if type(recTest) == "string" then
      hasAttribute = (#tl.helperUtils.splitter(recTest, "@") > 1)
      local desig = sub(recTest, 1, 1)
      if desig == "-" then return testCurrentlyPressed(sub(recTest, 2), 1)
      elseif desig == "^" then return testPreviouslyPressed(sub(recTest, 2))
      elseif desig == "|" then return testPreviouslyPressed(sub(recTest, 2), 1)
      elseif desig == ":" then return _testSequence(sub(recTest, 2))
      elseif desig == "~" then return _testSequence(sub(recTest, 2), 1)
      elseif desig == "." then return _testFlags(sub(recTest, 2))
      elseif desig == "*" then return _testFlags(sub(recTest, 2), 1)
      else return testCurrentlyPressed(recTest) end
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

---@param event Event
function MacroValidatorModule:skipConditions(event,options,macroType,macroID,singleTrigger)
  local fam,virtualState,keyNum = event.family,event.virtualType,event.keyNum
  local config = tl.profile.config
  local state = tl.profile.deviceState
  local macro = tl.profile.macroIndex[macroID]

  fam = fam or "m"
  if (tl.scriptStates.currentButton == keyNum or virtualState) and (virtualState or state[fam].conKey ~= keyNum) then 
    --starting the process to test if the right modifiers are down.
    local mouseDir = event.direction or state[fam].dir
    local meta = macro.state
    local lShift = state[fam].shift
    local lMod = state[fam].modus
    local buttonCheck = false
    meta.matchUp = mouseDir == "down" and macro.direction == "normal"
    meta.matchDown = mouseDir == "up" and macro.direction == "up"
    
    if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
    if mouseDir == "down" then meta.allPassed = true
    elseif mouseDir == "up" then meta.allPassed = nil end
    local blocking = options.blocking
    if tl.scriptStates.docMode and (not virtualState) and macroType ~= "documentation" then
      tl.validator:documentKey(macroID, fam, keyNum)
      return false
    end
    return meta.matchUp or meta.matchDown or not singleTrigger
  end
end

---@param event Event
function MacroValidatorModule:validateConditions(event,options,macroType,macroID,singleTrigger)
  local fam,virtualState,keyNum = event.family,event.virtualType,event.keyNum
  local config = tl.profile.config
  local state = tl.profile.deviceState
  local macro = tl.profile.macroIndex[macroID]

  fam = fam or "m"
  if (tl.scriptStates.currentButton == keyNum or virtualState) and (virtualState or state[fam].conKey ~= keyNum) then 
    --starting the process to test if the right modifiers are down.
    local mouseDir = event.direction or state[fam].dir
    local meta = macro.state
    local lShift = state[fam].shift
    local lMod = state[fam].modus
    local buttonCheck = false
    meta.matchUp = mouseDir == "down" and macro.direction == "normal"
    meta.matchDown = mouseDir == "up" and macro.direction == "up"
    
    if meta.matchUp or mouseDir == "down" or virtualState then meta.conditions = {} end
    if not virtualState then
      if mouseDir == "down" then
        buttonCheck =
          _testShift(meta, options.gshift or config.defaultShift, lShift) and
          _testMode(meta, options.mode or config.defaultMode, lMod, fam) and
          _testKey(meta, options.mkey, tl.scriptStates.mods) and
          _testArea(meta, options.area,macroID) and
          _triggerTest(options.condition, keyNum, virtualState, fam, mouseDir, macroID)
      elseif (mouseDir == "up" and meta.allPassed) then
        buttonCheck =
          (((options.unlock == nil or not tl.tbl:find(options.unlock, "shift")) and meta.conditions.shiftPass) or
          _testShift(meta, options.gshift, lShift)) and
          (((options.unlock == nil or not tl.tbl:find(options.unlock, "mode")) and meta.conditions.modePass) or
            _testMode(meta, options.mode, lMod, fam)) and
          (((options.unlock == nil or not tl.tbl:find(options.unlock, "mkeys")) and meta.conditions.mkeyPass) or
            _testKey(meta, options.mkey, tl.scriptStates.mods)) and
          (((options.unlock == nil or not tl.tbl:find(options.unlock, "area")) and meta.conditions.areaPass) or
            _testArea(meta, options.area,macroID)) and
          (((options.unlock == nil or not tl.tbl:find(options.unlock, "condition")) and meta.conditions.testPass) or
            _triggerTest(options.condition, keyNum, virtualState, fam, mouseDir, macroID))
      end
    else
      buttonCheck =
        ((not options.gshift) or _testShift(meta, options.gshift or config.defaultShift, lShift)) and
        ((not options.mode) or _testMode(meta, options.mode or config.defaultMode, lMod, fam)) and
        ((not options.mkeys) or _testKey(meta, options.mkeys, tl.scriptStates.mods)) and
        ((not options.area) or _testArea(meta, options.area,macroID)) and
        ((not options.condition) or _triggerTest(options.condition, keyNum, virtualState, fam, mouseDir, macroID))
    end

    if buttonCheck then
      if mouseDir == "down" then meta.allPassed = true
      elseif mouseDir == "up" then meta.allPassed = nil end
      local blocking = options.blocking
      if tl.scriptStates.docMode and (not virtualState) and macroType ~= "documentation" then
         tl.validator:documentKey(macroID, fam, keyNum)
        return false
      end
      return meta.matchUp or meta.matchDown or not singleTrigger
    else return false 
    end
  end
end

---@class doc
---key documentation function for documentation mode
---@param macro string
---@param fam string
---@param num number
function MacroValidatorModule:documentKey(macroID, fam, num)
  local macro = tl.profile.macroIndex[macroID]
  local macroString = macro.documentation or tl.profile.documentation[macroID] 
  or (fam and num and  tl.profile.assign.documentation and (tl.profile.assign.documentation[tl.profile.config.rename[fam .. num]] or tl.profile.documentation[fam .. num]))
  if macroID == self.lastDocumented then
    self.lastDocumented = ""
    return
  end
  self.lastDocumented = macro.pID
end

return MacroValidatorModule