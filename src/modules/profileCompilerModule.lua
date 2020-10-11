local tl,Base = ...---@type MainLibObject
local sub, gsub, type, insert, concat, pairs, next, loadfile, match, remove, ClearLog, xpcall =
  string.sub,string.gsub,type,table.insert,table.concat,pairs,next,loadfile,string.match,table.remove,ClearLog,xpcall

---@type ProfileDefinition
local ProfileDefinition = tl:classImport("ProfileDefinition")
--=============================================================
---@class ProfileCompilerModule
---: Functions that compile profiles and key bindings 
local ProfileCompilerModule = Base:new()
ProfileCompilerModule.loadedConfigs = {}
ProfileCompilerModule.profileBuffer = {}
ProfileCompilerModule.oldConfig = {}
ProfileCompilerModule.maxMode = 0
ProfileCompilerModule.sKey = 0
ProfileCompilerModule.maxKeys = 0
ProfileCompilerModule.profile = tl.paths.profile
local function _handleImportErrors(_)end
local function _handleBufferImports(path, mainContainer, keyContainer, lib)
  xpcall(function() loadfile(path)(mainContainer, keyContainer,lib) end,function() _handleImportErrors(path) end)
end
local function _handleObjectImports(path)
  local s, o = xpcall( function() return loadfile(path)() end, function() _handleImportErrors(path) end)
  return (s and o) or {}
end

local function _pruneUnused(tab)
  for k, v in pairs(tab) do
    if type(v) == "table" then
      _pruneUnused(tab[k])
      if next(tab[k]) == nil then tab[k] = nil end
    end
  end
end

---Eliminate names from tables and count them.
local function _elimiNames(collection)
  for i = 0, #collection.macroIndex do
    local  stats = (i == 0 and collection.macroIndex) or collection.macroIndex[i]
    for k, _ in pairs(stats) do
      --/ / //BUG: Where the FUCK do the _dummy and meta properties come from here?
      if k ~= "_dummy" and k ~= "_meta" and not stats[k]._dummy and stats[k].name then
        stats[k].name = nil
        tl.scriptStates.namedTables = tl.scriptStates.namedTables + 1
      end
    end
  end
end

---Pass parent properties to child tables
---@param taba GenericMacro
---@param origTable GenericMacro
---@param globalis table
local function _inherit(taba, origTable, globalis, bufferCollection)
  for k, d in pairs(taba) do
    local rideray = globalis == 1 and origTable.scopeDefaults or {}
    local gloverbal = globalis == 1 and origTable.scopeOverride or {}

    if type(k) == "string" and tl.activeProfile.unRename[k] ~= nil then
      if type(d) == "table" and tl.tbl:hasProperties(d) == false then
        local m = 1
        while d[m] ~= nil do
          local v = d[m]
          if type(v) == "string" and tl.tbl:hasProperties(tl.tbl:intersect(rideray, gloverbal, 1)) then
            v = {v}
          end
          if type(v) == "table" then
            if #v == 0 then --Arrays without any non-string keys are local override arrays.
              rideray = tl.tbl:intersect(rideray, v, 1) -- properties are added to the override array
              remove(d, m)
              m = m - 1
            elseif tl.tbl:hasProperties(tl.tbl:intersect(rideray, gloverbal, 1)) then
              taba[k][m] = tl.tbl:intersect(tl.tbl:intersect(v, rideray), gloverbal, 1)
            end
          end
          m = m + 1
        end
      elseif type(d) == "table" and tl.tbl:hasProperties(tl.tbl:intersect(rideray, gloverbal, 1)) then
        taba[k] = tl.tbl:intersect(tl.tbl:intersect(d, rideray), gloverbal, 1)
      elseif type(d) == "string" and tl.tbl:hasProperties(tl.tbl:intersect(rideray, gloverbal, 1)) then
        d = {d}
        taba[k] = tl.tbl:intersect(tl.tbl:intersect(d, rideray), gloverbal, 1)
      elseif type(d) == "string" then taba[k] = {taba[k]} end
    end
  end
  if bufferCollection and globalis == 1 then
    bufferCollection.assign.scopeDefaults = nil
    bufferCollection.assign.scopeOverride = nil
  end
end

---resolves the names of tables into table IDs based on their profile's scope
---@param tar GenericMacro|ProfileDefinition
---@param scope number
---@param startType string
local function _scopeNames(tar, parent, scope, startType)
  ---The subfunction for resolving individual IDs
  ---@param name string
  local function getID(name)
    local ancestorKey, libraryKey
    if name == nil or (parent.config.globalScopeKeys and tl.activeProfile.unRename(name)) then
      return name
    end
    for i = scope, #parent.macroIndex do
      local stat = parent.macroIndex[i]
      for k, _ in pairs(stat) do
        if not stat[k]._dummy and stat[k].name == name then
          stat[k].referenced = true
          ancestorKey = k
          break
        end
      end
    end
    for k, _ in pairs(parent.macroIndex) do
      if not parent.macroIndex[k]._dummy and parent.macroIndex[k].name == name then
        parent.macroIndex[k]._meta.referenced = true
        libraryKey = k
      end
    end
    return (parent.config.preferLibraryMacros and libraryKey) or ancestorKey or libraryKey or name
  end

  local currentType = tar.type or startType
  if currentType == "l" then
    tar[1] = getID(tar[1])
  elseif currentType == "s" or currentType == "c" or currentType == "h" then
    for i = 1, #tar do
      local obj = tar[i]
      if type(obj) == "table" and #obj == 1 and tl.tbl:hasProperties(obj) == false and type(obj[1]) == "string" then
        obj[1] = getID(obj[1])
      end
    end
  elseif currentType == "sc" or currentType == "cc" or currentType == "hc" then
    if tar[1] and type(tar[1]) == "string" then tar[1] = getID(tar[1]) end
  end

  local function scopeTests(tesTable)
    for k, v in ipairs(tesTable) do
      if type(v) == "table" then
        scopeTests(tesTable[k])
      elseif type(v) == "string" and match(v, "^[:~]") then
        tesTable[k] = sub(v, 1, 1) .. getID(sub(v, 2))
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
    if type(cTest) == "string" and match(cTest, "^[:~]") then
      tar.test = sub(cTest, 1, 1) .. getID(sub(cTest, 2))
    elseif type(cTest) == "table" then
      scopeTests(tar.test)
    end
  end

  if tar.update and type(tar.update) == "table" then
    if tl.tbl:isSingleTypeTable(tar.update, "table") == false then
      scopeUpdates(tar.update)
    else
      for i = 1, #tar.update do scopeUpdates(tar.update[i]) end
    end
  end

  for _, n in pairs(tar) do
    if type(n) == "table" then _scopeNames(n, parent, scope, tar.cast) end
  end
end

---Prepare Device profiles using user defined names for keys
---@private
function ProfileCompilerModule:_defineDevices(bufferCollection)
  bufferCollection.deviceState = {}
  local moreModes = 0
  local moreKeys = 0
  for k, v in pairs(bufferCollection.config.rename) do tl.activeProfile.unRename[v] = k end
  for g = 1, #tl.stringPresets.families do
    local fam = tl.stringPresets.families[g]
    local shorty = tl.str:token(fam)
    bufferCollection.deviceState[shorty] = {
      conKey = 0,
      shift = 0,
      modus = 1,
      mBeforeG = 1,
      dir = "down",
      lastModN = 0,
      lastMod = 0,
      buttonCount = bufferCollection.config[fam .. "ButtonCount"],
      sKey = bufferCollection.config[fam .. "ShiftKey"],
      modeCount = bufferCollection.config[fam .. "ModeCount"],
      modeConfig = bufferCollection.config[fam .. "ModeConfig"],
      bindHardwareModes = bufferCollection.config[fam .. "BindHardwareModes"],
      stable = {},
      unstable = {},
      token = shorty
    }
    if bufferCollection.config.defaultModeTarget == "join" then bufferCollection.deviceState[shorty].modeConfig = bufferCollection.config.genericModes end
    if bufferCollection.deviceState[shorty].modeCount > moreModes then moreModes = bufferCollection.deviceState[shorty].modeCount end
    if bufferCollection.deviceState[shorty].buttonCount > moreKeys then moreKeys = bufferCollection.deviceState[shorty].buttonCount end
    if bufferCollection.deviceState[shorty].sKey > self.sKey then self.sKey = 1 end
    for m = 1, bufferCollection.deviceState[shorty].buttonCount do
      tl.activeProfile.unRename[shorty .. m] = tl.activeProfile.unRename[shorty .. m] or shorty .. m
    end
    for h = 1, #bufferCollection.deviceState[shorty].modeConfig do
      if type(bufferCollection.deviceState[shorty].modeConfig[h]) ~= "table" then
        bufferCollection.deviceState[shorty].modeConfig[h] = {bufferCollection.deviceState[shorty].modeConfig[h]}
      end
    end
  end
  if self.maxMode < moreModes then self.maxMode = moreModes end
  for i = 1, self.maxMode do
    bufferCollection.config.genericModes[i] = bufferCollection.config.genericModes[i] or {i}
    if type(bufferCollection.config.genericModes[i]) ~= "table" then
      bufferCollection.config.genericModes[i] = {bufferCollection.config.genericModes[i]}
    end
  end
  if self.maxKeys < moreKeys then self.maxKeys = moreKeys end
end

---The function for checking if a path is actually valid
---@param path string
local function _checkValidString(path) 
  return (type(path) == "string" and #path ~= 0)
end

---Get the documentation from profile or external file.
local function _fetchDocs(collection)
  local fPath = _checkValidString(tl.paths.defaultDocPath.path) and tl.paths.defaultDocPath.path or ""
  local fName =
    _checkValidString(tl.paths.defaultDocPath.name) and gsub(tl.paths.defaultDocPath.name, "%.lua$", "") .. ".lua" or
    gsub(tl.paths.profileName, "%.lua$", "") .. tl.paths.defaultDocPath.suffix .. ".lua"
  return _handleObjectImports(concat({tl.paths.path, tl.paths.extPaths[tl.paths.fileLocation] or "", fPath, fName},"/"))
end
---@private
function ProfileCompilerModule:_fetchConfigs(metaconfig, name, collection)
  local fPath = _checkValidString(metaconfig.path) and metaconfig.path or ""
  local fName =_checkValidString(metaconfig.name) and gsub(metaconfig.name, "%.lua$", "") .. ".lua" or gsub(tl.paths.profileName, "%.lua$", "") .. metaconfig.suffix .. ".lua"
  local finalPath = concat({tl.paths.path, tl.paths.extPaths[tl.paths.fileLocation] or "", fPath, fName},"/")
  if not tl.tbl:find(self.loadedConfigs[name], finalPath) then
    if not self.loadedConfigs[name] then self.loadedConfigs[name] = {} end
    self.loadedConfigs[name][#self.loadedConfigs + 1] = finalPath
    return _handleObjectImports(finalPath)
  end
  return {}
end

---Prepare the key assignments array
---@private
---@param prepTable ProfileDefinition
function ProfileCompilerModule:_prepKeys(prepTable, parent)
  prepTable.library = {}
  prepTable.start = {}
  prepTable.exit = {}
  prepTable.scopeDefaults = {}
  prepTable.scopeOverride = {}
  prepTable.key = {}
  prepTable.documentation = _fetchDocs(parent)
  local function fillShiftAndModes(obj)
    if self.sKey ~= 0 then
      for p = 0, 2 do
        obj["s" .. p] = {}
        for i = 0, self.maxMode do obj["s" .. p]["mode" .. i] = {} end
      end
    end
  end
  local function fillModesAndShift(obj)
    for i = 0, self.maxMode do
      obj["mode" .. i] = {}
      if self.sKey ~= 0 then
        for p = 0, 2 do obj["mode" .. i]["s" .. p] = {} end
      end
    end
  end
  local function fillButtons(par)
    for g = 1, #tl.stringPresets.families do
      local targetState = parent.deviceState[tl.str:token(tl.stringPresets.families[g])]
      for m = 1, targetState.buttonCount do
        local bName = parent.config.rename[targetState.token .. m] or (targetState.token) .. m
        par[bName] = {}
        fillModesAndShift(par[bName])
        fillShiftAndModes(par[bName])
      end
    end
  end
  fillButtons(prepTable.key)
  fillModesAndShift(prepTable)
  fillModesAndShift(prepTable)
  fillShiftAndModes(prepTable.key)
  fillShiftAndModes(prepTable.key)
  return prepTable
end

---Set the default mouse buttons 3-5.
---@param ktab table
local function _setDefaults(ktab)
  for k, v in pairs(tl.config.defaultKeys) do ktab[k] = ktab[k] or v end
end

---Apply T-Lib options, cascade through option inheritance.
---@private
---@param configurator OptionsCollection
---@param init boolean
function ProfileCompilerModule:_config(configurator, init, name, bufferCollection, finalRun)
  local nextTable
  for i = 1, #bufferCollection do
    local pro = bufferCollection[i]
    if pro._processed == false then
      nextTable = pro
      break
    end
  end
  if not configurator and bufferCollection.config.enableConfigLinting then
    tl.lint:configLinter(bufferCollection.config, bufferCollection.config.profileName)
  end
  if (init or type(configurator) == "table" and next(configurator)) and not finalRun then
    self:_config(self:_fetchConfigs(bufferCollection.config.defaultConfigPath, name, bufferCollection), nil, name, bufferCollection)
  end
  if type(configurator) == "table" and next(configurator) then
    bufferCollection.config.defaultConfigPath = configurator.defaultConfigPath or bufferCollection.config.defaultConfigPath
    configurator.defaultConfigPath = nil
    bufferCollection.config.defaultConfigPath = nil
    bufferCollection.config.lockFlexCompilationSettings =
      configurator.lockFlexCompilationSettings or bufferCollection.config.lockFlexCompilationSettings
    if configurator.defaultModeTarget == "self" then configurator.defaultModeTarget = nil end
    if bufferCollection.config.enableConfigLinting and (not configurator._linted) then
      tl.lint:configLinter(configurator, configurator.profileName or nextTable and nextTable._fileOrigin or "unknown config")
    end

    for k, _ in pairs(configurator) do
      self.oldConfig[k] = bufferCollection.config[k]
      bufferCollection.config[k] = configurator[k] or bufferCollection.config[k]
    end
    if not bufferCollection.config.lockFlexCompilationSettings then
      for i = 1, #tl.stringPresets.flexConfigNames do
        local obj = tl.stringPresets.flexConfigNames[i]
        bufferCollection.config[obj] = self.oldConfig[obj]
      end
    end
  end
  if (configurator and next(configurator) and nextTable) or init then
    if nextTable then nextTable._configurator = configurator end
    if init or configurator.resolutions then tl.mouseMonitorUtils:compileScreenCoordinates(nil, bufferCollection) end
    self:_defineDevices(bufferCollection)
  end
end

---Main function for parsing the flexible syntax
---@private
---@param startable ProfileDefinition
function ProfileCompilerModule:_compileAssignments(startable, bufferCollection)
  local collector = startable.key

  local function extractFromTable(state, presets, subType) --Extract button functionality and put it into the main table
    _inherit(state, startable, nil, bufferCollection)
    local stackM = tl.config[subType .. "Stack"]
    local mergedResult = {}
    local tablePresets = tl.tbl:intersect({}, presets)
    local presetType = tablePresets.type
    local singleTypeSetting = tablePresets.singleType or tl.config.singleType

    for k, v in pairs(state) do
      if type(k) == "string" and tl.activeProfile.unRename[k] ~= nil then
        if type(v) ~= "table" then
          v = {v}
          v = tl.tbl:intersect(v, tablePresets, 2)
        elseif tl.tbl:hasProperties(v) or (presetType ~= nil and singleTypeSetting == 1) then
          v = tl.tbl:intersect(v, tablePresets, 2)
        else
          for u = 1, #v do
            if type(v[u]) ~= "table" then v[u] = {v[u]} end
            v[u] = tl.tbl:intersect(v[u], tablePresets, 2)
          end
        end
        if collector[k] == nil then
          collector[k] = v
        else
          if type(collector[k]) ~= "table" or tl.tbl:hasProperties(collector[k]) == true or tl.tbl:noType(collector[k], "table") then
            collector[k] = {collector[k]}
          end
          if not collector[k].name then
            collector[k].name = k
          end
          if type(v) ~= "table" or tl.tbl:hasProperties(v) then
            if stackM == "prepend" then insert(collector[k], 1, v)
            else collector[k][#collector[k] + 1] = v end
          else
            for u = 1, #v do
              local h = u
              if stackM == "prepend" then
                if tl.config.stackAutoReverse then h = #v - u + 1 end
                insert(collector[k], 1, v[h])
              else collector[k][#collector[k] + 1] = v[h] end
            end
          end
        end
        state[k] = nil
      elseif type(state[k]) == "table" and k ~= "key" then
        mergedResult[k] = v
        state[k] = nil
      end
    end
    return {mergedResult, tablePresets}
  end

  local function resolveHierachy(t, previousTableState) --recursively retrieve key definitions from array
    local nextWave = {}
    _inherit(t, startable, nil, bufferCollection)
    previousTableState = previousTableState or {}
    local newTableState = tl.tbl:intersect({}, previousTableState)
    local function setMode()
      local returnValue = {}
      for k = 0, self.maxMode do
        local j = k
        if tl.config.modeSort == "reverse" then
          j = self.maxMode - k
        elseif type(tl.config.modeSort) == "table" and #tl.config.modeSort == self.maxMode + 1 then
          j = tl.config.modeSort[k + 1]
        end
        if t["mode" .. j] ~= nil then
          local modeTable = t["mode" .. j]
          newTableState.mode = j
          returnValue[#returnValue + 1] = extractFromTable(modeTable, newTableState, "mode")
          t["mode" .. j] = nil
        end
        newTableState.mode = previousTableState.mode
      end
      return returnValue
    end

    local function setShift()
      local returnValue = {}
      if self.sKey ~= 0 then
        for h = 0, 2 do
          local j = h
          if tl.config.shiftSort == "reverse" then
            j = self.maxMode - h
          elseif type(tl.config.shiftSort) == "table" and #tl.config.shiftSort == 3 then
            j = tl.config.shiftSort[h + 1]
          end
          if t["s" .. j] ~= nil then
            local shiftTable = t["s" .. j]
            newTableState.gshift = j
            returnValue[#returnValue + 1] = extractFromTable(shiftTable, newTableState, "shift")
            t["s" .. j] = nil
          end
          newTableState.gshift = previousTableState.gshift
        end
      end
      return returnValue
    end

    local function setCustom()
      local returnValue = {}
      for r = 1, #tl.config.customSort do
        local customGroupName = tl.config.customSort[r]
        local customGroupTableState = {}
        if t[customGroupName] and t[customGroupName] == "table" then
          for d, m in pairs(t[customGroupName]) do
            if type(d) == "string" and tl.activeProfile.unRename[d] == nil then customGroupTableState[d] = m end
          end
          returnValue[#returnValue + 1] = extractFromTable(t[customGroupName], tl.tbl:intersect(previousTableState, customGroupTableState, 1), "custom")
          t[customGroupName] = nil
        end
      end
      for h, p in pairs(t) do
        local privs = {}
        if sub(h, 1, 2) == "_c" and type(p) == "table" then
          for d, m in pairs(p) do
            if type(d) == "string" and tl.activeProfile.unRename[d] == nil then
              privs[d] = m
            end
          end
          returnValue[#returnValue + 1] = extractFromTable(p, tl.tbl:intersect(previousTableState, privs, 1), "custom")
          t[h] = nil
        end
      end
      return returnValue
    end

    local orderTable = {custom = setCustom, mode = setMode, shift = setShift}
    for g = 1, #tl.config.stackOrder do
      local l = g
      if
        tl.config.stackAutoReverse and tl.config.modeStack == "prepend" and tl.config.shiftStack == "prepend" and
          tl.config.customStack == "prepend"
       then
        l = #tl.config.stackOrder - g + 1
      end
      nextWave[#nextWave + 1] = orderTable[tl.config.stackOrder[l]]()
    end
    if tl.tbl:hasContent(nextWave) then
      for u = 1, #nextWave do
        local wave = nextWave[u]
        for o = 1, #wave do
          local x = wave[o]
          resolveHierachy(x[1], x[2])
        end
      end
    end
  end
  resolveHierachy(startable)
  resolveHierachy(startable.key)
  startable = collector
end

---Dissolve MacroCollections that do not have names
---@param bufferCollection ProfileDefinition
local function _flattenCollections(bufferCollection)
  local possibleConts = {"key", "start", "exit", "library"}
  local keyTable = bufferCollection.assign
  local function dissolve(t)
    if tl.tbl:isContainer(t) then
      for i = 1, #t do
        if tl.tbl:isContainer(t[i]) and bufferCollection.macroIndex[t[i].pID]._meta.referenced == nil then
          local tablu = t[i]
          table.remove(t, i)
          for a = 1, #tablu do table.insert(t, i, dissolve(tablu[#tablu - a + 1])) end
        end
      end
      if not bufferCollection.macroIndex[t.pID]._dummy then
        bufferCollection.macroIndex[t.pID] = t
      end
    end
    return t
  end
  for a = 1, #possibleConts do
    local prop = possibleConts[a]
    for k, _ in pairs(keyTable[prop]) do keyTable[prop][k] = dissolve(keyTable[prop][k]) end
  end
end

---Creates a reference table for renamed keys
---@param tab table
local function _unRenameKeys(tab)
  for k, v in pairs(tl.config.rename) do tab[k], tab[v] = tab[v], tab[k] end
end

---Convert Macro names in the documentation to unique ids.
local function _scopeDocs(collection)
  for _, v in pairs(tl.macroIndex) do
    local mac = v.macro
    if mac and mac.name and collection.assign.documentation[mac.name] then
      collection.assign[mac.pID] = collection.assign.documentation[mac.name]
      collection.assign.documentation[mac.name] = nil
    end
  end
end
---Load a profile from an external file into its own buffer.
---@private
---@param name string
---@param path string
---@param init boolean
function ProfileCompilerModule:_loadIntoBuffer(bufferCollection, name, path, init)
  ---Imports linked Profile files
  ---@param parentName string
  local function _extend(parentName, subBuffer)
    local duplicate
    if parentName == "" or type(parentName) ~= "string" then return end
    for i = 1, #subBuffer do
      local ex = subBuffer[i]._fileOrigin
      if ex == parentName then
        tl.scriptStates.locationIndicator =
          tl.scriptStates.locationIndicator ..
          "\n\nWARNING:Prevented circular or duplicate inheritance from'" .. parentName .. "'!\n"
        duplicate = i
      end
    end
    if #subBuffer > subBuffer.config.maxInheritanceDepth then
      tl.scriptStates.locationIndicator =
        tl.scriptStates.locationIndicator ..
        "\n\nInheritance process stopped, due to number of profiles exceeding the maximum amount of " ..
          subBuffer.config.maxInheritanceDepth .. ".\n"
      return
    end
    local exTable = {
      subBuffer.config.extPaths[subBuffer.config.fileLocation] or "",
      gsub(parentName, "%.lua$", "") .. ".lua"
    }
    if subBuffer.config.childPaths then insert(exTable, 1, subBuffer.config.path) end
    local finalExPath = concat(exTable, "/")

    if duplicate then subBuffer[#subBuffer + 1] = subBuffer[duplicate]
    else self:_loadIntoBuffer(subBuffer, parentName, finalExPath) end
  end

  local function _extendHook(parent)
    if type(parent) ~= "table" then parent = {parent} end
    local extendTarget = bufferCollection
    if #parent > 1 then
      bufferCollection[#bufferCollection + 1] = {
        config = bufferCollection.config,
        macroIndex = bufferCollection.macroIndex,
        state = bufferCollection.deviceState
      }
      extendTarget = bufferCollection[#bufferCollection]
    end
    for i = 1, #parent do _extend(parent[i],extendTarget) end
  end
---@private
  local function _configHook(options)
    local origName = name
    local cPath = type(options) == "string" and options or #options == 1 and type(options[1]) == "string" and options[1]
    self:_config(cPath and _handleObjectImports(cPath) or options, nil, origName, bufferCollection)
  end

  bufferCollection[#bufferCollection + 1] = {
    _fileOrigin = name,
    ---@type AssignmentTable
    assign = {
    extend = _extendHook,
    configure = _configHook},
    _processed = false,

  }
  local bufferContainer = bufferCollection[#bufferCollection]
  local bufferNum = #bufferCollection
  bufferContainer._scope = bufferNum
  if init then self:_config(nil, init, name, bufferCollection) end
  self:_prepKeys(bufferContainer.assign, bufferCollection)
  if path then _handleBufferImports(path, bufferContainer.assign, bufferContainer.assign.key, tl) end
  if init then
    _extendHook(bufferCollection.config.extends)
   -- self.profile(bufferContainer, bufferContainer.assign.key, tl)
  end
  _pruneUnused(bufferContainer.assign.key)
  self:_compileAssignments(bufferContainer.assign, bufferCollection)
  _setDefaults(bufferContainer.assign.key)
  _inherit(bufferContainer.assign.key, bufferContainer, 1, bufferCollection)
  if init or not bufferCollection.config.keepCustomNames then
    _unRenameKeys(bufferContainer.assign.key)
  end
  tl.tbl:indexTables(bufferCollection, bufferContainer, bufferNum)
  bufferContainer.assign.extend = nil
  bufferContainer.assign.configure = nil
  bufferContainer._processed = true
end

---Loads the Macro definitions from separate profiles into the main active profile
---@param tar ProfileDefinition
local function _getMacros(tar, collection)
  local scope = collection.macroIndex[tar._scope or 1]
  if tar.pID and collection.macroIndex[tar.pID]._dummy then
    collection.macroIndex[tar.pID] = scope[tar.pID]
    scope[tar.pID] = nil
    tar._scope = nil
  end
  for _, n in pairs(tar) do
    if type(n) == "table" then _getMacros(n, collection) end
  end
end
---@private
function ProfileCompilerModule:_mergeBuffers(bufferCollection, parent)
  
  if #bufferCollection == 1 then
    bufferCollection.assign = bufferCollection[1].assign
    _scopeNames(bufferCollection.assign, bufferCollection, 1)
  else
    local optionStorage = {}
    local mainLib = {}
    local mainDocs = {}
    local mainKeys = {}
    local mainStart = {}
    local mainExit = {}
    for i = #bufferCollection, 1, -1 do
      if #bufferCollection[i] >= 1 then
        bufferCollection[i] = self:_mergeBuffers(bufferCollection[i], bufferCollection)
      end
    end
    for i = #bufferCollection, 1, -1 do
      local currentBuffer = bufferCollection[i]
      if
        bufferCollection.config.handleOptionConflicts == "useLast" or
          (bufferCollection.config.handleOptionConflicts == "useFirst" and next(optionStorage) == nil) or
          bufferCollection.config.handleOptionConflicts == i
       then
        optionStorage = currentBuffer._configurator
      elseif
        type(bufferCollection.config.handleOptionConflicts) == "string" and
          bufferCollection.config.handleOptionConflicts ~= "useFirst"
       then
        for k, v in pairs(currentBuffer.assign.documentation) do
          if optionStorage[k] == nil or bufferCollection.config.handleOptionConflicts == "replaceDuplicates" then
            optionStorage[k] = v
          end
        end
      end
    end
    self:_config(optionStorage, nil, nil, bufferCollection, true)
    for i = #bufferCollection, 1, -1 do
      local currentBuffer = bufferCollection[i]
      if
        bufferCollection.config.handleDocumentationConflicts == "useLast" or
          (bufferCollection.config.handleDocumentationConflicts == "useFirst" and next(mainDocs) == nil) or
          bufferCollection.config.handleDocumentationConflicts == i
       then
        mainDocs = currentBuffer.assign.documentation
      elseif
        type(bufferCollection.config.handleDocumentationConflicts) == "string" and
          bufferCollection.config.handleDocumentationConflicts ~= "useFirst"
       then
        for k, v in pairs(currentBuffer.assign.documentation) do
          if mainDocs[k] == nil or bufferCollection.config.handleDocumentationConflicts == "replaceDuplicates" and not tl.tbl:find(tl.stringPresets.internalProps, k) then mainDocs[k] = v end
        end
      end

      if
        bufferCollection.config.handleLibraryConflicts == "useLast" or
          (bufferCollection.config.handleLibraryConflicts == "useFirst" and #mainLib == 0) or
          bufferCollection.config.handleLibraryConflicts == i
       then
        mainLib = currentBuffer.assign.library
      elseif
        type(bufferCollection.config.handleLibraryConflicts) == "string" and
          bufferCollection.config.handleLibraryConflicts ~= "useFirst"
       then
        for m = 1, #currentBuffer.assign.library do
          local libObject = currentBuffer.assign.library[m]
          if libObject.name then
            local duped = false
            for n = 1, #mainLib do
              local compareObject = mainLib[n]
              if compareObject.name == libObject.name then
                duped = true
                if bufferCollection.config.handleLibraryConflicts == "replaceDuplicates" then
                  mainLib[n] = libObject
                end
              end
            end
            if not duped then mainLib[#mainLib + 1] = libObject end
          end
        end
      end
    end
    bufferCollection.assign.library = mainLib
    _getMacros(bufferCollection.assign, bufferCollection)
    for i = #bufferCollection, 1, -1 do
      local currentBuffer = bufferCollection[i]
      _scopeNames(currentBuffer, bufferCollection, i)
      if
        bufferCollection.config.handleKeyConflicts == "useLast" or
          (bufferCollection.config.handleKeyConflicts == "useFirst" and next(mainKeys) == nil) or
          bufferCollection.config.handleKeyConflicts == i
       then
        mainKeys = currentBuffer.assign.key or {}
        mainStart = currentBuffer.assign.start or {}
        mainExit = currentBuffer.assign.exit or {}
      elseif
        type(bufferCollection.config.handleKeyConflicts) == "string" and
          bufferCollection.config.handleKeyConflicts ~= "useFirst"
       then
        if not tl.tbl:isContainer(mainExit) then mainExit = {mainExit} end
        if not tl.tbl:isContainer(mainStart) then mainStart = {mainStart} end

        if next(mainStart) == nil or bufferCollection.config.handleKeyConflicts == "replaceDuplicates" then
          mainStart = currentBuffer.assign.start
        elseif bufferCollection.config.handleKeyConflicts == "prepend" then
          if not tl.tbl:isContainer(mainStart) then mainStart = {mainStart} end
          if tl.tbl:isContainer(currentBuffer.assign.start, 1) then
            for u = 1, #currentBuffer.assign.start do table.insert(mainStart, 1, currentBuffer.assign.start[u]) end
          else table.insert(mainStart, 1, currentBuffer.start) end
        elseif bufferCollection.config.handleKeyConflicts == "append" then
          if not tl.tbl:isContainer(mainStart) then mainStart = {mainStart} end
          if tl.tbl:isContainer(currentBuffer.assign.start, 1) then
            for u = 1, #currentBuffer.assign.start do mainStart[#mainStart + 1] = currentBuffer.assign.start[u] end
          else mainStart[#mainStart + 1] = currentBuffer.start end
        end

        if next(mainExit) == nil or bufferCollection.config.handleKeyConflicts == "replaceDuplicates" then
          mainExit = currentBuffer.assign.exit
        elseif bufferCollection.config.handleKeyConflicts == "prepend" then
          if not tl.tbl:isContainer(mainExit) then mainExit = {mainExit} end
          if #mainExit == 0 and not tl.tbl:hasProperties(mainExit) then mainExit = {} end
          if tl.tbl:isContainer(currentBuffer.assign.exit, 1) then
            for u = 1, #currentBuffer.assign.exit do table.insert(mainExit, 1, currentBuffer.assign.exit[u]) end
          else table.insert(mainExit, 1, currentBuffer.assign.exit) end
        elseif bufferCollection.config.handleKeyConflicts == "append" then
          if not tl.tbl:isContainer(mainExit) then mainExit = {mainExit} end
          if tl.tbl:isContainer(currentBuffer.assign.exit, 1) then
            for u = 1, #currentBuffer.assign.exit do mainExit[#mainExit + 1] = currentBuffer.assign.exit[u] end
          else mainExit[#mainExit + 1] = currentBuffer.assign.exit end
        end

        for k, v in pairs(currentBuffer.assign.key) do
          if not tl.tbl:find(tl.stringPresets.internalProps, k) then
            if mainKeys[k] == nil or bufferCollection.config.handleKeyConflicts == "replaceDuplicates" then
              mainKeys[k] = v
            elseif bufferCollection.config.handleKeyConflicts == "prepend" then
              if not tl.tbl:isContainer(mainKeys[k], 1) then mainKeys[k] = {mainKeys[k]} end
              if tl.tbl:isContainer(v, 1) then
                for u = 1, #v do table.insert(mainKeys[k], 1, v[u]) end
              else table.insert(mainKeys[k], 1, v) end
            elseif bufferCollection.config.handleKeyConflicts == "append" then
              if not tl.tbl:isContainer(mainKeys[k], 1) then mainKeys[k] = {mainKeys[k]} end
              if tl.tbl:isContainer(v, 1) then
                for u = 1, #v do mainKeys[k][#mainKeys[k] + 1] = v[u] end
              else mainKeys[k][#mainKeys[k] + 1] = v end
            end
          end
        end
      end
    end

    bufferCollection.assign.start = mainStart
    bufferCollection.assign.exit = mainExit
    bufferCollection.assign.documentation = mainDocs
    bufferCollection.assign.key = mainKeys
    --return bufferCollection
  end
  
  _getMacros(bufferCollection.assign, bufferCollection)
  _scopeDocs(bufferCollection)
  _elimiNames(bufferCollection)

  _flattenCollections(bufferCollection)
  parent.assign = self.profileBuffer.assign
  parent.macroIndex = self.profileBuffer.macroIndex
  parent.config = self.profileBuffer.config
  parent.deviceState = self.profileBuffer.deviceState
  for i = 1, #bufferCollection.macroIndex do
    ---@type MacroStatContainer
    bufferCollection.macroIndex[i] = nil
  end
  if #bufferCollection > 1 then
    tl.scriptStates.locationIndicator = tl.scriptStates.locationIndicator .. "\nExtending: "
    for i = 2, #bufferCollection do
      local s1, s2 = "", ", "
      if i == #bufferCollection then
        s2 = ""
        if i ~= 2 then s1 = " and " end
      end
      tl.scriptStates.locationIndicator = tl.scriptStates.locationIndicator .. s1 .. bufferCollection[i]._fileOrigin .. s2
    end
  end
  --//TODO: containers from multiple profiles don't work yet.
  return bufferCollection
end

---Computes the path to external profile files.
local function _getPath()
  local pathTable = {
    tl.config.extPaths[tl.config.fileLocation] or "",
    gsub(tl.config.profileName, "%.lua$", "") .. ".lua"
  }
  if tl.config.childPaths then insert(pathTable, 1, tl.config.path) end
  local finalPath = concat(pathTable, "/")
  if tl.config.fileLocation ~= 0 then
    tl.scriptStates.locationIndicator = "Running on external configs [" .. finalPath .. "]"
    return finalPath
  elseif tl.config.fileLocation ~= 0 then
    tl.scriptStates.locationIndicator = "Running on internal configs, external file missing or broken. [" .. finalPath .. "]"
  end
  return nil
end

function ProfileCompilerModule:buildBindings()
  local path = _getPath()
  local profileName = path or tl.config.profileName
  tl.activeProfile = ProfileDefinition:new(path,profileName,nil,true)
  self.profileBuffer = {config = tl.config, assign = {}, macroIndex = tl.helperUtils.newIndexTable(), state = {}}
  self:_loadIntoBuffer(self.profileBuffer, profileName, path, 1)
  self.profileBuffer = self:_mergeBuffers(self.profileBuffer, tl)
end

return ProfileCompilerModule