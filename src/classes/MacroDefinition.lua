local tl = ...---@type MainLibObject
local pairs,concat,yield,type,running,rep = pairs,table.concat,coroutine.yield,type,coroutine.running,string.rep
---@class MacroDefinition:BaseClass
---@field profile ProfileDefinition
local MacroDefinition = tl.baseClass:new()

local delayedTypes = tl.tbl:propsFrom{"instance","group"}
local toMain = {{"type","key"},"name",{"direction","normal"}}

---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
---@field type string
---@field direction string
---@field name string
function MacroDefinition:constructor(macroSummary,parentProfile,defaults,overrides,stack,device)
  if not macroSummary then return end
  self.sourceDevice = device
  self.stack = stack or {}
  self.init = false
  self.profile = parentProfile
  self.singleTrigger = false
  self.raw = macroSummary;
  self.subMacros = {}
  self.references = {}
  self.overrides = overrides or {}
  self.defaults = defaults or {}
  self.rawCommand,self.rawOptions = tl.tbl:splitDefinition(macroSummary)
  self.command = self.rawCommand
  self.options = tl.tbl:intersectSimple(self.rawOptions,(macroSummary._inherit or {}))
  for k, v in pairs(self.defaults) do self.options[k] = self.options[k] or v; end
  if self.type == "group" then self.raw.type = nil else
    for k, v in pairs(self.overrides) do self.options[k] = v; end
  end
  self:expandOptions()
  for i = 1, #toMain do local main,mainTab = toMain[i],(type(toMain[i]) == "table")
    local target = (mainTab and main[1] or main)
    self[target] = self.options[target] or (mainTab and main[2])
    self.options[target] = nil
  end
  if not delayedTypes[self.type] then self.pID = self:genId()end
  self:async(self.parseInstructions,self)
end
---@protected
function MacroDefinition:finishInit()
  if self.pID then 
    tl:put("finished "..self.pID,self.type,tl.helperUtils.pprint(self.subMacros))
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
  if self.idThread then self:async(self.idThread,self:identify()) end
  self.init = true
end

---@param target string|MacroDefinition
---@param key string|number
---@param parent table
---@param  table boolean optional
function MacroDefinition:replaceWithReferenceId(target,key,parent,table)
  local fetched = self:awaitId(target,true)
  self.references[#self.references+1]=fetched
  parent[key] = (table and {fetched}) or fetched
end

---@param event Event
---@param virtualType number
function MacroDefinition:virtualize(event,virtualType)
  local virtuVent = event
  virtuVent.virtualType = virtualType
  virtuVent.stack = virtuVent.stack or {}
  virtuVent.stack[#virtuVent.stack+1]=self.pID
  virtuVent.virtualFamily = event.family
  virtuVent.virtualDirection = event.direction
  virtuVent.originator = virtuVent.originator or self.pID
  return virtuVent
end

---@protected
function MacroDefinition:extractOptions(keyList)
  local container ={}
  for i = 1, #keyList do local key = keyList[i]
    container[key] = self.options[key]
  end
  return container
end

---@protected
function MacroDefinition:expandOptions()
  local short = self.profile.config.preferShorthand
  local mappedTerms = tl.stringPresets.shortHands
  for i = 1, #mappedTerms do local term = mappedTerms[i]
    local primary = short and term[1] or term[2]
    local secondary = short and term[2] or term[1]
    if (self.options[primary] ~= nil) or (self.options[secondary] ~=nil) then
      local finalValue
      if (self.options[primary] ~= nil) then  finalValue = self.options[primary]
      else  finalValue = self.options[secondary]  end
      self.options[term[2]] = finalValue
      self.options[term[1]]=nil
    end
  end
end
---@protected
function MacroDefinition:circular(name,stack)
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
---@param target string|MacroDefinition The macro can either be targeted by its name or referenced directly
---@param refOnly boolean If we're only waiting for a reference we don't care if teh reference is circular.
function MacroDefinition:awaitId(target,refOnly)
  if type(target)~="string" then return target:awaitOwnId() end
  if self.profile.nameMap[target] then return self.profile.nameMap[target] else
    if self.profile.awaiting[target] then
      self.profile.awaiting[target].queue[#self.profile.awaiting[target].queue+1] = running()
      self.profile.awaiting[target].waitNum = self.profile.awaiting[target].waitNum +1 
    else 
      self.profile.awaiting[target] = {queue ={running()},waitNum = 1}
    end
    if self.name then 
      if not self.profile.awaiting[target].waiting then self.profile.awaiting[target].waiting = {self.name} else
      self.profile.awaiting[target].waiting[#self.profile.awaiting[target].waiting+1] = self.name end
      if not refOnly then self:circular(target) end
    end
    local yieldedName = yield()
    self.profile.awaiting[target].waitNum = self.profile.awaiting[target].waitNum - 1
    --if self.profile.awaiting[target].waitNum == 0 then self.profile.awaiting[target] = nil end
    return yieldedName
  end
end

---@return KeyPress
function MacroDefinition:keyPress(event)
  return {
    actionDelay = self.options.actionDelay or self.profile.config.actionDelay,
    keyDelay  = self.options.keyDelay or self.profile.config.keyDelay,
    actionVariance= self.options.actionVariance or self.profile.config.actionVariance,
    keyVariance = self.options.keyVariance or self.profile.config.keyVariance,
    family = event.family,
    keyNum = event.keyNum,
    forceSleep = false
  }
end

---**@async**  
---Returns the macro ID when the macro is fully initialized
---@return string ID of the macro or replacement macro if bypassed
function MacroDefinition:awaitOwnId()
  if self.init then return self:identify() end
  self.idThread = running()
  return yield()
end

---@param event Event
function MacroDefinition:run(event)
  local options = self.options
  self.state = self.state or {}
  if  tl.validator:validateConditions(event,options,self.type,self.pID,self.singleTrigger) then
    self:execute(event)
    self.profile.deviceState[event.family].conKey = (not (not event.virtualType and (options.consume == 1 or options.consume == 3)) and 0) or event.keyNum
  end
end

function MacroDefinition:parseInstructions()self:finishInit() end

function MacroDefinition:export(startDepth)
  local depth = startDepth or 0
  local indent = rep("    ",depth)
  local subTable={}
  
  local startLine = (indent or "")..tl.classMap[self.type or "key"][1].." ("..self.type..")"
  for i = 1, #self.subMacros do 
    subTable[#subTable+1]= self.profile.macroIndex[self.subMacros[i]]:export(depth+1)
  end
  if #subTable == 0 then return startLine 
  else return startLine.."\n"..concat(subTable,"\n") end
end

function MacroDefinition:identify() return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil end

function MacroDefinition:execute() end

return MacroDefinition