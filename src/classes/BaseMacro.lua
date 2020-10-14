local tl,Base = ...---@type MainLibObject
local pairs, resume,concat,yield,create,type = pairs,coroutine.resume,table.concat,coroutine.yield,coroutine.create,type
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
  self:async(self.parseSubMacros,self)
end
---@protected
function BaseMacro:finishInit()
  if self.pID then 
    self.stack[#self.stack+1] = self.pID
    self.profile.macroIndex[self.pID] = self
    if self.name then
      self.profile.nameMap[self.name] = self.pID  
      if self.profile.awaiting[self.name]then
        local store = self.profile.awaiting[self.name].queue
        for i = 1, #store do self:async(store[i],self.pID) end
      end
    end
  end
end
---@protected
function BaseMacro:async(thread,...) 
  local thr = thread
  if type(thr) ~="thread" then thr = create(thr) end
  local b,e = resume(thr,...)
  if not b then tl:put(e) end
end

function BaseMacro:replaceName(name,key,parent,noTable)
  local fetched = self:awaitId(name)
  parent[key] = (noTable and fetched) or {fetched}
end

---@protected
function BaseMacro:extractOptions(keyList)
  local container ={}
  for i = 1, #keyList do local key = keyList[i]
    container[key] = self.options[key]
  end
  return container
end

---@protected
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
---@protected
function BaseMacro:circular(name,stack)
if not self.profile.awaiting[name] then return end
  local stack = stack or {}
  local store = self.profile.awaiting[name].waiting
  for i = 1, #store do local waiter = store[i]
    for m = 1, #stack do
      if waiter == stack[m] then 
        stack[#stack+1]=waiter
      error('circular requirement detected: '..concat(stack,'->'))
    end
  end
  stack[#stack+1]= name
  self:circular(waiter,stack)
  end
end
---@protected
function BaseMacro:awaitId(name)
  if self.profile.nameMap[name] then return self.profile.nameMap[name] else
    if self.profile.awaiting[name] then
      self.profile.awaiting[name].queue[#self.profile.awaiting[name].queue+1] = running()
      self.profile.awaiting[name].waiting[#self.profile.awaiting[name].waiting+1] = self.name or self.pID
    else self.profile.awaiting[name] = {queue ={running()},waiting={self.name}}end
    self:circular(name)
    return yield()
  end
end

function BaseMacro:execute() end

return BaseMacro
