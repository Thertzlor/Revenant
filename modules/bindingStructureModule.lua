local tl = ...
local abs, sub, match, gsub, find, type, insert, remove, concat, tostring, pairs, gmatch, next =
math.abs, string.sub, string.match, string.gsub, string.find,type, table.insert, table.remove, table.concat,tostring,pairs,string.gmatch, next
--->>> The main framework functions for the script, controls parsing and execution of user defined bindings =============================================================

function tl._prepKeys(prepTable) --Prepare the key assignments array
  prepTable.library={}
  prepTable.start={}
  prepTable.exit={}
  prepTable.scopeDefaults={}
  prepTable.scopeOverride={}
  prepTable.key={}
  prepTable.documentation=tl._fetchDocs()
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
  resign(prepTable)
end

function tl._config(configurator,init)
  local nextTable
  for i=1, #tl.profileBuffer do local pro = tl.profileBuffer[i]
    if pro._processed == false then nextTable = pro break end
  end
  if type(configurator) == "table" then
    for k,v in pairs(configurator) do
     tl.oldConfig[k] = tl[k]
      tl[k] = configurator[k] or tl[k]
    end
  end
  if (configurator and nextTable) or init then
    if nextTable then nextTable._configurator = configurator end
    if init or configurator.resolutions then
      tl.compileScreenCoordinates()
    end
    tl._defineDevices()
    tl._prepKeys(nextTable)
  end
end

function tl._restoreConfigs()
  for k,v in pairs(tl.oldConfig) do
     tl[k] = tl.oldConfig[k]
  end
  tl.oldConfig={}
end

function tl._fetchDocs()
  if tl.docFile == 0 then return {} end
  local fPath = ''
  if tl.docPath ~= 0 then fPath = tl.docPath end
  local fName = gsub(tl.fileName or tl.profileName,"%.lua$","")..tl.docSuffix..'.lua'
  if tl.docName ~= 0 then fName = gsub(tl.docName,"%.lua$","")..".lua" end
  return loadfile(concat({tl.path,tl.extPaths[tl.fileLocation],fPath,fName}, "/"))()
end

function tl._defineDevices() -- Prepare Device profiles using user defined names for keys
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
   --  tl[fam.."ButtonCount"] = nil
   -- tl[fam.."ModeCount"] = nil
   -- tl[fam.."ShiftKey"] = nil
   -- tl[fam.."ModeConfig"] = nil
   -- tl[fam.."BindHardwareModes"] = nil
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

function tl.buildBindings()
  tl._defineDevices()
  local path = tl._getPath()
  local profileName = path or tl.profileName
  tl._loadIntoBuffer(profileName,path,1)
  tl._mergeBuffers()
end

function tl._setDefaults(ktab)
  for k,v in pairs(tl.defaultKeys) do
   ktab[k] = ktab[k] or  v
  end
end

function tl._loadIntoBuffer(name,path,init)
  tl.profileBuffer[#tl.profileBuffer+1] = {_fileOrigin=name,key={}, _processed=false, _bufferNum = #tl.profileBuffer+1}
  local bufferContainer = tl.profileBuffer[#tl.profileBuffer]
  local bufferNum = #tl.profileBuffer
  tl._config(nil,init)
  if path then loadfile(path)(bufferContainer, bufferContainer.key) end
  if init then
    tl.extend(tl.extends)
    tl.setKeys(bufferContainer,bufferContainer.key)
  end
  tl._compileAssignments(bufferContainer)
  tl._setDefaults(bufferContainer.key)
  tl.inherit(bufferContainer.key,bufferContainer,1)
  if init or tl.keepCustomNames == 0 then tl._unRenameKeys(bufferContainer.key) end
  tl.tablecrawl(bufferContainer,bufferNum)
  bufferContainer._processed = true;
end

function tl._getMacros(tar)
  local scope = tl.macroStats[tar._scope or 1]
  if tar.pID then
  tl.macroStats[tar.pID] = scope[tar.pID]
  scope[tar.pID] = nil
  tar._scope = nil
  end
  for _,n in pairs(tar) do
    if type(n) == "table" then
      tl._getMacros(n)
    end
  end
end

function tl._unRenameKeys(tab)
  for k,v in pairs(tl.rename) do
    --tl.prettyTab({tab[k],tab[v]})
    tab[k],tab[v] = tab[v],tab[k]
  end
end

function tl.extend(parentName)
  if parentName == "" or  type(parentName) ~= "string" then return end
  for i = 1, #tl.profileBuffer do local ex=tl.profileBuffer[i]._fileOrigin
    if ex == parentName then tl.findEx = tl.findEx.."\n\nWARNING: Extending cancelled due to circular reference to "..parentName.."!\n" return end
  end
  local exTable = {tl.extPaths[tl.fileLocation],gsub(parentName,"%.lua$","")..".lua"}
  if tl.childPaths == 1 then insert(exTable,1,tl.path) end
  local finalExPath = concat(exTable,"/")
  tl._loadIntoBuffer(parentName,finalExPath)
end

function tl._mergeBuffers()
  if #tl.profileBuffer == 1 then
    tl.assign = tl.profileBuffer[1]
    tl.scopeNames(tl.assign,1)
    tl._getMacros(tl.assign)
    tl.elimiNames(1)
    --tl.prettyTab(tl.macroStats,"your face")
  else
    local mainLib = tl.assign.library
    for i=1,#tl.profileBuffer do local currentBuffer = tl.profileBuffer[i]

      if tl.handleOptionConflicts == "overwriteAll" or (tl.handleOptionConflicts == "discardAll" and next(currentBuffer.library) == nil) then
        tl.assign.library = currentBuffer.library
          elseif tl.handleOptionConflicts ~= "discardAll" then
            for m=1,#currentBuffer._configurator do local option = currentBuffer._configurator[m]

              local duped = false
              for n=1,#mainLib do local compareObject = mainLib[n]
              if compareObject.name == option then
              duped = true
              if tl.handleOptionConflicts == "replaceDuplicates" then
                mainLib[n] = option
              end
            end
            if not duped then
              mainLib[#mainLib+1] = option
            end
          end
        end
      end

      if tl.handleLibraryConflicts == "overwriteAll" or (tl.handleLibraryConflicts == "discardAll" and #mainLib == 0) or tl.handleLibraryConflicts == i then
        tl.assign.library = currentBuffer.library
          elseif type(tl.handleLibraryConflicts) == "string" and tl.handleLibraryConflicts ~= "discardAll" then
            for m=1,#currentBuffer.library do local libObject = currentBuffer.library[m]
              if libObject.name then
                local duped = false
                for n=1,#mainLib do local compareObject = mainLib[n]
                if compareObject.name == libObject.name then
                duped = true
                if tl.handleLibraryConflicts == "replaceDuplicates" then
                  mainLib[n] = libObject
                end
              end
            end
            if not duped then
              mainLib[#mainLib+1] = libObject
            end
          end
        end
      end

      local mainDocs = tl.assign.documentation

      if tl.handleDocumentationConflicts == "useLast" or (tl.handleDocumentationConflicts == "useFirst" and next(mainDocs) == nil) or tl.handleDocumentationConflicts == i then
        tl.assign.documentation = currentBuffer.documentation
          elseif type(tl.handleDocumentationConflicts) == "string" and tl.handleDocumentationConflicts ~= "discardAll" then
            for m=1,#currentBuffer.library do local libObject = currentBuffer.library[m]
              if libObject.name then
                local duped = false
                for n=1,#mainLib do local compareObject = mainLib[n]
                if compareObject.name == libObject.name then
                duped = true
                if tl.handleDocumentationConflicts == "replaceDuplicates" then
                  mainLib[n] = libObject
                end
              end
            end
            if not duped then
              mainLib[#mainLib+1] = libObject
            end
          end
        end
      end

    end
  end

  for i=1,#tl.macroStats do
  tl.macroStats[i] = nil
  end
  tl.profileBuffer = nil
end

function tl.loadEx() -- Loads external configuration files depending on profile types
  return
end

function tl._getPath()
  local pathTable = {tl.extPaths[tl.fileLocation],gsub(tl.fileName or tl.profileName,"%.lua$","")..".lua"}
  if tl.childPaths == 1 then insert(pathTable,1,tl.path) end
  local finalPath = concat(pathTable,"/")
  if tl.fileLocation ~= 0 then
    tl.findEx="Running on external configs ["..finalPath.."]"
    return finalPath
  elseif tl.fileLocation ~= 0 then
    tl.findEx="Running on internal configs, external file missing or broken. ["..finalPath.."]"
  end
  return nil
end

function tl._compileAssignments(startable) --main function for parsing the flexible syntax
  local collector = startable.key

  local function tabExtract(state,presets,moda) --Extract button functionality and put it into the main table
    tl.inherit(state,startable)
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
                  insert(collector[k],1,v)
                else
                  collector[k][#collector[k]+1]=v
                end
              else
                for u=1, #v do local h = u
                  if stackM == "prepend" then
                    if tl.stackAutoReverse == 1 then h = #v-u+1 end
                    insert(collector[k],1,v[h])
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

  local function unhier(t,prevs) --recursively retrieve key definitions from array
    local nextWave={}
    tl.inherit(t,startable)
    prevs = prevs or {}
    local provs = tl.intersect({},prevs)

  local function setMode()
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

    local function setShift()
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

    local function setCustom()
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
          if sub(h,1,2) == "_c" and type(p) == "table" then
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

function tl.keyGen(keyN,fam,lock,keyCode,virt,virtrect,originator) --function for fetching a button's bindings and feeding it to the execution function.
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
  playStorage[playState] = playStorage[playState] + tl._key(
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
  originator,
  lock.area or pKey.area,
  fam or "m",
  lock.family or pKey.family)
  return playStorage[playState]
end

function tl.quickGen(bar,fam) --quick and dirty keyGen call
  if tl.isContainer(bar) == false then
    tl.keyGen(0,fam,bar,0,5)
  else
    for g=1, #bar do local com = bar[g]
      tl.keyGen(0,fam,com,0,5)
    end
  end
end

function tl._matchButtonDirection(selec,dir1,dir2) --If specified, do the direction instructions on the key line up with the current input direction?
  local reray = {{"normal","down"},{"up","up"}}
  if (dir1 == reray[selec][2] and dir2 == reray[selec][1]) then return true end
  return false
end

function tl._getShift(stat,shifted,lShift)
  if type(shifted) == "number" and (shifted == 2 or (shifted == lShift))then
    stat.check.shiftPass = true
    return true
    end
  return false
end

function tl._getMode(stat,modi,lMod,fam,manual)
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
      if (type(stat,modi,lMod,obj) == "number" and obj < 0) or (type(obj) == "string" and sub(obj,1,1) == "-") then
        if tl._getMode(stat,modi,lMod,fam,obj) == false then return false end
      elseif tl._getMode(stat,modi,lMod,fam,obj) then
        rVal = true
      end
    end
    return rVal
  end
end

function tl._getKey(stat,mkeys,lModif)
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

function tl._getTest(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  return (t_test == nil) or tl._testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
end

function tl._getArea(stat,area)
  if area ~= nil and not tl.areaCheckWrapper(area) then return false end
  stat.check.areaPass = true
  return true
end

function tl._testEvaluation(t_test,t_mouse,t_virt,t_fam,t_dir,t_ident)
  local tes = t_test
  local mouse = t_mouse
  local virtu = t_virt
  local mdir = t_dir
  local ident = t_ident
  local stat = tl.macroStats[t_ident or "null"]
  local fam = t_fam
  local hasAttribute

  local function recursiveTest(ind) --evaluating the "test" conditions of a key.(recursive)
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
      t = remove(attriT,1)
      end
      local tres = (neg == nil)
      t = tl.unname[t] or t
      if sub(t,1,1) =="#" then
        local faRay = {}
        for h=1, #tl.families do faRay[#faRay+1]=tl.token(tl.families[h])..sub(t,2) end
        faRay.mode="or"
        if recursiveTest(faRay) == false then tres = not tres end
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

  if recursiveTest(tes) then stat.check.testPass = true return true end
  return false
end

function tl._key(mouse,cmd,def,shifted,modi,mkeys,unlock,cons,tes,pDir,ident,virtu,virdir,originator,area,fam,simFam) --the main program for parsing key commands
  local mouseDir = virdir or tl.state[fam].dir
  local stat = tl.macroStats[ident or "null"]
  local lShift = tl.state[fam].shift
  local lMod = tl.state[fam].modus
  local lModif = tl.mods
  local played = 0
  tl.macroStats.null={}

  if (tl.but == mouse or virtu) and (virtu or tl.state[fam].conKey ~= mouse) then --starting the process to test if the right modifiers are down.
    if tl._matchButtonDirection(1,mouseDir,pDir) or mouseDir=="down" or (virtu and virdir== nil) then stat.check={} end

    if (((mouseDir == "down" or (virtu and virdir == nil)) and tl._getShift(stat,shifted,lShift))or (mouseDir == "up"
      and (((unlock == nil or not tl.find(unlock,"shift"))and stat.check.shiftPass) or tl._getShift(stat,shifted,lShift))))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and tl._getMode(stat,modi,lMod,fam)) or (mouseDir == "up"
      and (((unlock == nil or not tl.find(unlock,"mode")) and stat.check.modePass) or tl._getMode(stat,modi,lMod,fam))))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and tl._getKey(stat,mkeys,lModif))  or (mouseDir == "up"
      and (((unlock == nil or not tl.find(unlock,"mkeys"))and stat.check.keyPass) or tl._getKey(stat,mkeys,lModif))))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and tl._getArea(stat,area)) or (mouseDir == "up"
      and (((unlock == nil or not tl.find(unlock,"area")) and stat.check.areaPass) or tl._getArea(stat,area))))
    and(((mouseDir == "down" or (virtu and virdir == nil)) and tl._getTest(tes,mouse,virtu,fam,mouseDir,ident)) or (mouseDir == "up"
      and (((unlock == nil or not tl.find(unlock,"test")) and stat.check.testPass) or tl._getTest(tes,mouse,virtu,fam,mouseDir,ident))))
    then

      if tl.docMode and not virtu and cmd.type ~= "doc" then tl.document(cmd,fam,mouse) end
      def = def or "n"
      local tabs = tl.defaultFuncs
      if virtu and virtu ~= 2 and virdir == nil then
        mouseDir = nil
        tabs = tl.funcRayM
      elseif tl._matchButtonDirection(1,mouseDir,pDir) then
        tabs = tl.funcRayU
      elseif tl._matchButtonDirection(2,mouseDir,pDir) then
        tabs = tl.funcRayD
      end

      if tabs[def] then
        tabs[def](cmd,mouseDir,mouse,virtu,fam,simFam,originator,pDir)
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