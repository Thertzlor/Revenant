local tl, Base = ...---@type MainLibObject
local rawset, type, setmetatable, pairs,next,insert = rawset, type, setmetatable, pairs,next,insert

---@alias MacroTable table<string,GenericMacro>
---@alias MacroArray table<number,GenericMacro>
---@alias Assignment GenericMacro|MacroArray|MacroTable

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
    if type(v) == "table" then
      table[k] = self:recursiveTable(v)
    end
  end
  return self:autoTable(table)
end

---Yaes
---@param path string
---@param init boolean
---@param stack string[]
function ProfileDefinition:constructor(path,name,stack,init)
  self.stack = stack or {}
  self.path = path or "origin"
  self.init = false
  self.autoKeys = true
  self.awaiting = {}
  self.buttonMap = {}
  self.nameMap = {}---@type table<string,string>
  self.macroIndex = {}  ---@type table<string,BaseMacro>
  self.config = {}---@type OptionsCollection
  self.documentation={}
  self.toggledKeys={}
  self.deviceState={}
  self.unRename = {}
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
  self.logiSet = tl.paths.profile
  self.assign = self:autoTable(baseTable)
  if path then tl:profileImport(path,self.assign) end
  if init then self.logiSet(self.assign) end
  if self.assign.config.externalConfigs then end
  if self.assign.config.externalDocs then end
  self.autoKeys = false
  self.config = tl.tbl:intersectSimple(tl.defaultConfig,self.assign.config or {})
  if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
  self.name = self.config.profileName
  self.stack[#self.stack+1] = self.path
  for k, v in pairs(tl.config.defaultKeys) do self.assign[k] = self.assign[k] or v end
  self:applyConfig(init)
end


function ProfileDefinition:fetchDocs()end
function ProfileDefinition:fetchConfigs()end
function ProfileDefinition:fetchLibrary()end

---@private
function ProfileDefinition:_compileAssignments(startable)
  local collector =  {}

  local function extractFromTable(state, presets, subType) --Extract button functionality and put it into the main table
    self:_inherit(state, self.assign)
    local stackM = self.config[subType .. "Stack"]
    local mergedResult = {}
    local tablePresets = tl.tbl:intersect({}, presets)
    local presetType = tablePresets.type
    local singleTypeSetting = tablePresets.singleType or self.config.singleType

    for k, v in pairs(state) do
      if type(k) == "string" and self.unRename[k] ~= nil then
        if type(v) ~= "table" then
          v = {v}
        elseif tl.tbl.identifyTableType(v) == "group" then
          for u = 1, #v do
            if type(v[u]) ~= "table" then v[u] = {v[u]} end
          end
        end
        if collector[k] == nil then
          collector[k] = v
        else
          if type(collector[k]) ~= "table" then
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
                if self.config.stackAutoReverse then h = #v - u + 1 end
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
    self:_inherit(t, self.assign)
    previousTableState = previousTableState or {}
    local newTableState = tl.tbl:intersect({}, previousTableState)
    local function setMode()
      local returnValue = {}
      for k = 0, self.deviceState.maxMode do
        local j = k
        if self.config.modeSort == "reverse" then
          j = self.deviceState.maxMode - k
        elseif type(self.config.modeSort) == "table" and #self.config.modeSort == self.deviceState.maxMode + 1 then
          j = self.config.modeSort[k + 1]
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
      if self.deviceState.sKey ~= 0 then
        for h = 0, 2 do
          local j = h
          if self.config.shiftSort == "reverse" then
            j = self.deviceState.maxMode - h
          elseif type(self.config.shiftSort) == "table" and #self.config.shiftSort == 3 then
            j = self.config.shiftSort[h + 1]
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
      for r = 1, #self.config.customSort do
        local customGroupName = self.config.customSort[r]
        local customGroupTableState = {}
        if t[customGroupName] and t[customGroupName] == "table" then
          for d, m in pairs(t[customGroupName]) do
            if type(d) == "string" and self.unRename[d] == nil then customGroupTableState[d] = m end
          end
          returnValue[#returnValue + 1] = extractFromTable(t[customGroupName], tl.tbl:intersect(previousTableState, customGroupTableState, 1), "custom")
          t[customGroupName] = nil
        end
      end
      for h, p in pairs(t) do
        local privs = {}
        if sub(h, 1, 2) == "_c" and type(p) == "table" then
          for d, m in pairs(p) do
            if type(d) == "string" and self.unRename[d] == nil then
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
    for g = 1, #self.config.stackOrder do
      local l = g
      if
        self.config.stackAutoReverse and self.config.modeStack == "prepend" and self.config.shiftStack == "prepend" and
          self.config.customStack == "prepend"
       then
        l = #self.config.stackOrder - g + 1
      end
      nextWave[#nextWave + 1] = orderTable[self.config.stackOrder[l]]()
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
  resolveHierachy(self.assign)
  resolveHierachy(self.assign.key)
  self.assignFlattened = collector
end

  ---Pass parent properties to child tables
---@param taba GenericMacro
---@param origTable GenericMacro
---@param globalis table
---@private
function ProfileDefinition:_inherit(taba, origTable, globalis)
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
  if globalis == 1 then
    self.assign.scopeDefaults = nil
    self.assign.scopeOverride = nil
  end
end

function ProfileDefinition:parseBindings()
  self.bindings = {}
  local processed = 0
  local fullTotal
  local bindingStats = {_fullTotal = 0}
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
    if processed == fullTotal then self.init = true end
  end
  for key, bindingTable in pairs(self.assignFlattened) do
    local singleKeyCollection = {}
    for i = 1, #bindingTable do local binding = bindingTable[i]
      ---@type BaseMacro
      local bindingClass = tl.bindings:getMacroClass(binding);
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
end

---@private
function ProfileDefinition:defineDevices()
  local moreModes = 0
  local moreKeys = 0
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
end

return ProfileDefinition