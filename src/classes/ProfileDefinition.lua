local tl = ...---@type MainLibObject
local rawset, type, setmetatable, pairs,next,insert, loadfile,xpcall,sub,concat,gsub = rawset, type, setmetatable, pairs,next,insert,loadfile,xpcall,string.sub,table.concat,string.gsub
local ConfigDefinition = tl:classImport("ConfigDefinition") ---@type ConfigDefinition
---@alias MacroTable table<string,GenericMacro>
---@alias MacroArray table<number,GenericMacro>
---@alias Assignment GenericMacro|MacroArray|MacroTable

local function log(what) tl:put(tl.helperUtils.pprint(what)) end

---@class ProfileDefinition:BaseClass
local ProfileDefinition = tl.baseClass:new()

---Yaes
---@param path string
---@param init boolean
---@param stack string[]
function ProfileDefinition:constructor(path,name,stack,init)
  self.stack = stack or {}---@private
  self.path = path or "origin"
  self.subPath = gsub(self.path,"[^\\/]+$","")
  self.init = false
  self.libMacros = {}
  self.libInit = false
  self.autoKeys = true---@private
  self.awaiting = {}
  self.nameMap = {}---@type table<string,string>
  self.macroIndex = {}  ---@type table<string,MacroDefinition>
  self.config = {}---@type OptionsCollection
  self.documentation={}
  self.toggledKeys={}---@private
  self.deviceState={}
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
  self:fetchConfigs()
  self.name = tl.paths.profileName or (self.config.profileName)
  self:fetchDocs()
  if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
  self.stack[#self.stack+1] = self.path
  self:applyConfig()
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
  if(self.assign.config and self.assign.config[vars[1]])then path = ((tl.paths.childPaths and self.subPath) or "")..self.assign.config[vars[1]]
  elseif def then 
    path =  ((tl.paths.childPaths and self.subPath) or "")..tl.paths.extPaths[tl.paths.fileLocation]..((def.path and "/"..def.path.."/") or "")..
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
  xpcall(function()return loadfile(p)(self.assign)end,function(err)tl:put("Error loading profile from "..p..".\n  Error Message: \""..err..'"')end)
end

---@private
function ProfileDefinition:compileAssignments()
  local collector =  self.assign.key or {}

  local function extractFromTable(currentTable, presets, subType) --Extract button functionality and put it into the main table
    local stackM = self.config[subType .. "Stack"]
    local mergedResult = {}
    local tablePresets = tl.tbl:intersect({}, presets or {})
    for key, value in pairs(currentTable) do
      if type(key) == "string" and self.unRename[key] ~= nil then
        if type(value) ~= "table" then value = {value} end
        local identValue = self:identifyTableType(value)
        if collector[key] == nil then 
          if identValue == "macro" then value._inherit = tablePresets else value = tl.tbl:intersectSimple(value,tablePresets) end
          collector[key] = value
        else
          if type(collector[key]) ~= "table" then collector[key] = {collector[key]} end
          if tl.tbl:hasProperties(collector[key]) then collector[key] = {collector[key]}end
          if identValue == "macro" or (identValue == "group" and tl.tbl:hasProperties(value)) then
            if identValue == "macro" then value._inherit = tablePresets else value = tl.tbl:intersectSimple(value,tablePresets) end
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
  for k, v in pairs(collector) do 
    if type(v) ~= "table" then v = {v} end
    v.name = v.name  or k
    collector[k] = v
  end
  for k,v in pairs(self.unRename) do
    if k~=v then
      collector[v]=collector[k]
      collector[k]=nil
    end
  end
  self.assignFlattened = collector
end

---@return '"group"'|'"macro"'|'"empty"'
function ProfileDefinition:identifyTableType(tbl)
  local t = type(tbl)
  if t == "string" then return "macro"
  elseif t=="nil" then return "empty"
  elseif t ~= "table" then  error("Malformed Macro or Group") end
  local cm,op = tl.tbl:splitDefinition(tbl)
  if next(op) then
    if (op.type or op.t) then
      if op.type and op.t then tbl.type = (self.config.preferShorthand and op.t or op.type)
      else  tbl.type = op.type or op.t end
      tbl.t = nil
      return "macro" 
    elseif #cm == 0 then return "empty"
    elseif #cm == 1 and type(cm[1]) == "string" then return "macro"
    else return "group" end
  elseif #cm == 1 and type(cm[1]) == "string" then return "macro"
  elseif #cm ~= 0 then return "group"
  else return "empty" end
end

function ProfileDefinition:getMacroClass(def)
  local detected = self:identifyTableType(def)
  if detected == "group" then
    def.type = "group"
    return tl:classImport("GroupMacro")
  elseif detected == "macro" then
    if type(def) == "string" then def = {def,type="key"}
    elseif not def.type then def.type = "key" end
    local macroType = tl.classMap[def.type]
    def.type = macroType[2]
    return tl:classImport(macroType[1])
  end
  return false
end

function ProfileDefinition:buildTree()
  local extable={}
  for k, v in pairs(self.bindings) do extable[#extable+1] = k..": "..self.macroIndex[v]:export() end
  return concat(extable,"\n\n")
end

function ProfileDefinition:parseLibrary()
  local total = # (self.assign.library or {})
  if total == 0 then self.libInit = true return end
  local processed = 0
  local function getLib(class)
    local classID = class:awaitOwnId()
    if classID then self.libMacros[#self.libMacros+1] = classID end
    processed = processed+1
    if processed == total then  self.libInit = true end
  end

  for i = 1, total do local libMacro = self.assign.library[i]
    local bindingClass = self:getMacroClass(libMacro)---@type MacroDefinition
    if bindingClass then
      local bindingInstance = bindingClass:new(libMacro,self,self.assign.scopeDefaults,self.assign.scopeOverride)
      self:async(getLib,bindingInstance)
    end
  end
end

function ProfileDefinition:parseBindings()
  self.bindings = {}
  local processed = (0 + ((self.assign.exit and 1) or 0) + ((self.assign.start and 1) or 0))
  local total = 0
  for _ in pairs(self.assignFlattened) do  total = total + 1 end
  ---@param class MacroDefinition
  local function getBinding(class,key)
    local classID = class:awaitOwnId()
    if classID then self.bindings[key] = classID end
    processed = processed+1
    if processed == total then 
      for k, v in pairs(self.macroIndex) do
        if v.type then local typeIndex = self.typedIndex[v.type]
          if typeIndex then typeIndex[#typeIndex+1] = k  else self.typedIndex[v.type] = {k} end
        end
      end
      self.init = true
    end
  end

  for key, bindingTable in pairs(self.assignFlattened) do
    local bindingClass = self:getMacroClass(bindingTable)---@type MacroDefinition
      if bindingClass then
        local fam
        if self.deviceState[tl.str:token(key) or "null"] then fam = tl.str:token(key) end
        local bindingInstance = bindingClass:new(bindingTable,self,self.assign.scopeDefaults,self.assign.scopeOverride,nil,fam)
        self:async(getBinding,bindingInstance,key)
    end
  end

  if self.assign.exit then 
    local exitClass = self:getMacroClass(self.assign.exit)
    if exitClass then self:async(getBinding,exitClass:new(self.assign.exit,self,self.assign.scopeDefaults,self.assign.scopeOverride),"exit")end
  end

  if self.assign.start then
    local startClass = self:getMacroClass(self.assign.start)
    if startClass then self:async(getBinding,startClass:new(self.assign.exit,self,self.assign.scopeDefaults,self.assign.scopeOverride),"start") end
  end
end

---Apply T-Lib options, cascade through option inheritance.
---@private
---@param configurator OptionsCollection
---@param init boolean
function ProfileDefinition:applyConfig()
  local configurator = self.config
  if configurator.resolutions then self.resolutions = tl.mouseMonitorUtils:compileScreenCoordinates(configurator.resolutions, self) or {} end
  self:defineDevices()
  if self.config.defaultKeys then for k, v in pairs(self.config.defaultKeys) do self.assign.key[k] =  self.assign.key[k]  or v end end
  self:compileAssignments()
end

---@private
function ProfileDefinition:defineDevices()
  local moreModes = 0
  local moreKeys = 0
  local sKey = false
  if self.config.rename then for k, v in pairs(self.config.rename) do self.unRename[v] = k end end
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
      family= fam,
      token = shorty
    }
    if self.deviceState[shorty].sKey then sKey = true end
    if self.config.defaultModeTarget == "join" then self.deviceState[shorty].modeConfig = self.config.genericModes end
    if self.deviceState[shorty].modeCount > moreModes then moreModes = self.deviceState[shorty].modeCount end
    if self.deviceState[shorty].buttonCount > moreKeys then moreKeys = self.deviceState[shorty].buttonCount end
    for m = 1, self.deviceState[shorty].buttonCount do self.unRename[shorty .. m] = self.unRename[shorty .. m] or shorty .. m end
    for h = 1, #self.deviceState[shorty].modeConfig do
      if type(self.deviceState[shorty].modeConfig[h]) ~= "table" then
       self.deviceState[shorty].modeConfig[h] = {self.deviceState[shorty].modeConfig[h]}
      end
    end
  end
  self.deviceState.maxMode = moreModes
  for i = 1, self.deviceState.maxMode do self.config.genericModes[i] = self.config.genericModes[i] or {i}
    if type(self.config.genericModes[i]) ~= "table" then self.config.genericModes[i] = {self.config.genericModes[i]} end
  end
  self.deviceState.maxKeys = moreKeys
  self.deviceState.sKey = sKey
end

return ProfileDefinition