local tl, Base = ...---@type MainLibObject
local rawset, type, setmetatable, pairs = rawset, type, setmetatable, pairs

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
  self.config = {}
  self.documentation={}
  self.toggledKeys={}
  ---@class MacroAssignment
  ---@field key table<string,Assignment>
  ---@field documentation table<string,string>
  ---@field config table
  ---@field exit Assignment
  ---@field library Assignment
  ---@field scopeDefaults Assignment
  ---@field scopeOverride Assignment
  ---@field start Assignment
  local baseTable = {}
  self.logiSet = tl.config.setKeys
  tl.config.setKeys = nil
  self.assign = self:autoTable(baseTable)
  if path then tl:profileImport(path,self.assign) end
  self.config = tl.tbl:intersectSimple(self.config)
  if init then self.logiSet(self.assign) end
  self.stack[#self.stack+1] = self.path
end


return ProfileDefinition
