local tl = ...---@type MainLibObject
local pairs,concat,yield,type,running,rep,match,sub,error = pairs,table.concat,coroutine.yield,type,coroutine.running,string.rep,string.match,string.sub,error
---@class MacroDefinition:BaseClass
---@field profile ProfileDefinition
local MacroDefinition = tl.baseClass:new()
local delayedTypes = tl.tbl:propsFrom{"instance","group"}
local toMain = {{"type","key"},"name",{"direction","normal"}}
MacroDefinition.lintProperties = {}
---Maps long option names to shorter ones.
MacroDefinition.shortHands = {}
---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
---@field type string
---@field direction string
---@field name string
function MacroDefinition:constructor(macroSummary,parentProfile,defaults,overrides,stack,device)
  if not macroSummary then return end
  self.shortHands = tl.tbl:intersectSimple(tl.stringPresets.shortHands,self.shortHands,true)
  self.shortMap = {} ---@protected
  for k, v in pairs(self.shortHands) do self.shortMap[#self.shortMap+1]={k,v} end
  self.sourceDevice = device
  self.stack = stack or {} ---@protected
  self.init = false ---@protected
  self.profile = parentProfile
  self.singleTrigger = false ---@protected
  self.raw = macroSummary;
  self.subMacros = {} ---@protected
  self.references = {} ---@protected
  self.overrides = overrides or {} ---@protected
  self.defaults = defaults or {}
  self.rawCommand,self.rawOptions = tl.tbl:splitEnumerable(macroSummary) ---@protected
  self.command = self.rawCommand ---@protected
  self.options = tl.tbl:intersectSimple(self.rawOptions,(macroSummary._inherit or {}))
  for k, v in pairs(self.defaults) do self.options[k] = self.options[k] or v; end
  if self.type == "group" then self.raw.type = nil else
    for k, v in pairs(self.overrides) do self.options[k] = v; end
  end
  self:expandOptions()
  self:parseQualifiers()
  for i = 1, #toMain do local main,mainTab = toMain[i],(type(toMain[i]) == "table")
    local target = (mainTab and main[1] or main)
    local rep = self.options[target]
    if not rep and mainTab and main[2] then rep = main[2] end
    self[target] = rep
    self.options[target] = nil
  end
  self.titleExport = tl.classMap[self.type or "key"][1].." ("..self.type..")"
  if not delayedTypes[self.type] then  self.pID = self:genId() end
  self.state = self.state or {}
  self:async(self.parseInstructions,self)
  tl.lint:KeyLinter(self.raw,self.lintProperties,self.shortHands,self.name or self:export(),self.name)
end

---@protected
function MacroDefinition:finishInit(transient)
  if self.pID then 
    --tl:put("finished "..self.pID,self.type,tl.helperUtils.pprint(self.subMacros))
    if not transient then self.profile.macroIndex[self.pID] = self end
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

---@protected
---@param target string|MacroDefinition
---@param key string|number
---@param parent table
---@param  table boolean optional
function MacroDefinition:replaceWithReferenceId(target,key,parent,table,func)
  local fetched = self:awaitId(target,true)
  func = func or function(x)return x end
  self.references[#self.references+1]=fetched
  parent[key] = (table and {func(fetched)}) or func(fetched)
end

---@protected
---@param event Event
---@param virtualType number
function MacroDefinition:virtualize(event,virtualType)
  local virtuVent = event
  virtuVent.virtualType = virtualType
  virtuVent.stack = virtuVent.stack or {}
  virtuVent.stack[#virtuVent.stack+1]=self.pID
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
  local mappedTerms = self.shortMap;
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
---@param refOnly boolean If we're only waiting for a reference we don't care if the reference is circular.
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

---@protected
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

function MacroDefinition:runFree(event)
  local options = self.options
  if tl.validator:skipConditions(event,options,self.type,self.pID,self.singleTrigger) then
    self:execute(event)
    self.profile.deviceState[event.family].conKey = (not (not event.virtualType and (options.blocking == 1 or options.blocking == 3)) and 0) or event.keyNum
  end
end

---@param event Event
function MacroDefinition:run(event)
  local options = self.options
  if tl.validator:validateConditions(event,options,self.type,self.pID,self.singleTrigger) then
    self:execute(event)
    self.profile.deviceState[event.family].conKey = (not (not event.virtualType and (options.blocking == 1 or options.blocking == 3)) and 0) or event.keyNum
  end
end

---@protected
function MacroDefinition:errorHandler(msg)
  local name = self.name
  tl:put(tl.helperUtils.pprint(self.stack))
  if not name then for i = 1, #self.stack do local stn = self.stack[i][2] if stn then name = "Child Macro of "..stn end break end
  else name = "Macro "..name end
  if not name then name = "a "..self.type.." macro" end
  tl.scriptStates.errors[#tl.scriptStates.errors+1]  = name.." failed to initialize:\n  "..msg
end

---@protected
function MacroDefinition:parseInstructions()self:finishInit()end

---@private
function MacroDefinition:parseQualifiers()
  if self.options.mode then local modas = self.options.mode
    if type(modas) ~= "table" then modas = {modas} end
    for i = 1, #modas do local mod = modas[i]
      if type(mod) == "string" then
        local minus = match(mod,"^-")
        mod = (minus and sub(mod,2)) or mod
        local realMod = self.profile.deviceState[self.sourceDevice].modeIndex[mod]
        if not realMod then error("mode "..mod.." not found on "..self.profile.deviceState[self.sourceDevice].family) end
        modas[i] = realMod * ((minus and -1) or 1)
      end
    end
    self.options.mode = (#modas == 1 and modas[1]) or modas
  end
  if self.options.condition then 
    local function testReplace(el,index,parent)
      if type(el) ~= "table" then if type(el) == "string" then 
        local prefix = sub(el,1,2)
        if prefix == ":" or prefix == "~" then
          self:async(self.replaceWithReferenceId,self,el,index,parent,function(wac)return prefix..wac end) end
        end
      else for i = 1, #el do testReplace(el[i],i,el) end end
    end
    testReplace(self.options.condition,"condition",self.options)
  end
end

--TODO:Better exports for different modules including submodules
function MacroDefinition:exportContent(depth)
  depth = depth or 0
  local indent = rep("    ",depth)
  local subTable={}
  for i = 1, #self.subMacros do 
    subTable[#subTable+1]= self.profile.macroIndex[self.subMacros[i]]:export(depth+1)
  end
  if #subTable == 0 then return false end
  return "\n"..concat(subTable,",\n")
end
function MacroDefinition:export(depth)
  depth = depth or 0
  local indent = rep("    ",depth)
  local startLine = (indent or "")..self.titleExport 
  local content = self:exportContent(depth+1)
  return startLine..(content or "")..(self.endExport and "\n"..indent..self.endExport or "")
end

---@protected
function MacroDefinition:identify() return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil end

function MacroDefinition:execute() end

return MacroDefinition