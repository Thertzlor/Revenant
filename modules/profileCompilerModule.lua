local tl = ...
local  sub, gsub, type, insert, concat, pairs, next, loadfile =
 string.sub, string.gsub,type, table.insert, table.concat,pairs, next, loadfile

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
    tab[k],tab[v] = tab[v],tab[k]
  end
end

function tl.extend(parentName)
  if parentName == "" or  type(parentName) ~= "string" then return end
  for i = 1, #tl.profileBuffer do local ex=tl.profileBuffer[i]._fileOrigin
    if ex == parentName then tl.findEx = tl.findEx.."\n\nWARNING:Prevented circular or duplicate inheritance from'"..parentName.."'!\n" return end
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
    local optionStorage = {}
    local mainLib = tl.assign.library
    local mainDocs = tl.assign.documentation

    for i=1,#tl.profileBuffer do local currentBuffer = tl.profileBuffer[i]

      if tl.handleOptionConflicts == "overwriteAll" or (tl.handleOptionConflicts == "discardAll" and next(optionStorage) == nil) or tl.handleOptionConflicts == i then
        optionStorage = currentBuffer._configurator
      elseif type(tl.handleOptionConflicts) == "string" and tl.handleOptionConflicts ~= "discardAll" then
        for k,v in pairs(currentBuffer.documentation) do
          if optionStorage[k] == nil or tl.handleOptionConflicts == "replaceDuplicates" then optionStorage[k] = v end
        end
      end

      if tl.handleDocumentationConflicts == "useLast" or (tl.handleDocumentationConflicts == "useFirst" and next(mainDocs) == nil) or tl.handleDocumentationConflicts == i then
        tl.assign.documentation = currentBuffer.documentation
      elseif type(tl.handleDocumentationConflicts) == "string" and tl.handleDocumentationConflicts ~= "discardAll" then
        for k,v in pairs(currentBuffer.documentation) do
          if mainDocs[k] == nil or tl.handleDocumentationConflicts == "replaceDuplicates" then mainDocs[k] = v end
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

    end
    for k,v in pairs(optionStorage) do
        tl[k] = v
    end
  end

  for i=1,#tl.macroStats do
  tl.macroStats[i] = nil
  end
  tl.profileBuffer = nil
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
  for k,v in pairs(tl.defaultOptions) do
     tl[k] = v
  end
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
   -- tl[fam.."ButtonCount"] = nil
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