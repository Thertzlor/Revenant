local tl,Base = ...---@type MainLibObject
local next,type = next,type
---@class ConfigDefinition:BaseClass
local ConfigDefinition = Base:new()

local function _mergeConfigs(a,b)
  --//TODO actual in-depth merge
return tl.tbl:intersectSimple(a,b)
end

function ConfigDefinition:constructor(base,stack)
  self.stack = stack or {}
  self.base = base
  self.tempConfigs={}---@private
  self.finalConfig = {}
--//TODO circular prevention
  local function singleImport(base)
    if type(base) == "table" then
      self.tempConfigs[#self.tempConfigs+1] = base
      return
    end
    local stack = self.stack
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
    if #self.tempConfigs == 1 then
      self.finalConfig = self.tempConfigs[1]
    else
      for i = 1, #self.tempConfigs do local temp = self.tempConfigs[i]
        self.finalConfig = _mergeConfigs(self.finalConfig,temp)
      end
    end
  end
end

function ConfigDefinition:output()
  if next(self.finalConfig) then return self.finalConfig end
  return false
end