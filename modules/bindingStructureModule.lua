local tl = ...
local abs = math.abs
--->>> The main framework functions for the script, controls parsing and execution of user defined bindings =============================================================

function tl.prepKeys() --Prepare the key assignments array
  tl.assign.null={}
  tl.assign.start={}
  tl.assign.exit={}
  tl.assign.global={}
  tl.assign.globalOverride={}
  tl.assign.key={}
  local function resign(tagta,cdepth)
    local depth = cdepth or 0
    if tl.sKey ~= 0 then
      for p=0, 2 do
        tagta["s"..p]={}
        if depth < tl.stackDepth then resign(tagta["s"..p],depth+1) end
      end
    end

    for i = 0, tl.maxMode do
      tagta["mode"..i]={}
      if depth < tl.stackDepth then resign(tagta["mode"..i],depth+1) end
    end
  end
  resign(tl.assign)
end

function tl.switchCustom()
  local moreModes = 0
  local moreKeys = 0
  for k,v in  pairs(tl.rename) do
    tl.unname[v]=k
  end
  for g=1, #tl.families do local fam = tl.families[g]
    local shorty = tl.token(fam)
    tl.state[shorty]={
      conKey=0,
      shift=0,
      modus=1,
      mBeforeG=1,
      dir ="down",
      lastModN = 0,
      lastMod = 0,
      buttonCount = tl[fam.."ButtonCount"],
      sKey = tl[fam.."ShiftKey"],
      modeCount = tl[fam.."ModeCount"],
      modeConfig = tl[fam.."ModeConfig"],
      bindHardwareModes = tl[fam.."BindHardwareModes"],
      stable = {},
      unstable = {}
    }
    if tl.defaultModeTarget == "join" then
      tl.state[shorty].modeConfig=tl.genericModes
    end
    tl[fam.."ButtonCount"] = nil
    tl[fam.."ModeCount"] = nil
    tl[fam.."ShiftKey"] = nil
    tl[fam.."ModeConfig"] = nil
    tl[fam.."BindHardwareModes"] = nil
    if tl.state[shorty].modeCount > moreModes then moreModes = tl.state[shorty].modeCount end
    if tl.state[shorty].buttonCount > moreKeys then moreKeys = tl.state[shorty].buttonCount end
    if tl.state[shorty].sKey > tl.sKey then tl.sKey = 1 end
    for m=1, tl.state[shorty].buttonCount do
      tl.unname[shorty..m] = tl.unname[shorty..m] or shorty..m
    end
    for h=1, #tl.state[shorty].modeConfig do
      if type(tl.state[shorty].modeConfig[h]) ~= "table" then
        tl.state[shorty].modeConfig[h] = {tl.state[shorty].modeConfig[h]}
      end
    end
  end
  tl.maxMode = moreModes
  for i=1, tl.maxMode do
    tl.genericModes[i]= tl.genericModes[i] or {i};
    if type(tl.genericModes[i]) ~= "table" then
      tl.genericModes[i] = {tl.genericModes[i]}
    end
  end
  tl.maxKeys = moreKeys
end

function tl.toKey(legtab) --push legacy key bindings into the key table and apply default bindings
  for k,v in pairs(legtab) do
    if type(k) == "string" and tl.unname[k] ~= nil then
      legtab.key[k] = legtab.key[k] or v
      legtab[k] = nil
    end
  end
end

function tl.setDefaults(ktab)
  for k,v in pairs(tl.defaultKeys) do
    if ktab[k] == nil then ktab[k] = v end
  end
end

function tl.extend(parentName)
  if parentName == "" or  type(parentName) ~= "string" then return end
  for i = 0, #tl.extendList do local ex=tl.extendList[i]
    if ex == parentName then tl.findEx = tl.findEx.."\n\nWARNING: Extending cancelled due to circular reference to "..parentName.."!\n" return end
  end
  tl.extendList[#tl.extendList+1] = parentName
  local exTable = {tl.extPaths[tl.fileLocation],string.gsub(parentName,"%.lua$","")..".lua"}
  if tl.childPaths == 1 then table.insert(exTable,1,tl.path) end
  local finalExPath = table.concat(exTable,"/")
  loadfile(finalExPath)(tl.assign, tl.assign.key)
end

function tl.loadEx() -- Loads external configuration files depending on profile types
  local pathTable = {tl.extPaths[tl.fileLocation],string.gsub(tl.fileName or tl.profileName,"%.lua$","")..".lua"}
  if tl.childPaths == 1 then table.insert(pathTable,1,tl.path) end
  local finalPath = table.concat(pathTable,"/")
  if tl.fileLocation ~= 0 then
    tl.findEx="Running on external configs ["..finalPath.."]"
    tl.extend(tl.extends)
    loadfile(finalPath)(tl.assign, tl.assign.key)
  elseif tl.fileLocation ~= 0 then
    tl.findEx="Running on internal configs, external file missing or broken. ["..finalPath.."]"
  end
end

function tl.compileAssignments(startable) --main function for parsing the flexible syntax
  local collector = startable.key

  function tabExtract(state,presets,moda) --Extract button functionality and put it into the main table
    tl.inherit(state)
    local stackM = tl[moda.."Stack"]
    local secundus = {}
    local prosits = tl.intersect({},presets)
    local hastype = prosits.type
    local single = prosits.singleType or tl.singleType

    for k,v in pairs(state) do
      if type(k) == "string" and tl.unname[k] ~= nil then
          if type(v) ~= "table" then
              v={v}
              v = tl.intersect(v,prosits,2)
          elseif tl.props(v) or (hastype ~= nil and single == 1) then
            v = tl.intersect(v,prosits,2)
          else
            for u=1, #v do
              if type(v[u]) ~= "table"  then
                v[u]={v[u]}
              end
              v[u] = tl.intersect(v[u],prosits,2)
            end
          end

          if collector[k] == nil then
            collector[k] = v
          else
              if type(collector[k]) ~= "table" or tl.props(collector[k]) == true or tl.noType(collector[k],"table") then
                collector[k]={collector[k]}
              end
              if type(v) ~= "table" or tl.props(v) then
                if stackM == "prepend" then
                  table.insert(collector[k],1,v)
                else
                  collector[k][#collector[k]+1]=v
                end
              else
                for u=1, #v do local h = u
                  if stackM == "prepend" then
                    if tl.stackAutoReverse == 1 then h = #v-u+1 end
                    table.insert(collector[k],1,v[h])
                  else
                    collector[k][#collector[k]+1]=v[h]
                  end
                end
              end
          end
          state[k]=nil
      elseif type(state[k]) == "table" and k ~= "key" then
          secundus[k]=v
          state[k]=nil
      end
    end
    return {secundus,prosits,moda}
  end

  function unhier(t,prevs) --recursively retrieve key definitions from array
    local nextWave={}
    tl.inherit(t)
    prevs = prevs or {}
    local provs = tl.intersect({},prevs)

    function setMode()
      local retVal={}
        for k=0, tl.maxMode do local j = k
          if tl.modeSort == "reverse" then
            j = tl.maxMode-k
          elseif type(tl.modeSort) == "table" and #tl.modeSort == tl.maxMode+1 then
            j = tl.modeSort[k+1]
          end
          if  t["mode"..j] ~=nil then
            local curtable = t["mode"..j]
            provs.mode = j
            retVal[#retVal+1] = tabExtract(curtable,provs,"mode")
            t["mode"..j]=nil
          end
          provs.mode=prevs.mode
        end
      return retVal
    end

    function setShift()
      local retVal={}
      if tl.sKey ~=0 then
        for h = 0 , 2 do local j = h
          if tl.shiftSort == "reverse" then
            j = tl.maxMode-h
          elseif type(tl.shiftSort) == "table" and #tl.shiftSort == 3 then
            j = tl.shiftSort[h+1]
          end
            if t["s"..j] ~=nil then
                local shiftable = t["s"..j]
                provs.gshift = j
                retVal[#retVal+1] = tabExtract(shiftable,provs,"shift")
                t["s"..j] = nil
            end
            provs.gshift=prevs.gshift
          end
        end
      return retVal
    end

    function setCustom()
      local retVal={}
      for r = 1, #tl.customSort do local cusn = tl.customSort[r]
        local privs = {}
        if t[cusn] and t[cusn] == "table" then
          for d,m in pairs(t[cusn]) do
            if type(d) == "string" and tl.unname[d] == nil then privs[d] = m end
          end
          retVal[#retVal+1] = tabExtract(t[cusn],tl.intersect(prevs,privs,1),"custom")
          t[cusn]=nil
        end
      end
      for h,p in pairs(t) do
        local privs = {}
          if string.sub(h,1,2) == "_c" and type(p) == "table" then
            for d,m in pairs(p) do
              if type(d) == "string" and tl.unname[d] == nil then privs[d] = m end
            end
            retVal[#retVal+1] = tabExtract(p,tl.intersect(prevs,privs,1),"custom")
            t[h]=nil
          end
        end
      return retVal
    end

  local ordertable = {custom=setCustom,mode=setMode,shift=setShift}
  for g = 1, #tl.stackOrder do local l = g
    if tl.stackAutoReverse == 1 and tl.modeStack == "prepend" and tl.shiftStack == "prepend" and tl.customStack == "prepend" then
      l = #tl.stackOrder-g+1
    end
    nextWave[#nextWave+1] = ordertable[tl.stackOrder[l]]()
  end
    if tl.full(nextWave) then
      for u=1,#nextWave do local n= nextWave[u]
        for o=1, #n do local x=n[o]
          unhier(x[1],x[2],x[3])
        end
      end
    end
  end

  unhier(startable)
  unhier(startable.key)
  startable = collector
end

function tl.resolveLink(link)
  local lock = link
  local combinedID = ''
  local metaUpdate = false
  while (lock.type == "l") and tl.macroStats[lock[1]] ~=nil do -- If the binding is a link we override the original binding's properties with any new ones
    local lockTarget = lock[1]
    local rideNum = 3
    if lock.keepExisting == 1 then rideNum = 4 end
    local unlock = tl.macroStats[lockTarget].macro
    combinedID = combinedID..lock.pID..unlock.pID
    if tl.dynamicTables[combinedID] ~= nil and tl.cacheLinks == 1 then
      lock = tl.dynamicTables[combinedID]
    else
      local currentUpdate = metaUpdate or lock.update;
      metaUpdate = tl.mergeUpdate(currentUpdate,unlock.update)
      lock = tl.intersect(unlock,lock,rideNum,lock.keepExisting)
      local lack = tl.deepcopy(lock)
      if metaUpdate ~= false and lack.type ~="l" then lock = tl.targetUpdate(metaUpdate,lack) end
      lock.pID = combinedID
      tl.macroStats[combinedID] = tl.macroStats[combinedID] or {macro=lock,check={}}
      tl.dynamicTables[combinedID] = lock
    end
  end
  return lock
end

function tl.keyGen(keyN,fam,lock,keyCode,virt,virtrect,virpar) --function for fetching a button's bindings and feeding it to the execution function.
  local pKey = tl.assign.key[keyCode]
  if virt then pKey = lock end
  lock = tl.resolveLink(lock)
  local cmd = lock
  local playState = "played"
  local playStorage = {}
  if fam and not virt then
    playStorage = tl.lastKeysDown[#tl.lastKeysDown]
  end
  playStorage[playState] = playStorage[playState] or 0
  playStorage[playState] = playStorage[playState] + tl.key(
  keyN,
  cmd,
  lock.type,
  lock.gshift or pKey.gshift or tl.defaultShift,
  lock.mode or pKey.mode or tl.defaultMode,
  lock.mkey or pKey.mkey,
  lock.unlock or pKey.unlock,
  lock.consume or pKey.consume,
  lock.test or pKey.test,
  lock.direction or pKey.direction or "normal",
  lock.pID or pKey.pID,
  virt,
  lock.simDir or pKey.simDir or virtrect,
  virpar,
  lock.area or pKey.area,
  fam or "m",
  lock.family or pKey.family)
  return playStorage[playState]
end


function tl.quickGen(bar,fam) --quick and dirty keyGen call
  if type(bar) ~= "table" or tl.multiTab(args) == false then
    tl.keyGen(0,fam,bar,0,5,1,"down",4)
  elseif type(bar) == "table" then
    for g=1, #bar do local com = bar[g]
      tl.keyGen(0,fam,com,0,5,1,"down",4)
    end
  end
end

function tl.key(mouse,cmd,def,shifted,modi,mkeys,unlock,cons,tes,pDir,ident,virtu,virdir,virp,area,fam,simFam) --the main program for parsing key commands
  local mouseDir = virdir or tl.state[fam].dir
  local stat = tl.macroStats[ident or "null"]
  local lShift = tl.state[fam].shift
  local lMod = tl.state[fam].modus
  local lModif = tl.mods
  local played = 0
  tl.macroStats.null={}

  local function tup(domo) --If specified, do the direction instructions on the key line up with the current input direction?
    local selec = domo or 1
    local reray = {{"normal","down"},{"up","up"}}
    if (mouseDir == reray[selec][2] and pDir == reray[selec][1]) then return true end
    return false
  end

  local function getShift()
    if type(shifted) == "number" and (shifted == 2 or (shifted == lShift))then
      stat.check.shiftPass = true
      return true
      end
    return false
  end

  local function getMode(manual)
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
      if string.sub(moTest,1,1) == "-" then 
        rVal = false
        moTest = string.sub(moTest,2) 
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
        if (type(obj) == "number" and obj < 0) or (type(obj) == "string" and string.sub(obj,1,1) == "-") then
          if getMode(obj) == false then return false end
        elseif getMode(obj) then
          rVal = true
        end
      end
      return rVal
    end
  end

  local function getKey()
    local okayK = false
    if (mkeys == "no" and (lModif == nil or lModif== 0 or #lModif ==0)) or (mkeys ~="no" and (mkeys==nil or mkeys==0 or mkeys=="" or lModif == mkeys)) then
      okayK = true
    elseif type(lModif) == "string" and type(mkeys) == "string" then
      local typeComb = false
      local keyComb = false
      local comTab = {}
      local recTab = {}

      for i in string.gmatch(mkeys, "%a%a") do comTab[#comTab+1] = i end
      for i in string.gmatch(lModif, "%a%a") do  recTab[#recTab+1] = i end

      for i=1,#recTab do local obj = recTab[i]
        typeComb = false
        for d=1,#comTab do local abj = comTab[d]
          if string.match(obj,"%a$") == string.match(abj,"%a$") then
            typeComb = true
          end
          if typeComb == false then
            break
          end
        end
      end

      for i=1,#comTab do local obj = comTab[i]
        keyComb = false
        for d=1,#recTab do local abj = recTab[d]
          if abj == obj or (string.match(obj,"%a") == "g" and string.match(obj,"%a$") == string.match(abj,"%a$")) then
            keyComb = true
          end
          if keyComb == false then
            break
          end
        end
      end
      if keyComb == true and typeComb == true then
        okayK = true
      end
    end
    stat.check.keyPass = okayK
    return okayK
  end

  local function getTest(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
    return (t_test == nil) or tl.testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  end

  local function getArea()
    if area ~= nil and not tl.areaCheckWrapper(area) then return false end
    stat.check.areaPass = true
    return true
  end

  if (tl.but == mouse or virtu) and (virtu or tl.state[fam].conKey ~= mouse) then --starting the process to test if the right modifiers are down.
    if tup() or mouseDir=="down" or (virtu and virdir== nil) then stat.check={} end
  
    if (((mouseDir == "down" or (virtu and virdir == nil)) and getShift())or (mouseDir == "up" and (((unlock == nil or not tl.find(unlock,"shift"))and stat.check.shiftPass) or getShift())))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and getMode()) or (mouseDir == "up" and (((unlock == nil or not tl.find(unlock,"mode")) and stat.check.modePass) or getMode())))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and getKey())  or (mouseDir == "up" and (((unlock == nil or not tl.find(unlock,"mkeys"))and stat.check.keyPass) or getKey())))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and getArea()) or (mouseDir == "up" and (((unlock == nil or not tl.find(unlock,"area")) and stat.check.areaPass) or getArea())))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and getTest(tes,mouse,virtu,fam,mouseDir,ident)) or (mouseDir == "up" and (((unlock == nil or not tl.find(unlock,"test")) and stat.check.testPass) or getTest(tes,mouse,virtu,fam,mouseDir,ident))))
    then

      def = def or "n"
      local tabs = tl.defaultFuncs
      if virtu and virtu ~= 2 and virdir == nil then
        mouseDir = nil
        tabs = tl.funcRayM
      elseif tup() then
        tabs = tl.funcRayU
      elseif tup(2) then
        tabs = tl.funcRayD
      end
      
      if tabs[def] then 
        tabs[def](cmd,mouseDir,pDir,mouse,virtu,virp,fam,simFam) 
        played = 1 
      end
      
      if not virtu and (cons == 1  or cons==3) then
        tl.state[fam].conKey = mouse
      else
        tl.state[fam].conKey = 0
      end
    end
  end
  return played
end

function tl.testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  local tes = t_test
  local mouse = t_mouse
  local virtu = t_virt
  local mdir = t_dir
  local ident = t_ident
  local stat = tl.macroStats[t_ident or "null"]
  local fam = t_fam

  local function recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
    local tes = ind or tes
    if type(ind) == "boolean" then
      return ind
    end
    local tas = tes

    if type(tes) == "table" then --recursively testing arrays
      local m = tes.mode or "or"
      local sucs = {}
      for i=1,#tes do local obj = tes[i]
        local subtest = recursiveTest(obj)
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
      t = table.remove(attriT,1)
      end
      local tres = (neg == nil)
      t = tl.unname[t] or t
      if string.sub(t,1,1) =="#" then
        local faRay = {}
        for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..string.sub(t,2) end
        faRay.mode="or"
        if recursiveTest(faRay) == false then tres = not tres end
      elseif string.find(t,"^%a") == nil then
        t= fam..t
      end
      if string.sub( t,-1) == "#" then
        local sFam = string.sub( t,1,1)
        for k,v in pairs(tl.downs) do
          if type(k) == "string" and k~= fam..mouse and string.sub(k,1,1) == sFam and ((not hasAttribute) or attribuTest(attriT,v)) then return tres end
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
        if string.sub(sub,1,1) =="#" then
          local faRay = {}
          for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..string.sub(sub,2) end
          for d=1,#faRay do
            if singleCheck(faRay[d],arr) then return true end
          end
          return false
        elseif  string.find(sub,"^%a") == nil then
          sub = fam..sub
        end
        if string.sub( sub,-1) == "#" then
          return string.sub(arr.name,1,1) == string.sub(sub,1,1)
        end
        sub = tl.unname[sub] or sub
        return (arr.name == sub)
      end

      for g = 1, #testRay do local i = #testRay-g+1 local unit = testRay[i]
        local attriT
        if hasAttribute then
        attriT = tl.splitter(unit,"@")
        unit = table.remove(attriT,1)
        end
        local nopster = string.sub(unit, 1,1) == "|"
        if nopster then unit = string.sub(unit,2) end
        if
          (nopster == false and singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) and (not hasAttribute or attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff])))
        or
           (nopster == true and (not singleCheck(unit,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) or (hasAttribute and attribuTest(attriT,tl.lastKeysDown[#tl.lastKeysDown-g+virtoff]) == false)))
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

    local function attribuTest(subject,subRay)
      if #subject == 1 then return true end
      for o=1,#subject do local unit = tl.splitter(subject[o],"=")
        local key = unit[1]
        local val = unit[2]
        if tostring(subRay[key]) ~= val then return false end
      end
      return true
    end

    local function varTest(varString)
      local varSplit = tl.splitter(varString,"=")
      if #varSplit == 2 then
        return tl.stateVars[varSplit[1]] == varSplit[2]
      else
        return tl.stateVars[varString]
      end
    end

    if type(tes) == "string" then
      local hasAttribute = (#tl.splitter(tes,"@") > 1)
      local desig= string.sub(tes, 1,1)
      if desig == "-" then
        return presenTest(string.sub(tes,2),1)
      elseif desig == "^" then 
        return pasTest(string.sub(tes,2))
      elseif desig== "|" then
        return pasTest(string.sub(tes,2),1)
      elseif desig == ":" then
        return seqTest(string.sub(tes,2))
      elseif desig == "~" then
        return seqTest(string.sub(tes,2),1)
      elseif desig == "." then
        return varTest(string.sub(tes,2))
      else
        return presenTest(tes)
      end
    end
  end

  if recursiveTest(tes) then stat.check.testPass = true return true end
  return false
end