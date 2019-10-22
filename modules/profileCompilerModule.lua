local sub, gsub, type, insert, concat, pairs, next, loadfile, match, remove =
string.sub, string.gsub,type, table.insert, table.concat,pairs, next, loadfile, string.match, table.remove
---@type MainLibObject
local tl = ...
-->>>>  Functions that compile profiles and key bindings ==================================================================

---Revert configs to their previous value.
local function _restoreConfigs()
  for k,v in pairs(tl.oldConfig) do
     tl.config[k] = v
  end
end

---Eliminate names from tables and count them.
local function _elimiNames()
  local stats
  for i = 0,#tl.macroStats do stats = tl.macroStats[i]
    if i == 0 then stats =tl.macroStats end
    for k,_ in pairs(stats) do
      if stats[k].macro and stats[k].macro.name then
        stats[k].macro.name = nil
        tl.namedTables = tl.namedTables+1
      end
    end
  end
end

---Pass parent properties to child tables
---@param taba GenericMacro
---@param origTable GenericMacro
---@param globalis table
local function _inherit(taba,origTable,globalis)
  for k,d in pairs(taba) do
    local rideray = {}
    local gloverbal = {}
    if globalis == 1 then
    rideray = origTable.scopeDefaults or {}
    gloverbal = origTable.scopeOverride or {}
    end

    if type(k) == "string" and tl.unname[k] ~= nil then
      if type(d) == "table" and tl.props(d) == false then
        local m = 1
        while d[m] ~= nil do local v = d[m]
          if type(v) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
            v = {v}
          end
          if type(v) == "table" then
            if #v == 0 then --Arrays without any non-string keys are local override arrays.
              rideray = tl.intersect(rideray,v,1) -- properties are added to the override array
              remove(d,m)
              m=m-1
            elseif tl.props(tl.intersect(rideray,gloverbal,1)) then
              taba[k][m] = tl.intersect(tl.intersect(v,rideray),gloverbal,1)
            end
          end
          m=m+1
        end
      elseif type(d) == "table" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      elseif type(d) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        d = {d}
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      elseif type(d) == "string" then
        taba[k] = {taba[k]}
      end
    end
  end
  if globalis == 1 then
    tl.assign.scopeDefaults = nil
    tl.assign.scopeOverride = nil
  end
end

---resolves the names of tables into table IDs based on their profile's scope
---@param tar GenericMacro|ProfileDefinition
---@param scope number
---@param startType string
local function _scopeNames(tar,scope,startType)

  ---The subfunction for resolving individual IDs
  ---@param name string
  local function getID(name)
    local ancestorKey, libraryKey
    if name == nil or (tl.config.globalScopeKeys and tl.unname(name)) then return name end
    for i=scope,#tl.macroStats do local stat = tl.macroStats[i]
      for k, _ in pairs(stat) do
        if stat[k].macro and stat[k].macro.name == name then
          stat[k].referenced=true
          ancestorKey = k
          break
        end
      end
    end
    for k, _ in pairs(tl.macroStats) do
      if tl.macroStats[k].macro and tl.macroStats[k].macro.name == name then
        tl.macroStats[k].referenced=true
        libraryKey = k
      end
    end
    return (tl.config.preferLibraryMacros and libraryKey) or ancestorKey or libraryKey or name
  end

  local currentType = tar.type or startType
  if currentType == "l" then
    tar[1] = getID(tar[1])
  elseif currentType == "s" or currentType == "c" or currentType == "h"
  then
    for i = 1, #tar do local obj = tar[i]
      if type(obj) == "table" and #obj == 1 and tl.props(obj) == false and type(obj[1]) == "string" then
        obj[1] = getID(obj[1])
      end
    end
  elseif
  currentType == "sa" or
  currentType == "sp" or
  currentType == "sr" or
  currentType == "cr" or
  currentType == "hc"
  then
    if tar[1] and type(tar[1]) == "string" then
    tar[1] = getID(tar[1])
    end
  end

  local function scopeTests(tesTable)
    for k,v in ipairs(tesTable) do
      if type(v) == "table" then
        scopeTests(tesTable[k])
      elseif type(v) == "string" and match(v,"^[:~]") then
        tesTable[k] = sub(v,1,1)..getID(sub(v,2))
      end
    end
  end

  local function scopeUpdates(updateProp)
    if updateProp[4] and type(updateProp[4]) == "string" then
      updateProp[4] = getID(updateProp[4])
    end
  end

  if tar.test then
    local cTest = tar.test
    if type(cTest) == "string" and match(cTest,"^[:~]") then
      tar.test = sub(cTest,1,1)..getID(sub(cTest,2))
    elseif type(cTest) == "table" then
      scopeTests(tar.test)
    end
  end

  if tar.update and type(tar.update) == "table" then
    if tl.allType(tar.update,"table") == false then
      scopeUpdates(tar.update)
    else
      for i=1, #tar.update do
        scopeUpdates(tar.update[i])
      end
    end
  end

  for _,n in pairs(tar) do
    if type(n) == "table" then
      _scopeNames(n,scope,tar.cast)
    end
  end
end

---Prepare Device profiles using user defined names for keys
local function _defineDevices()
  local moreModes = 0
  local moreKeys = 0
  for k,v in  pairs(tl.config.rename) do
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
      buttonCount = tl.config[fam.."ButtonCount"],
      sKey = tl.config[fam.."ShiftKey"],
      modeCount = tl.config[fam.."ModeCount"],
      modeConfig = tl.config[fam.."ModeConfig"],
      bindHardwareModes = tl.config[fam.."BindHardwareModes"],
      stable = {},
      unstable = {}
    }
    if tl.config.defaultModeTarget == "join" then
      tl.state[shorty].modeConfig=tl.config.genericModes
    end
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
    tl.config.genericModes[i]= tl.config.genericModes[i] or {i};
    if type(tl.config.genericModes[i]) ~= "table" then
      tl.config.genericModes[i] = {tl.config.genericModes[i]}
    end
  end
  tl.maxKeys = moreKeys
end

---Get the documentation from profile or external file.
local function _fetchDocs()
  if tl.config.docFile == 0 then return {} end
  local fPath = ''
  if tl.config.docPath ~= 0 then fPath = tl.config.docPath end
  local fName = gsub(tl.fileName or tl.config.profileName,"%.lua$","")..tl.config.docSuffix..'.lua'
  if tl.config.docName ~= 0 then fName = gsub(tl.config.docName,"%.lua$","")..".lua" end
  return loadfile(concat({tl.config.path,tl.config.extPaths[tl.config.fileLocation],fPath,fName}, "/"))()
end

---Prepare the key assignments array
---@param prepTable ProfileDefinition
local function _prepKeys(prepTable)
  prepTable.library={}
  prepTable.start={}
  prepTable.exit={}
  prepTable.scopeDefaults={}
  prepTable.scopeOverride={}
  prepTable.key={}
  prepTable.documentation=_fetchDocs()
  local function resign(tagta,cdepth)
    local depth = cdepth or 0
    if tl.sKey ~= 0 then
      for p=0, 2 do
        tagta["s"..p]={}
        if depth < tl.config.stackDepth then resign(tagta["s"..p],depth+1) end
      end
    end
    for i = 0, tl.maxMode do
      tagta["mode"..i]={}
      if depth < tl.config.stackDepth then resign(tagta["mode"..i],depth+1) end
    end
  end
  resign(prepTable)
  resign(prepTable.key)
  return prepTable
end

---Set the default mouse buttons 3-5.
---@param ktab table
local function _setDefaults(ktab)
  for k,v in pairs(tl.config.defaultKeys) do
   ktab[k] = ktab[k] or  v
  end
end

---Apply T-Lib options.
---@param configurator OptionsCollection
---@param init boolean
local function _config(configurator,init)
  local nextTable
  for i=1, #tl.profileBuffer do local pro = tl.profileBuffer[i]
    if pro._processed == false then nextTable = pro break end
  end
  if type(configurator) == "table" then
    for k,_ in pairs(configurator) do
      tl.oldConfig[k] = tl.config[k]
      tl.config[k] = configurator[k] or tl.config[k]
    end
    if not tl.config.retainFlexCompilationSettings then
      for i = 1, #tl.flexConfigNames do local obj = tl.flexConfigNames[i]
          tl.config[obj] = tl.oldConfig[obj]
      end
    end
  end
  if (configurator and nextTable) or init then
    if nextTable then nextTable._configurator = configurator end
    if init or configurator.resolutions then
      tl.compileScreenCoordinates()
    end
    _defineDevices()
    _prepKeys(nextTable)
  end
end

---Main function for parsing the flexible syntax
---@param startable ProfileDefinition
local function _compileAssignments(startable)
  local collector = startable.key

  local function tabExtract(state,presets,moda) --Extract button functionality and put it into the main table
    _inherit(state,startable)
    local stackM = tl.config[moda.."Stack"]
    local secundus = {}
    local prosits = tl.intersect({},presets)
    local hastype = prosits.type
    local single = prosits.singleType or tl.config.singleType

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
              if tl.config.keyNamesAreMacroNames and not collector[k].name then
                collector[k].name = k
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
                    if tl.config.stackAutoReverse then h = #v-u+1 end
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
    _inherit(t,startable)
    prevs = prevs or {}
    local provs = tl.intersect({},prevs)

    local function setMode()
      local retVal={}
        for k=0, tl.maxMode do local j = k
          if tl.config.modeSort == "reverse" then
            j = tl.maxMode-k
          elseif type(tl.config.modeSort) == "table" and #tl.config.modeSort == tl.maxMode+1 then
            j = tl.config.modeSort[k+1]
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
          if tl.config.shiftSort == "reverse" then
            j = tl.maxMode-h
          elseif type(tl.config.shiftSort) == "table" and #tl.config.shiftSort == 3 then
            j = tl.config.shiftSort[h+1]
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
      for r = 1, #tl.config.customSort do local cusn = tl.config.customSort[r]
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
  for g = 1, #tl.config.stackOrder do local l = g
    if tl.config.stackAutoReverse and tl.config.modeStack == "prepend" and tl.config.shiftStack == "prepend" and tl.config.customStack == "prepend" then
      l = #tl.config.stackOrder-g+1
    end
    nextWave[#nextWave+1] = ordertable[tl.config.stackOrder[l]]()
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

---Dissolve MacroCollections that do not have names
---@param bufferNum number
local function _flattenCollections(bufferNum)
  local possibleConts = {"key","start","exit","library"}
  local keyTable = tl.assign
  if bufferNum then keyTable = tl.profileBuffer[bufferNum] end
  local function dissolve(t)
    if tl.isContainer(t) then
      for i=1,#t do
        if tl.isContainer(t[i]) and tl.macroStats[t[i].pID].referenced == nil then
          local tablu = t[i]
          table.remove(t, i)
          for a=1,#tablu do
            table.insert( t,i,dissolve(tablu[#tablu-a+1]))
          end
        end
      end
      if tl.macroStats[t.pID] and tl.macroStats[t.pID].macro then tl.macroStats[t.pID].macro = t end
    end
    return t
  end
  for a=1,#possibleConts do local prop = possibleConts[a]
    for k,_ in pairs(keyTable[prop]) do
      keyTable[prop][k] = dissolve(keyTable[prop][k])
    end
  end
end

---Creates a reference table for renamed keys
---@param tab table
local function _unRenameKeys(tab)
  for k,v in pairs(tl.config.rename) do
    tab[k],tab[v] = tab[v],tab[k]
  end
end

---Convert Macro names in the documentation to unique ids.
local function _scopeDocs()
  for _,v in pairs(tl.macroStats) do local mac = v.macro
    if mac and mac.name and tl.assign.documentation[mac.name] then
      tl.assign[mac.pID] = tl.assign.documentation[mac.name]
      tl.assign.documentation[mac.name] = nil
    end
  end
end

---Load a profile from an external file into its own buffer.
---@param name string
---@param path string
---@param init boolean
local function _loadIntoBuffer(name,path,init)

  ---Imports linked Profile files
  ---@param parentName string
  local function _extend(parentName)
    if parentName == "" or  type(parentName) ~= "string" then return end
    for i = 1, #tl.profileBuffer do local ex=tl.profileBuffer[i]._fileOrigin
      if ex == parentName then tl.locationIndicator = tl.locationIndicator.."\n\nWARNING:Prevented circular or duplicate inheritance from'"..parentName.."'!\n" return end
    end
    if #tl.profileBuffer > tl.config.maxInheritanceDepth then tl.locationIndicator = tl.locationIndicator.."\n\nInheritance process stopped, due to number of profiles exceeding the maximum amount of "..tl.config.maxInheritanceDepth..".\n" return end
    local exTable = {tl.config.extPaths[tl.config.fileLocation],gsub(parentName,"%.lua$","")..".lua"}
    if tl.config.childPaths then insert(exTable,1,tl.config.path) end
    local finalExPath = concat(exTable,"/")
    _loadIntoBuffer(parentName,finalExPath)
  end

  tl.profileBuffer[#tl.profileBuffer+1] = {_fileOrigin=name, key={}, _processed=false,extend = _extend}
  local bufferContainer = tl.profileBuffer[#tl.profileBuffer]
  local bufferNum = #tl.profileBuffer
  bufferContainer._scope = bufferNum
  _config(nil,init)
  _prepKeys(bufferContainer)
  if path then loadfile(path)(bufferContainer,bufferContainer.key,tl) end
  if init then
    _extend(tl.config.extends)
    tl.setKeys(bufferContainer,bufferContainer.key)
  end
  _compileAssignments(bufferContainer)
  _setDefaults(bufferContainer.key)
  _inherit(bufferContainer.key,bufferContainer,1)
  if init or not tl.keepCustomNames then _unRenameKeys(bufferContainer.key) end
  tl.tablecrawl(bufferContainer,bufferNum)
  bufferContainer._processed = true;
end

---Loads the Macro definitions from separate profiles into the main active profile
---@param tar ProfileDefinition
local function _getMacros(tar)
  local scope = tl.macroStats[tar._scope or 1]
  if tar.pID and tl.macroStats[tar.pID] == nil then
    tl.macroStats[tar.pID] = scope[tar.pID]
    scope[tar.pID] = nil
    tar._scope = nil
  end
  for _,n in pairs(tar) do
    if type(n) == "table" then
      _getMacros(n)
    end
  end
end

local function _mergeBuffers()
  if #tl.profileBuffer == 1 then
    tl.assign = tl.profileBuffer[1]
    _scopeNames(tl.assign,1)
  else
    local optionStorage = {}
    local mainLib = {}
    local mainDocs = {}
    local mainKeys = {}
    local mainStart = {}
    local mainExit = {}
    for i=#tl.profileBuffer,1,-1 do local currentBuffer = tl.profileBuffer[i]
      if tl.config.handleOptionConflicts == "useLast" or (tl.config.handleOptionConflicts == "useFirst" and next(optionStorage) == nil) or tl.config.handleOptionConflicts == i then
        optionStorage = currentBuffer._configurator
      elseif type(tl.config.handleOptionConflicts) == "string" and tl.config.handleOptionConflicts ~= "useFirst" then
        for k,v in pairs(currentBuffer.documentation) do
          if optionStorage[k] == nil or tl.config.handleOptionConflicts == "replaceDuplicates" then
            optionStorage[k] = v end
        end
      end
    end

    _config(optionStorage)
    for i=#tl.profileBuffer,1,-1 do local currentBuffer = tl.profileBuffer[i]
      if tl.config.handleDocumentationConflicts == "useLast" or (tl.config.handleDocumentationConflicts == "useFirst" and next(mainDocs) == nil) or tl.config.handleDocumentationConflicts == i then
        mainDocs = currentBuffer.documentation
      elseif type(tl.config.handleDocumentationConflicts) == "string" and tl.config.handleDocumentationConflicts ~= "useFirst" then
        for k,v in pairs(currentBuffer.documentation) do
          if mainDocs[k] == nil or tl.config.handleDocumentationConflicts == "replaceDuplicates" and not tl.find(tl.internalProps,k) then
            mainDocs[k] = v end
        end
      end

      if tl.config.handleLibraryConflicts == "useLast" or (tl.config.handleLibraryConflicts == "useFirst" and #mainLib == 0) or tl.config.handleLibraryConflicts == i then
        mainLib = currentBuffer.library
      elseif type(tl.config.handleLibraryConflicts) == "string" and tl.config.handleLibraryConflicts ~= "useFirst" then
        for m=1,#currentBuffer.library do local libObject = currentBuffer.library[m]
          if libObject.name then
            local duped = false
            for n=1,#mainLib do local compareObject = mainLib[n]
              if compareObject.name == libObject.name then
              duped = true
              if tl.config.handleLibraryConflicts == "replaceDuplicates" then
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
    tl.assign.library = mainLib
    _getMacros(tl.assign)
    for i=#tl.profileBuffer,1,-1 do local currentBuffer = tl.profileBuffer[i]
      _scopeNames(currentBuffer,i)
      _flattenCollections(i)
      if tl.config.handleKeyConflicts == "useLast" or (tl.config.handleKeyConflicts == "useFirst" and next(mainKeys) == nil) or tl.config.handleKeyConflicts == i then
        mainKeys = currentBuffer.key
        mainStart = currentBuffer.start
        mainExit = currentBuffer.exit
      elseif type(tl.config.handleKeyConflicts) == "string" and tl.config.handleKeyConflicts ~= "useFirst" then
        if not tl.isContainer(mainExit) then mainExit = {mainExit} end
        if not tl.isContainer(mainStart) then mainStart = {mainStart} end

        if next(mainStart) == nil or tl.config.handleKeyConflicts == "replaceDuplicates" then
          mainStart = currentBuffer.start
        elseif tl.config.handleKeyConflicts == "prepend" then
          if not tl.isContainer(mainStart) then mainStart = {mainStart} end
            if tl.isContainer(currentBuffer.start,1) then
              for u = 1 , #currentBuffer.start do table.insert(mainStart, 1, currentBuffer.start[u])end
            else
              table.insert(mainStart, 1, currentBuffer.start)
            end
        elseif tl.config.handleKeyConflicts == "append" then
          if not tl.isContainer(mainStart) then mainStart = {mainStart} end
          if tl.isContainer(currentBuffer.start,1) then
            for u = 1 , #currentBuffer.start do mainStart[#mainStart+1] = currentBuffer.start[u] end
          else
            mainStart[#mainStart+1] = currentBuffer.start
          end
        end

        if next(mainExit) == nil or tl.config.handleKeyConflicts == "replaceDuplicates" then
          mainExit = currentBuffer.exit
        elseif tl.config.handleKeyConflicts == "prepend" then
          if not tl.isContainer(mainExit) then mainExit = {mainExit} end
          if #mainExit == 0 and not tl.props(mainExit) then mainExit = {} end
            if tl.isContainer(currentBuffer.exit,1) then
              for u = 1 , #currentBuffer.exit do table.insert(mainExit, 1, currentBuffer.exit[u])end
            else
              table.insert(mainExit, 1, currentBuffer.exit)
            end
        elseif tl.config.handleKeyConflicts == "append" then
          if not tl.isContainer(mainExit) then mainExit = {mainExit} end
          if tl.isContainer(currentBuffer.exit,1) then
            for u = 1 , #currentBuffer.exit do mainExit[#mainExit+1] = currentBuffer.exit[u] end
          else
            mainExit[#mainExit+1] = currentBuffer.exit
          end
        end

        for k,v in pairs(currentBuffer.key) do
          if not tl.find(tl.internalProps,k) then
            if mainKeys[k] == nil or tl.config.handleKeyConflicts == "replaceDuplicates" then
              mainKeys[k] = v
            elseif tl.config.handleKeyConflicts == "prepend" then
              if not tl.isContainer(mainKeys[k],1) then mainKeys[k] = {mainKeys[k]} end
                if tl.isContainer(v,1) then
                  for u = 1 , #v do table.insert(mainKeys[k], 1, v[u])end
                else
                  table.insert(mainKeys[k], 1, v)
                end
            elseif tl.config.handleKeyConflicts == "append" then
              if not tl.isContainer(mainKeys[k],1) then mainKeys[k] = {mainKeys[k]} end
              if tl.isContainer(v,1) then
                for u = 1 , #v do mainKeys[k][#mainKeys[k]+1] = v[u] end
              else
                mainKeys[k][#mainKeys[k]+1] = v
              end
            end
          end
        end
      end
    end
    tl.assign.start = mainStart
    tl.assign.exit = mainExit
    tl.assign.documentation = mainDocs
    tl.assign.key = mainKeys

  end
  _getMacros(tl.assign)
  _scopeDocs()
  _elimiNames()
  _flattenCollections()
  for i=1,#tl.macroStats do
  ---@type MacroStatContainer
  tl.macroStats[i] = nil
  end
  if #tl.profileBuffer > 1 then
    tl.locationIndicator = tl.locationIndicator.."\nExtending: "
    for i=2,#tl.profileBuffer do
      local s1,s2 = "",", "
      if i == #tl.profileBuffer then
        s2 = ""
        if i ~=2 then
        s1= " and "
        end
      end
      tl.locationIndicator = tl.locationIndicator..s1..tl.profileBuffer[i]._fileOrigin..s2
    end
  end
  tl.profileBuffer = nil
end

---Computes the path to external profile files.
local function _getPath()
  local pathTable = {tl.config.extPaths[tl.config.fileLocation],gsub(tl.fileName or tl.config.profileName,"%.lua$","")..".lua"}
  if tl.config.childPaths then insert(pathTable,1,tl.config.path) end
  local finalPath = concat(pathTable,"/")
  if tl.config.fileLocation ~= 0 then
    tl.locationIndicator="Running on external configs ["..finalPath.."]"
    return finalPath
  elseif tl.config.fileLocation ~= 0 then
    tl.locationIndicator="Running on internal configs, external file missing or broken. ["..finalPath.."]"
  end
  return nil
end

function tl.buildBindings()
  _defineDevices()
  local path = _getPath()
  local profileName = path or tl.config.profileName
  _loadIntoBuffer(profileName,path,1)
  _mergeBuffers()
end