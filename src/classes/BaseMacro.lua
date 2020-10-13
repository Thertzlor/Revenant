local tl,Base = ...---@type MainLibObject
local pairs, resume = pairs,coroutine.resume
---@class BaseMacro:BaseClass
---@field state table
local BaseMacro = Base:new()

---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
function BaseMacro:constructor(macroSummary,parentProfile,defaults,overrides,stack)
  if not macroSummary then return end
  self.stack = stack or {}
  self.awaiting = {}
  self.profile = parentProfile
  self.raw = macroSummary;
  self.subMacros = {}
  self.overrides = overrides or {}
  self.defaults = defaults or {}
  self.command,self.options = tl.tbl:splitDefinition(macroSummary)
  for k, v in pairs(self.defaults) do self.options[k] = self.options[k] or v; end
  for k, v in pairs(self.overrides) do self.options[k] = v; end
  self.type = self.options.type
  self.name = self.options.name
  self.options.type = nil
  self.pID = self:genId()
  self:expandOptions()
  self:parseSubMacros()
end

function BaseMacro:finishInit()
  if self.pID then 
    self.stack[#self.stack+1] = self.pID
    self.profile.macroIndex[self.pID] = self
    if self.name and self.profile.awaiting[self.name]then
      local store = self.profile.awaiting[self.name]
      for i = 1, #store.queue do local q = store.queue[i]
        resume(q,self.pID)
      end
    end
  end
end

---@protected
function BaseMacro:extractOptions(keyList)
  local container ={}
  for i = 1, #keyList do local key = keyList[i]
    container[key] = self.options[key]
  end
  return container
end

function BaseMacro:parseSubMacros() self:finishInit() end
---@protected
function BaseMacro:expandOptions()
  local short = self.profile.config.preferShorthand
  local mappedTerms = tl.stringPresets.shortHands
  for i = 1, #mappedTerms do local term = mappedTerms[i]
    local primary = short and term[1] or term[2]
    local secondary = short and term[2] or term[1]
    if (self.options[primary] ~= nil) or (self.options[secondary] ~=nil) then
      local finalValue
      if (self.options[primary] ~= nil) then 
        finalValue = self.options[primary]
      else 
        finalValue = self.options[secondary] 
      end
      self.options[term[2]] = finalValue
      self.options[term[1]]=nil
    end
  end
end

function BaseMacro:execute() end

return BaseMacro
