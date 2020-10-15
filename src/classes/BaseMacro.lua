local tl,Base = ...---@type MainLibObject
local pairs,concat,yield,type,running = pairs,table.concat,coroutine.yield,type,coroutine.running
---@class BaseMacro:BaseClass
---@field state table
local BaseMacro = Base:new()
local delayedTypes = tl.tbl:propsFrom{"link","group"}
---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
function BaseMacro:constructor(macroSummary,parentProfile,defaults,overrides,stack)
  if not macroSummary then return end
  self.stack = stack or {}
  self.init = false
  self.awaiting = {}
  self.profile = parentProfile
  self.raw = macroSummary;
  self.subMacros = {}
  self.overrides = overrides or {}
  self.defaults = defaults or {}
  self.command,self.options = tl.tbl:splitDefinition(macroSummary)
  self.type = self.options.type or "k"
  self.name = self.options.name
  self.options.type = nil
  for k, v in pairs(self.defaults) do self.options[k] = self.options[k] or v; end
  if not delayedTypes[self.type] then self.pID = self:genId()end
  if self.type == "group" then self.raw.type = nil else
    for k, v in pairs(self.overrides) do self.options[k] = v; end
  end
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
  if self.idThread then
    self:async(self.idThread,self:identify())
  end
  self.init = true
end

---@param target string|BaseMacro
---@param key string|number
---@param parent table
---@param  table boolean optional
function BaseMacro:replaceWithId(target,key,parent,table)
  local fetched = self:awaitId(target)
  parent[key] = (table and {fetched}) or fetched
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
---**@async**  
---Waits for a Macro to be fully initialized and then returns its ID.
---@param target string|BaseMacro The macro can either be targeted by its name or referenced directly
function BaseMacro:awaitId(target)
  if type(target)~="string" then return target:awaitOwnId() end
  if self.profile.nameMap[target] then return self.profile.nameMap[target] else
    if self.profile.awaiting[target] then
      self.profile.awaiting[target].queue[#self.profile.awaiting[target].queue+1] = running()
      self.profile.awaiting[target].waiting[#self.profile.awaiting[target].waiting+1] = self.name or self.pID
    else self.profile.awaiting[target] = {queue ={running()},waiting={self.name}}end
    self:circular(target)
    return yield()
  end
end
---**@async**  
---Returns the macro ID when the macro is fully initialized
---@return string ID of the macro or replacement macro if bypassed
function BaseMacro:awaitOwnId()
  if self.init then return self:identify() end
  self.idThread = running()
  return yield()
end

function BaseMacro:identify()
  return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil
end

function BaseMacro:execute() end

return BaseMacro
