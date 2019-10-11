local abs, sub, match, find, type, remove, tostring, pairs, gmatch =
math.abs, string.sub, string.match, string.find,type, table.remove,tostring,pairs,string.gmatch
---@type MainLibObject
local tl = ...
-->>>> The main framework functions for the script, controls parsing and execution of user defined bindings =============================================================

---Automatically identify a macro type by the macro's properties
---@param macro GenericMacro
local function _identifyType(macro)
  local foundType
  for k,_ in pairs(macro) do
    if type(k) == "string" and tl.propertyDefinitions[k] and tl.propertyDefinitions[k].propertyOf then local prop = tl.propertyDefinitions[k].propertyOf
      if type(prop) == "string" then
        if foundType and foundType ~= prop then foundType = nil break else foundType = prop end
      end
    end
  end
  if foundType == "l" then error("trying to coerce a link type macro. This is a very bad idea.") end
  macro.type = foundType
end

---Parse collection of macros into separate macro calls
---@param keyN number
---@param fam string
---@param lock table<integer,GenericMacro>|GenericMacro
---@param virt number
---@param virtrect string
---@param originator string
local function _deContain(keyN,fam,lock,virt,virtrect,originator)
  if tl.isContainer(lock)then
    for num=1,#lock do local coms = lock[num]
      _deContain(keyN,fam,coms,virt,virtrect,originator)
    end
  else
    tl.keyGen(keyN,fam,lock,virt,virtrect,originator)
  end
end

---If specified, do the direction instructions on the key line up with the current input direction?
---@param selec number
---@param dir1 string
---@param dir2 string
---@return boolean
local function _matchButtonDirection(selec,dir1,dir2)
  local reray = {{"normal","down"},{"up","up"}}
  return (dir1 == reray[selec][2] and dir2 == reray[selec][1])
end

local function _getShift(stat,shifted,lShift)
  stat.check.shiftPass =  type(shifted) == "number" and (shifted == 2 or (shifted == lShift))
  return stat.check.shiftPass 
end

local function _getMode(stat,modi,lMod,fam,manual)
  local moTest = manual or modi
  local rVal = true
  if type(moTest) == "number" then
    if moTest < 0 then
      rVal = false
      moTest = abs(moTest)
    end
    if moTest == 0 or moTest == tonumber(lMod) then
      stat.check.modePass = rVal 
      return rVal
    end
    return not rVal
  elseif type(moTest) == "string" then
    if sub(moTest,1,1) == "-" then
      rVal = false
      moTest = sub(moTest,2)
    end
    local modeRay = tl.state[fam].modeConfig
    if modeRay[lMod] and modeRay[lMod][1] == moTest then
      stat.check.modePass = rVal
      return rVal
    end
    return not rVal
  elseif type(moTest) == "table" then
    rVal = false
    for i=1,#moTest do local obj = moTest[i]
      if (type(obj) == "number" and obj < 0) or (type(obj) == "string" and sub(obj,1,1) == "-") then
        if _getMode(stat,modi,lMod,fam,obj) == false then return false end
      elseif _getMode(stat,modi,lMod,fam,obj) then
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
local function _getKey(stat,mkeys,lModif)
  local okayK = false
  if (mkeys == "no" and (lModif == nil or lModif== 0 or #lModif ==0)) or (mkeys ~="no" and (mkeys==nil or mkeys==0 or mkeys=="" or lModif == mkeys)) then
    okayK = true
  elseif type(lModif) == "string" and type(mkeys) == "string" then
    local typeComb = false
    local keyComb = false
    local comTab = {}
    local recTab = {}

    for i in gmatch(mkeys, "%a%a") do comTab[#comTab+1] = i end
    for i in gmatch(lModif, "%a%a") do  recTab[#recTab+1] = i end

    for i=1,#comTab do local obj = comTab[i]
      typeComb = false
      for d=1,#recTab do local abj = recTab[d]
        if match(obj,"%a$") == match(abj,"%a$") then
          typeComb = true
        end
        if typeComb == true then
          break
        end
      end
    end

    for i=1,#comTab do local obj = comTab[i]
      keyComb = false
      for d=1,#recTab do local abj = recTab[d]
        if abj == obj or (match(obj,"%a") == "g" and match(obj,"%a$") == match(abj,"%a$")) then
          keyComb = true
        end
        if keyComb == false then
          break
        end
      end
    end
    if keyComb  and typeComb then
      okayK = true
    end
  end
  stat.check.keyPass = okayK
  return okayK
end


---Wrapper for area test
---@param stat MacroStatContainer
---@param area AreaContainer
local function _getArea(stat,area)
  stat.check.areaPass = (area == nil or tl.areaCheckWrapper(area))
  return stat.check.areaPass
end

---Check custom conditions as defined on keys
---@param t_test TestStruct
---@param t_mouse number
---@param t_virt number
---@param t_fam string
---@param t_dir string
---@param t_ident string
local function _testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  local tes = t_test
  local mouse = t_mouse
  local virtu = t_virt
  local mdir = t_dir
  local ident = t_ident
  ---@type MacroStatContainer
  local stat = tl.macroStats[t_ident or "null"]
  local fam = t_fam
  local hasAttribute

  local function _recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
    local tes = ind or tes
    if type(ind) == "boolean" then
      return ind
    end
    local tas = tes

    local function attribuTest(subject,subRay)
      if #subject == 1 then return true end
      for o=1,#subject do local unit = tl.splitter(subject[o],"=")
        local key = unit[1]
        local val = unit[2]
        if tostring(subRay[key]) ~= val then return false end
      end
      return true
    end

    if type(tes) == "table" then --recursively testing arrays
      local m = tes.logic or "or"
      local sucs = {}
      for i=1,#tes do local obj = tes[i]
        local subtest = _recursiveTest(obj)
        if m == "and" and subtest == false then return false end
        if m == "or" and subtest == true then return true
        elseif subtest == true then sucs[#sucs+1] = 1 end
      end

      if #sucs == 0 and (m=="nor" or m=="nand" or m=="xnor") then return true end
      if #sucs == #tes and (m=="and" or m=="xnor") then return true end
      if #sucs > 0 and #sucs ~= #tes and (m=="nand" or m == "xor") then return true end

      return false
    elseif type(tes) == "number" then
        if tes > 0 then
          tes = fam..tes
        else
          tes = "-"..fam..abs(tes)
        end
    end

    local function presenTest(t,neg)
      local attriT
      if hasAttribute then
      attriT = tl.splitter(t,"@")
      t = remove(attriT,1)
      end
      local tres = (neg == nil)
      t = tl.unname[t] or t
      if sub(t,1,1) =="#" then
        local faRay = {}
        for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..sub(t,2) end
        faRay.mode="or"
        if _recursiveTest(faRay) == false then tres = not tres end
      elseif find(t,"^%a") == nil then
        t= fam..t
      end
      if sub( t,-1) == "#" then
        local sFam = sub( t,1,1)
        for k,v in pairs(tl.downs) do
          if type(k) == "string" and k~= fam..mouse and sub(k,1,1) == sFam and ((not hasAttribute) or attribuTest(attriT,v)) then return tres end
        end
        return not tres
      end
      t = tl.unname[t] or t
      if tl.downs[t] == nil or (hasAttribute and attribuTest(t,tl.downs[t]) == false) then tres = not tres end
      return tres
    end

    local function pasTest(t,neg)
      local tres = (neg == nil)
      local virtoff = 0
      if virtu and tl.lastKeysDown[#tl.lastKeysDown].name == fam..mouse then virtoff = 1 end
      local testRay = tl.splitter(t,"-")
      if #testRay > #tl.lastKeysDown-1 then return not tres end
      local truthRay = {}
      local function singleCheck(sub,arr)
        sub = tl.unname[sub] or sub
        if sub(sub,1,1) =="#" then
          local faRay = {}
          for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..sub(sub,2) end
          for d=1,#faRay do
            if singleCheck(faRay[d],arr) then return true end
          end
          return false
        elseif  find(sub,"^%a") == nil then
          sub = fam..sub
        end
        if sub( sub,-1) == "#" then
          return sub(arr.name,1,1) == sub(sub,1,1)
        end
        sub = tl.unname[sub] or sub
        return (arr.name == sub)
      end

      for g = 1, #testRay do local i = #testRay-g+1 local unit = testRay[i]
        local attriT
        if hasAttribute then
        attriT = tl.splitter(unit,"@")
        unit = remove(attriT,1)
        end
        local nopster = sub(unit, 1,1) == "|"
        if nopster then unit = sub(unit,2) end
        if
          (nopster == false and singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) and 
          (not hasAttribute or attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff])))
        or
           (nopster == true and (not singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) or 
           (hasAttribute and attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) == false)))
        then
          truthRay[#truthRay+1]=1
        end
      end
      return (#truthRay == #testRay) == tres
    end

    local function seqTest(t,neg)
      local tres = (neg == nil)
      if tl.TaskList[t] ~= nil and not tl.TaskList[t].paused then return tres end
      return not tres
    end

    local function varTest(varString,neg)
      local tres = (neg == nil)
      local varSplit = tl.splitter(varString,"=")
      if #varSplit == 2 then
        if tl.stateVars[varSplit[1]] == varSplit[2] then return tres end
      elseif tl.stateVars[varString] then
        return tres
      end
      return not tres
    end

    if type(tes) == "string" then
      hasAttribute = (#tl.splitter(tes,"@") > 1)
      local desig= sub(tes, 1,1)
      if desig == "-" then
        return presenTest(sub(tes,2),1)
      elseif desig == "^" then
        return pasTest(sub(tes,2))
      elseif desig== "|" then
        return pasTest(sub(tes,2),1)
      elseif desig == ":" then
        return seqTest(sub(tes,2))
      elseif desig == "~" then
        return seqTest(sub(tes,2),1)
      elseif desig == "." then
        return varTest(sub(tes,2))
      elseif desig == "*" then
        return varTest(sub(tes,2),1)
      else
        return presenTest(tes)
      end
    end
  end
  if _recursiveTest(tes) then stat.check.testPass = true return true end
  return false
end

---Wrapper for custom test conditions
---@param t_test TestStruct
---@param t_mouse number
---@param t_virt number
---@param t_fam string
---@param t_dir string
---@param t_ident string
local function _getTest(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  return (t_test == nil) or _testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
end

---quick and dirty keyGen call
---@param bar GenericMacro
---@param fam string
function tl.quickGen(bar,fam)
  if tl.isContainer(bar) == false then
    tl.keyGen(0,fam,bar,5)
  else
    for g=1, #bar do local com = bar[g]
      tl.keyGen(0,fam,com,5)
    end
  end
end

---Resolves and updates the references in "l" type macros.
---@param link LinkMacro
---@param button string
---@param parentUpdate table
---@return GenericMacro
function tl.resolveLink(link,button,parentUpdate)
  local lock = link
  local combinedID = ''
  local metaUpdate = parentUpdate
  while (lock.type == "l") and tl.macroStats[lock[1]] ~=nil do -- If the binding is a link we override the original binding's properties with any new ones
    local lockTarget = lock[1]
    local rideNum = 3
    local lack
    if lock.keepExisting == 1 then rideNum = 4 end
    local unlock = tl.macroStats[lockTarget].macro
    combinedID = combinedID..lock.pID..unlock.pID
    if tl.cacheLinks and tl.dynamicTables[combinedID] ~= nil then
      lock = tl.dynamicTables[combinedID]
    elseif tl.isContainer(lock) then
      lack = tl.deepcopy(lock)
      for i=1,#lack do
        lack[i] = tl.resolveLink(lack[i], button, metaUpdate)
      end
      lack.pID = combinedID
      ---@type MacroStatContainer
      tl.macroStats[combinedID] = tl.macroStats[combinedID] or {macro=lack,check={}}
      tl.dynamicTables[combinedID] = lack
      return lack
    else
      local currentUpdate = metaUpdate or lock.update;
      metaUpdate = tl.mergeUpdate(currentUpdate,unlock.update,button)
      lock = tl.intersect(unlock,lock,rideNum,lock.keepExisting)
      lack = tl.deepcopy(lock,nil,button)
      if metaUpdate ~= false and lack.type ~="l" then lock = tl.targetUpdate(metaUpdate,lack,button) end
      lock.pID = combinedID
      ---@type MacroStatContainer
      tl.macroStats[combinedID] = tl.macroStats[combinedID] or {macro=lock,check={}}
      tl.dynamicTables[combinedID] = lock
    end
  end
  return lock
end

---the main program for parsing key commands
---@param keyNum number
---@param fam string
---@param macro table<integer,GenericMacro>|GenericMacro
---@param virtualState number
---@param simDirection string
---@param originator string
function tl.keyGen(keyNum,fam,macro,virtualState,simDirection,originator)
 local pKey = tl.assign.key[(fam or "")..keyNum]
 if not macro then macro = pKey end
 if virtualState then pKey = macro end
 if macro == nil then return end
 local playState = "played"
 local playStorage = {}
 if fam and not virtualState then
   playStorage = tl.lastKeysDown[#tl.lastKeysDown]
 end
 fam = fam or "m"
 playStorage[playState] = (playStorage[playState] or 0)

if type(macro) == "string" then
  macro = {macro}
elseif type(macro) == "table" and tl.isContainer(macro) then
  _deContain(keyNum,fam,macro,virtualState,simDirection,originator) return
end
  local played = 0

  if (tl.but == keyNum or virtualState) and (virtualState or tl.state[fam].conKey ~= keyNum) then --starting the process to test if the right modifiers are down.
    local ev = {
      type = macro.type,
      unlock = macro.unlock or pKey.unlock,
      ID = macro.pID or pKey.pID,
      mkeys = macro.mkey or pKey.mkey,
      area = macro.area or pKey.area,
      simDirection = macro.simDir or pKey.simDir or simDirection,
      testCondition = macro.test or pKey.test,
      mode = macro.mode or pKey.mode,
      shifted =macro.gshift or pKey.gshift,
      pDir = macro.direction or pKey.direction or "normal"}
    
    local mouseDir = tl.state[fam].dir
    if virtualState and ev.simDirection then mouseDir = ev.simDirection end 
    tl.macroStats.null={check={}}
    local stat = tl.macroStats[ev.ID or "null"]
    local lShift = tl.state[fam].shift
    local lMod = tl.state[fam].modus
    local buttonCheck = false

    if _matchButtonDirection(1,mouseDir,ev.pDir) or mouseDir=="down" or virtualState  then stat.check={} end
    
    if not virtualState then 
      if mouseDir == "down" then
        buttonCheck = _getShift(stat,ev.shifted or tl.defaultShift,lShift) 
        and _getMode(stat,ev.mode or tl.defaultMode,lMod,fam) 
        and _getKey(stat,ev.mkeys,tl.mods) 
        and _getArea(stat,ev.area) 
        and _getTest(ev.testCondition,keyNum,virtualState,fam,mouseDir,ev.ID)
      elseif (mouseDir == "up" and stat.allPassed) then
        buttonCheck = (((ev.unlock == nil or not tl.find(ev.unlock,"shift"))and stat.check.shiftPass) or _getShift(stat,ev.shifted,lShift)) 
        and (((ev.unlock == nil or not tl.find(ev.unlock,"mode")) and stat.check.modePass) or _getMode(stat,ev.mode,lMod,fam))
        and (((ev.unlock == nil or not tl.find(ev.unlock,"mkeys"))and stat.check.keyPass) or _getKey(stat,ev.mkeys,tl.mods))
        and (((ev.unlock == nil or not tl.find(ev.unlock,"area")) and stat.check.areaPass) or _getArea(stat,ev.area))
        and (((ev.unlock == nil or not tl.find(ev.unlock,"test")) and stat.check.testPass) or _getTest(ev.testCondition,keyNum,virtualState,fam,mouseDir,ev.ID))
      end
    else
      buttonCheck = (not ev.shifted or _getShift(stat,ev.shifted or tl.defaultShift,lShift))
      and ((not ev.mode )or _getMode(stat,ev.mode or tl.defaultMode,lMod,fam))
      and ((not ev.mkeys) or _getKey(stat,ev.mkeys,tl.mods))
      and ((not ev.area) or _getArea(stat,ev.area))
      and ((not ev.testCondition) or _getTest(ev.testCondition,keyNum,virtualState,fam,mouseDir,ev.ID))
    end
    if buttonCheck then
      if mouseDir == "down" then stat.allPassed = true elseif mouseDir == "up" then stat.allPassed = nil end
      if ev.type == "l" then return tl.keyGen(keyNum, fam, tl.resolveLink(macro), virtualState, ev.simDirection, originator) end
      if tl.automaticTypeDetection and not ev.type then _identifyType(macro) end
      local simFam = macro.family or pKey.family
      local consume = macro.consume or pKey.consume
      if tl.enableLinting and tl.lintErrors[fam..keyNum] then
        if tl.lintErrors._lastDisplayedMessage ~= tl.lintErrors[fam..keyNum] then
          tl.put(tl.lintErrors[fam..keyNum])
          tl.lintErrors._lastDisplayedMessage = tl.lintErrors[fam..keyNum]
        end
        if tl.abortOnLintError then return end
      end
      if tl.docMode and not virtualState and macro.type ~= "doc" then tl.document(macro,fam,keyNum) end
      ev.type = ev.type or "n"
      local tabs = tl.defaultFuncs
      if virtualState and virtualState ~= 2 and ev.simDirection == nil then
        mouseDir = nil
        tabs = tl.funcRayM
      elseif _matchButtonDirection(1,mouseDir,ev.pDir) then
        tabs = tl.funcRayU
      elseif _matchButtonDirection(2,mouseDir,ev.pDir) then
        tabs = tl.funcRayD
      end
      if tabs[ev.type] then
        tabs[ev.type](macro,mouseDir,keyNum,virtualState,fam,simFam,originator,ev.pDir)
        played = 1
      end
      if not virtualState and (consume == 1  or consume==3) then
        tl.state[fam].conKey = keyNum
      else
        tl.state[fam].conKey = 0
      end
    end
  end
  playStorage[playState] = played
end