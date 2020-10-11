local tl, Base = ...---@type MainLibObject
local rawset, type, setmetatable, pairs,next = rawset, type, setmetatable, pairs,next

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
    if type(v) == "table" and not v._meta then
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
  self.autoKeys = true
  self.buttonMap = {}
  ---@type table<string,BaseMacro>
  self.macroIndex = {}
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
  self.autoKeys = false
  self.config = tl.tbl:intersectSimple(tl.defaultConfig,self.assign.config or {})
  if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
  self.name = self.config.profileName
  self.stack[#self.stack+1] = self.path
  self:applyConfig(init)
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
