---@type MainLibObject
local tl = ...
local abs, sub, match, find, type, remove, tostring, pairs, gmatch, insert =
math.abs, string.sub, string.match, string.find,type, table.remove,tostring,pairs,string.gmatch,table.insert
-->>>> The main framework functions for the script, controls parsing and execution of user defined bindings =============================================================

---Property override for linked macros
---@param u1 table
---@param u2 table
---@param button string
local function _mergeUpdate(u1,u2,button)
  if u1 == nil and u2 ==nil then return false end
  u1 = u1 or {}
  u1 = tl.deepcopy(u1,nil,button)
  if tl.allType(u1,"table") == false then u1={u1} end
  if tl.allType(u2,"table") == false then u2={u2} end
  for i=1, #u2 do
    insert(u1,1,u2[i])
  end
  return u1
end

local function _tabulate(tbl,startTable,noOff,fallbackTable)
  local minus = noOff or 1
  local position = startTable or fallbackTable or {}
  local finalValue = tbl[#tbl]
  for p=1, #tbl-minus do
    if type(tbl[p]) == "number" and tbl[p] < 1 then tbl[p] = #position+tbl[p] end
    position = position[tbl[p]]
  end
  return position, finalValue
end

---Resolves and updates the references in "l" type macros.
---@param link LinkMacro
---@param button string
---@param parentUpdate table
---@return GenericMacro
local function _resolveLink(link,button,parentUpdate)
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
    if tl.config.cacheLinks and tl.dynamicTables[combinedID] ~= nil then
      lock = tl.dynamicTables[combinedID]
    elseif tl.isContainer(lock) then
      lack = tl.deepcopy(lock)
      for i=1,#lack do
        lack[i] = _resolveLink(lack[i], button, metaUpdate)
      end
      lack.pID = combinedID
      ---@type MacroStatContainer
      tl.macroStats[combinedID] = tl.macroStats[combinedID] or {macro=lack,check={}}
      tl.dynamicTables[combinedID] = lack
      return lack
    else
      local currentUpdate = metaUpdate or lock.update;
      metaUpdate = _mergeUpdate(currentUpdate,unlock.update,button)
      lock = tl.intersect(unlock,lock,rideNum,lock.keepExisting)
      lack = tl.deepcopy(lock,nil,button)
      if metaUpdate ~= false and lack.type ~="l" then
        if type(metaUpdate) == "table" then

          local function _replaceCycle(reptable)
            local h = reptable[1]
            if type(h) ~= "table" then h={h} end
            local targTab,valName = _tabulate(h,nil,nil,lack)
            local endInsert = reptable[2]
            if type(reptable[4]) == "string" then
              if type(reptable[2]) ~="table" then reptable[2] = {reptable[2]} end
              local importer = _resolveLink(tl.macroStats[reptable[4] or "null"].macro,button)
              endInsert,_ = _tabulate(reptable[2],importer,0,lack)
            end

            if reptable[3] == nil or reptable[3] == "replace"  then
              targTab[valName] = endInsert
            elseif reptable[3] == "insert" then
              insert(targTab,valName,endInsert)
            elseif reptable[3] == "remove" then
              local g = reptable[2]
              if type(g) == "string" then
                targTab[valName][g] = nil
              elseif g > 1 then
                local posi = valName-1
                for _=1, abs(g) do
                  remove(targTab,posi)
                  posi = posi -1
                end
              else
                local posi = valName
                for _=1, g do
                remove(targTab,posi)
              end
            end
            end
          end

          if tl.allType(metaUpdate,"table")== false then
            _replaceCycle(metaUpdate)
          else
            for i=1, #metaUpdate do
              _replaceCycle(metaUpdate[i])
            end
          end
          lock = lack
        end
      end
      lock.pID = combinedID
      ---@type MacroStatContainer
      tl.macroStats[combinedID] = tl.macroStats[combinedID] or {macro=lock,check={}}
      tl.dynamicTables[combinedID] = lock
    end
  end
  return lock
end

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

local function _attribuTest(subject,subRay)
  if #subject == 1 then return true end
  for o=1,#subject do local unit = tl.splitter(subject[o],"=")
    local key = unit[1]
    local val = unit[2]
    if tostring(subRay[key]) ~= val then return false end
  end
  return true
end

local function _seqTest(t,neg)
  local tres = (neg == nil)
  if tl.taskList[t] ~= nil and not tl.taskList[t].paused then return tres end
  return not tres
end

local function _varTest(varString,neg)
  local tres = (neg == nil)
  local varSplit = tl.splitter(varString,"=")
  if #varSplit == 2 then
    if tl.flags[varSplit[1]] == varSplit[2] then return tres end
  elseif tl.flags[varString] then
    return tres
  end
  return not tres
end

local function _singleCheck(subString,arr,fam)
  subString = tl.unname[subString] or subString
  if sub(subString,1,1) =="#" then
    local faRay = {}
    for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..sub(subString,2) end
    for d=1,#faRay do
      if _singleCheck(faRay[d],arr,fam) then return true end
    end
    return false
  elseif  find(subString,"^%a") == nil then
    subString = fam..subString
  end
  if sub(subString,-1) == "#" then
    return sub(arr.name,1,1) == sub(subString,1,1)
  end
  subString = tl.unname[subString] or subString
  return (arr.name == subString)
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

  local function _recursiveTest(ind,mouse,fam,virtu) --evaluating the "test" conditions of a key.(recursive)
    local hasAttribute
    local recTest = ind or tes
    if type(ind) == "boolean" then
      return ind
    end

    if type(recTest) == "table" then --recursively testing arrays
      local m = recTest.logic or "or"
      local sucs = {}
      for i=1,#recTest do local obj = recTest[i]
        local subtest = _recursiveTest(obj)
        if m == "and" and subtest == false then return false end
        if m == "or" and subtest == true then return true
        elseif subtest == true then sucs[#sucs+1] = 1 end
      end

      if #sucs == 0 and (m=="nor" or m=="nand" or m=="xnor") then return true end
      if #sucs == #recTest and (m=="and" or m=="xnor") then return true end
      if #sucs > 0 and #sucs ~= #recTest and (m=="nand" or m == "xor") then return true end

      return false
    elseif type(recTest) == "number" then
        if recTest > 0 then
          recTest = fam..recTest
        else
          recTest = "-"..fam..abs(recTest)
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
        for k,v in pairs(tl.keysDown) do
          if type(k) == "string" and k~= fam..mouse and sub(k,1,1) == sFam and ((not hasAttribute) or _attribuTest(attriT,v)) then return tres end
        end
        return not tres
      end
      t = tl.unname[t] or t
      if tl.keysDown[t] == nil or (hasAttribute and _attribuTest(t,tl.keysDown[t]) == false) then tres = not tres end
      return tres
    end

    local function pasTest(t,neg)
      local tres = (neg == nil)
      local virtoff = 0
      if virtu and tl.lastKeysDown[#tl.lastKeysDown].name == fam..mouse then virtoff = 1 end
      local testRay = tl.splitter(t,"-")
      if #testRay > #tl.lastKeysDown-1 then return not tres end
      local truthRay = {}

      for g = 1, #testRay do local i = #testRay-g+1 local unit = testRay[i]
        local attriT
        if hasAttribute then
        attriT = tl.splitter(unit,"@")
        unit = remove(attriT,1)
        end
        local nopster = sub(unit, 1,1) == "|"
        if nopster then unit = sub(unit,2) end
        if
          (nopster == false and _singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff],fam) and
          (not hasAttribute or _attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff])))
        or
           (nopster == true and (not _singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff],fam) or
           (hasAttribute and _attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) == false)))
        then
          truthRay[#truthRay+1]=1
        end
      end
      return (#truthRay == #testRay) == tres
    end

    if type(recTest) == "string" then
      hasAttribute = (#tl.splitter(recTest,"@") > 1)
      local desig= sub(recTest, 1,1)
      if desig == "-" then
        return presenTest(sub(recTest,2),1)
      elseif desig == "^" then
        return pasTest(sub(recTest,2))
      elseif desig== "|" then
        return pasTest(sub(recTest,2),1)
      elseif desig == ":" then
        return _seqTest(sub(recTest,2))
      elseif desig == "~" then
        return _seqTest(sub(recTest,2),1)
      elseif desig == "." then
        return _varTest(sub(recTest,2))
      elseif desig == "*" then
        return _varTest(sub(recTest,2),1)
      else
        return presenTest(recTest)
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

if type(macro) ~= "table" then
  macro = {macro}
elseif tl.isContainer(macro) then
  _deContain(keyNum,fam,macro,virtualState,simDirection,originator) return
end
  local played = 0

  if (tl.currentButton == keyNum or virtualState) and (virtualState or tl.state[fam].conKey ~= keyNum) then --starting the process to test if the right modifiers are down.
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
      shifted =macro.gshift or pKey.gshift,
      pDir = macro.direction or pKey.direction or "normal"}

    local mouseDir = (virtualState and ev.simDirection) or tl.state[fam].dir
    tl.macroStats.null={check={}}
    local stat = tl.macroStats[ev.ID or "null"]
    local lShift = tl.state[fam].shift
    local lMod = tl.state[fam].modus
    local buttonCheck = false

    stat.matchUp = mouseDir=="down" and ev.pDir == "normal"
    stat.matchDown = mouseDir=="up" and ev.pDir == "up"

    if stat.matchUp or mouseDir=="down" or virtualState  then stat.check={} end

    if not virtualState then
      if mouseDir == "down" then
        buttonCheck = _getShift(stat,ev.shifted or tl.config.defaultShift,lShift)
        and _getMode(stat,ev.mode or tl.config.defaultMode,lMod,fam)
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
      buttonCheck = (not ev.shifted or _getShift(stat,ev.shifted or tl.config.defaultShift,lShift))
      and ((not ev.mode )or _getMode(stat,ev.mode or tl.config.defaultMode,lMod,fam))
      and ((not ev.mkeys) or _getKey(stat,ev.mkeys,tl.mods))
      and ((not ev.area) or _getArea(stat,ev.area))
      and ((not ev.testCondition) or _getTest(ev.testCondition,keyNum,virtualState,fam,mouseDir,ev.ID))
    end
    if buttonCheck then
      if mouseDir == "down" then stat.allPassed = true elseif mouseDir == "up" then stat.allPassed = nil end
      if ev.type == "l" then return tl.keyGen(keyNum, fam, _resolveLink(macro), virtualState, ev.simDirection, originator) end
      if tl.config.automaticTypeDetection and not ev.type then _identifyType(macro) end
      local simFam = macro.family or pKey.family
      local consume = macro.consume or pKey.consume
      if tl.config.enableLinting and tl.lintErrors[fam..keyNum] then
        if tl.lintErrors._lastDisplayedMessage ~= tl.lintErrors[fam..keyNum] then
          tl.put(tl.lintErrors[fam..keyNum])
          tl.lintErrors._lastDisplayedMessage = tl.lintErrors[fam..keyNum]
        end
        if tl.config.abortOnLintError then return end
      end
      if tl.docMode and not virtualState and macro.type ~= "doc" then tl.document(macro,fam,keyNum) end
      ev.type = ev.type or "n"
      local tabs = tl.defaultFuncs
      if virtualState and virtualState ~= 2 and ev.simDirection == nil then
        mouseDir = nil
        tabs = tl.funcRayM
      elseif stat.matchUp then
        tabs = tl.funcRayU
      elseif stat.matchDown then
        tabs = tl.funcRayD
      end
      if tabs[ev.type] then
        tabs[ev.type](macro,mouseDir,keyNum,virtualState,fam,simFam,originator,ev.pDir,stat.matchUp or stat.matchDown)
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