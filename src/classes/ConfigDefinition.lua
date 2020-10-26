local tl,Base = ...---@type MainLibObject
local next,type,concat,error = next,type,table.concat,error
---@class ConfigDefinition:BaseClass
local ConfigDefinition = Base:new()

---@param a OptionsCollection
---@param b OptionsCollection
local function _mergeConfigs(a,b)
  --TODO actual in-depth merge
  local keep = a.handleOptionConflicts ~= "replaceDuplicates"
  return tl.tbl:intersectSimple(a,b,keep)
end


function ConfigDefinition:constructor(baseData,stack)
  self.stack = stack or {}
  self.base = baseData
  self.tempConfigs={}---@private
  self.finalConfig = tl.defaultConfig
  local function singleImport(base)
    if type(base) == "table" then
      self.tempConfigs[#self.tempConfigs+1] = base
      return
    end
    local stack = self.stack
    for i = 1, #stack do
      if stack[i] == base then
        stack[#stack+1]=base
        error("Circular dependency while loading configuration files: "..concat(stack,'->'))
      end
    end
    self.stack[#self.stack+1]=base
    local tempImport = tl:import(base,function()end) ---@type OptionsCollection
    if tempImport then
      local parent = tempImport.externalConfigs
      if parent then
        local subDef = ConfigDefinition:new(parent,stack):output()
        if subDef then tempImport = _mergeConfigs(tempImport,subDef) end
      end
      self.tempConfigs[#self.tempConfigs+1] = tempImport
    end
  end

  self:multiArg(singleImport,self.base)
  if next(self.tempConfigs) then
    for i = 1, #self.tempConfigs do local temp = self.tempConfigs[i]
    self.finalConfig = _mergeConfigs(self.finalConfig,temp)end
  end
end

function ConfigDefinition:output()
    if next(self.finalConfig) then return self.finalConfig end
  return false
end

return ConfigDefinition