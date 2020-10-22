local tl, Base = ...---@type MainLibObject
local rawset, type, setmetatable, pairs,next,insert, loadfile,xpcall,sub = rawset, type, setmetatable, pairs,next,insert,loadfile,xpcall,string.sub
local ConfigDefinition = tl:classImport("ConfigDefinition") ---@type ConfigDefinition
---@alias MacroTable table<string,GenericMacro>
---@alias MacroArray table<number,GenericMacro>
---@alias Assignment GenericMacro|MacroArray|MacroTable

local function log(what) tl:put(tl.helperUtils.pprint(what)) end

---@class ProfileDefinition:BaseClass
local ProfileDefinition = Base:new()
---@generic Source
---@param table Source
---@return Source
function ProfileDefinition:autoTable(table)
  table = table or {}
  local magicMeta = {
    __index = function(table, key)
      if not self.autoKeys then return nil elseif key == "_meta" then return true end
      local newInf = self:autoTable()
      rawset(table, key, newInf)
      return newInf 
    end,
    __newindex = function(table, key, value)
      if not self.autoKeys then return rawset(table, key, value) end
      if type(value) == "table" and not value._meta then value = self:recursiveTable(value) end
      rawset(table, key, value)
    end,
    __tostring = tl.helperUtils.pprint
  }
  setmetatable(table, magicMeta)
  return table
end

function ProfileDefinition:recursiveTable(table)
  for k, v in pairs(table) do
    if type(v) == "table" then table[k] = self:recursiveTable(v) end
  end
  return self:autoTable(table)
end

---Yaes
---@param path string
---@param init boolean
---@param stack string[]
function ProfileDefinition:constructor(path,name,stack,init)

  self.stack = stack or {}---@private
  self.path = path or "origin"
  self.init = false
  self.autoKeys = true---@private
  self.stable={}
  self.unstable={}
  self.awaiting = {}
  self.nameMap = {}---@type table<string,string>
  self.macroIndex = {}  ---@type table<string,BaseMacro>
  self.config = {}---@type OptionsCollection
  self.documentation={}
  self.toggledKeys={}---@private
  self.deviceState={}---@private
  self.unRename = {}---@private
  self.typedIndex= {} ---@type table<string,string[]>
  
  ---@class MacroAssignment
  ---@field key table<string,Assignment>
  ---@field documentation table<string,string>
  ---@field config OptionsCollection
  ---@field exit Assignment
  ---@field library Assignment
  ---@field scopeDefaults Assignment
  ---@field scopeOverride Assignment
  ---@field start Assignment
  local baseTable = {}
  self.logiSet = tl.paths.profile---@private
  self.assign = self:autoTable(baseTable)
  if path then self:profileImport() end
  if init then self.logiSet(self.assign) end
  self.autoKeys = false
  self.name = tl.paths.profileName or (self.assign.config and self.assign.config.profileName)
  self:fetchConfigs()
  self:fetchDocs()
  if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
  self.stack[#self.stack+1] = self.path
  for k, v in pairs(tl.config.defaultKeys) do self.assign[k] = self.assign[k] or v end
  self:applyConfig(init)
  self:parseBindings()
end

---@private
---Generic import function for config and documentatation files
---@param importType '"doc"'|'"config"'
---@return string path to the external file for documentation or configuration
function ProfileDefinition:getExtPath(importType)
  if tl.paths.fileLocation == 0 then return false end
  local vars =({doc={"externdalDocs","defaultDocPath"},config={"externdalConfigs","defaultConfigPath"}})[importType]
  local def = tl.paths[vars[2]]
  local path
  if(self.assign.config and self.assign.config[vars[1]])then path = self.assign.config[vars[1]]
  elseif def then 
    path =  tl.paths.extPaths[tl.paths.fileLocation].."/"..((def.path and def.path.."/") or "")..
    (def.prefix or "")..((def.name ~= nil and def.name ~= "" and def.name) or self.name or "")..(def.suffix or "")
  end
  return path
end

function ProfileDefinition:findMacros(group,id)
  if id then
    if type(id) ~= "table" then
      local mac = self.macroIndex[id] 
      return mac and {mac} or {}
    end
    local res = {}
    for i = 1, #id do local mac = self.macroIndex[id[i]] 
      if mac then res[#res+1]=mac end
    end
    return res
  end
  return self.typedIndex[group] or {}
end
---Fetches one or more external config files for the current profile
function ProfileDefinition:fetchConfigs()
  local path = self:getExtPath("config")
  if not path then return end
  self.config= ConfigDefinition:new((self.assign.config and {path,self.assign.config}) or path):output() or self.assign.config or self.config
end

---Fetches one or more external documentation file for the current profile
function ProfileDefinition:fetchDocs()
  local path = self:getExtPath("doc")
  if not path then return end
  self.documentation = tl:import(path,function()end) or self.documentation
end
function ProfileDefinition:fetchLibrary()end
function ProfileDefinition:mergeDocs(otherDoc)
  local resolveSettings = self.config.handleDocumentationConflicts == "replace"
  local function addDoc(path)  self.documentation = tl.tbl.intersectSimple(self.documentation,(tl:import(path,function()end) or {}),resolveSettings) end
  local docPath = self.config.externalDocs or self:getExtPath("doc");
  self:multiArg(addDoc,docPath)
  self.documentation = tl.tbl:intersectSimple((self.assign.documentation or {}),self.documentation,resolveSettings)
end

function ProfileDefinition:profileImport()
  local p = self.path:gsub("%.lua$",""):gsub("$",".lua")
  xpcall(function()return loadfile(p)(self.assign)end,function(err)tl:put("Error loading profile from "..p..".\nError Message: \""..err..'"')end)
end

---@private
function ProfileDefinition:compileAssignments()
  local collector =  self.assign.key or {}
  local function extractFromTable(currentTable, presets, subType) --Extract button functionality and put it into the main table
    local stackM = self.config[subType .. "Stack"]
    log(subType)
    local mergedResult = {}
    local tablePresets = tl.tbl:intersect({}, presets or {})
    local presetType = tablePresets.type
    local singleTypeSetting = tablePresets.singleType or self.config.singleType
    for key, value in pairs(currentTable) do
      if type(key) == "string" and self.unRename[key] ~= nil then
        if type(value) ~= "table" then value = {value} end
        local identValue = tl.tbl:identifyTableType(value)
        if collector[key] == nil then 
          value = tl.tbl:intersectSimple(value,tablePresets)
          collector[key] = value
        else
          if type(collector[key]) ~= "table" then collector[key] = {collector[key]} end
          if tl.tbl:hasProperties(collector[key]) then collector[key] = {collector[key]}end
          if identValue == "macro" or (identValue == "group" and tl.tbl:hasProperties(value)) then
            value = tl.tbl:intersectSimple(value,tablePresets)
            if stackM == "prepend" then insert(collector[key], 1, value)
            else collector[key][#collector[key] + 1] = value end
          elseif identValue ~= "empty" then -- Here we handle groups without properties
            for w = 1, #value do 
              if type(value[w]) ~="table" then value[w]={value[w]} end
              value[w] = tl.tbl:intersectSimple(value[w],tablePresets) end
            for u = 1, #value do local h = u
              if stackM == "prepend" then
                if self.config.stackAutoReverse then h = #value - u + 1 end
                insert(collector[key], 1, value[h])
              else collector[key][#collector[key] + 1] = value[h] end
            end
          end
        end
        currentTable[key] = nil
      elseif type(currentTable[key]) == "table" and key ~= "key"  then
        mergedResult[key] = value
        currentTable[key] = nil
      end
    end
    return {mergedResult, tablePresets}
  end

  local function resolveHierachy(currentTable, previousTableState) --recursively retrieve key definitions from array
    local nextWave = {}
    previousTableState = previousTableState or {}
    local newTableState = tl.tbl:intersect({}, previousTableState)

    local function setMode()
      local returnValue = {}
      for k = 0, self.deviceState.maxMode do local j = k
        if self.config.modeSort == "reverse" then
          j = self.deviceState.maxMode - k
        elseif type(self.config.modeSort) == "table" and #self.config.modeSort == self.deviceState.maxMode + 1 then
          j = self.config.modeSort[k + 1]
        end
        
        if currentTable["mode" .. j] ~= nil then
          local modeTable = currentTable["mode" .. j]
          newTableState.mode = j
          returnValue[#returnValue + 1] = extractFromTable(modeTable, newTableState, "mode")
          currentTable["mode" .. j] = nil
        end
        newTableState.mode = previousTableState.mode
      end
      return returnValue
    end

    local function setShift()
      local returnValue = {}
      if self.deviceState.sKey then
        for h = 0, 2 do local j = h
          if self.config.shiftSort == "reverse" then
            j = self.deviceState.maxMode - h
          elseif type(self.config.shiftSort) == "table" and #self.config.shiftSort == 3 then
            j = self.config.shiftSort[h + 1]
          end
          if currentTable["s" .. j] ~= nil then
            local shiftTable = currentTable["s" .. j]
            newTableState.gshift = j
            returnValue[#returnValue + 1] = extractFromTable(shiftTable, newTableState, "shift")
            currentTable["s" .. j] = nil
          end
          newTableState.gshift = previousTableState.gshift
        end
      end
      return returnValue
    end

    local function setCustom()
      local returnValue = {}
      for r = 1, #self.config.customSort do
        local customGroupName = self.config.customSort[r]
        local customGroupTableState = {}
        if currentTable[customGroupName] and currentTable[customGroupName] == "table" then
          for d, m in pairs(currentTable[customGroupName]) do
            if type(d) == "string" and not self.unRename[d] then customGroupTableState[d] = m end
          end
          returnValue[#returnValue + 1] = extractFromTable(currentTable[customGroupName], tl.tbl:intersect(previousTableState, customGroupTableState, 1), "custom")
          currentTable[customGroupName] = nil
        end
      end
      for h, p in pairs(currentTable) do
        local privs = {}
        if sub(h, 1, 2) == "_c" and type(p) == "table" then
          for d, m in pairs(p) do if type(d) == "string" and self.unRename[d] == nil then privs[d] = m end end
          returnValue[#returnValue + 1] = extractFromTable(p, tl.tbl:intersect(previousTableState, privs, 1), "custom")
          currentTable[h] = nil
        end
      end
      return returnValue
    end

    local orderTable = {custom = setCustom, mode = setMode, shift = setShift}
    for g = 1, #self.config.stackOrder do local l = g
      if self.config.stackAutoReverse and self.config.modeStack == "prepend" and self.config.shiftStack == "prepend" 
      and self.config.customStack == "prepend" then
        l = #self.config.stackOrder - g + 1
      end
      nextWave[#nextWave + 1] = orderTable[self.config.stackOrder[l]]()
    end

    if tl.tbl:hasContent(nextWave) then
      for u = 1, #nextWave do local wave = nextWave[u]
        for o = 1, #wave do local x = wave[o]
          resolveHierachy(x[1], x[2])
        end
      end
    end
  end
  resolveHierachy(self.assign.key)
  resolveHierachy(self.assign)
  for k, v in pairs(collector) do v.name = v.name  or k collector[k] = v end
  for k,v in pairs(self.unRename) do
    if k~=v then
      collector[v]=collector[k]
      collector[k]=nil
    end
  end
  self.assignFlattened = collector
end

function ProfileDefinition:parseBindings()
  self.bindings = {}
  local processed = 0
  local fullTotal=0
  local bindingStats = {}
  for key, bind in pairs(self.assignFlattened) do 
    bindingStats[key] = {total = #bind, res = {},keyProcessed=0}
    fullTotal = fullTotal + #bind
  end
  ---@param class BaseMacro
  local function getBinding(class,key)
    local classID = class:awaitOwnId()
    if classID then bindingStats[key].res[#bindingStats[key].res+1] = classID end
    processed = processed+1
    bindingStats[key].keyProcessed = bindingStats[key].keyProcessed +1 
    if bindingStats[key].keyProcessed == bindingStats[key].total and #bindingStats[key].res ~= 0 then
      self.bindings[key] = bindingStats[key].res 
    end
    if processed == fullTotal then 
      for k, v in pairs(self.macroIndex) do
        if v.type then local typeIndex = self.typedIndex[v.type]
          if typeIndex then typeIndex[#typeIndex+1] = k  else self.typedIndex[v.type] = {k} end
        end
      end
      self.init = true
    end
  end

  for key, bindingTable in pairs(self.assignFlattened) do
    local singleKeyCollection = {}
    for i = 1, #bindingTable do local binding = bindingTable[i]
      ---@type BaseMacro
      local bindingClass = tl.validator:getMacroClass(binding);
      if bindingClass then
        local bindingInstance = bindingClass:new(binding,self,self.assign.scopeDefaults,self.assign.scopeOverride)
        self:async(getBinding,bindingInstance,key)
      end
    end
  end
end

---Apply T-Lib options, cascade through option inheritance.
---@private
---@param configurator OptionsCollection
---@param init boolean
function ProfileDefinition:applyConfig(init)
  local configurator = self.config
  local nextTable
  if (configurator and next(configurator) and nextTable) or init then
    if nextTable then nextTable._configurator = configurator end
    if init or configurator.resolutions then self.resolutions = tl.mouseMonitorUtils:compileScreenCoordinates(configurator.resolutions, self) end
    self:defineDevices()
  end
  self:compileAssignments()
end

---@private
function ProfileDefinition:defineDevices()
  local moreModes = 0
  local moreKeys = 0
  local sKey = false
  for k, v in pairs(self.config.rename) do self.unRename[v] = k end
  for g = 1, #tl.stringPresets.families do
    local fam = tl.stringPresets.families[g]
    local shorty = tl.str:token(fam)
    self.deviceState[shorty] = {
      conKey = 0,
      shift = 0,
      modus = 1,
      mBeforeG = 1,
      dir = "down",
      lastModN = 0,
      lastMod = 0,
      buttonCount = self.config[fam .. "ButtonCount"],
      sKey = self.config[fam .. "ShiftKey"],
      modeCount = self.config[fam .. "ModeCount"],
      modeConfig = self.config[fam .. "ModeConfig"],
      bindHardwareModes = self.config[fam .. "BindHardwareModes"],
      stable = {},
      unstable = {},
      token = shorty
    }
    if self.deviceState[shorty].sKey then sKey = true end
    if self.config.defaultModeTarget == "join" then self.deviceState[shorty].modeConfig = self.config.genericModes end
    if self.deviceState[shorty].modeCount > moreModes then moreModes = self.deviceState[shorty].modeCount end
    if self.deviceState[shorty].buttonCount > moreKeys then moreKeys = self.deviceState[shorty].buttonCount end
    for m = 1, self.deviceState[shorty].buttonCount do
      self.unRename[shorty .. m] = self.unRename[shorty .. m] or shorty .. m
    end
    for h = 1, #self.deviceState[shorty].modeConfig do
      if type(self.deviceState[shorty].modeConfig[h]) ~= "table" then
        self.deviceState[shorty].modeConfig[h] = {self.deviceState[shorty].modeConfig[h]}
      end
    end
  end
  self.deviceState.maxMode = moreModes
  for i = 1, self.deviceState.maxMode do
    self.config.genericModes[i] = self.config.genericModes[i] or {i}
    if type(self.config.genericModes[i]) ~= "table" then
      self.config.genericModes[i] = {self.config.genericModes[i]}
    end
  end
  self.deviceState.maxKeys = moreKeys
  self.deviceState.sKey = sKey
end

return ProfileDefinition