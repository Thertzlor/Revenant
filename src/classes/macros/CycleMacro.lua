local tl = ...---@type MainLibObject
local type,GetRunningTime,abs,huge = type, GetRunningTime,math.abs,math.huge
local MacroDefinition = tl:classImport('MacroDefinition')

local function log(what) tl:put(tl.helperUtils.pprint(what)) end


---@class CycleMacro:MacroDefinition
---@field profile ProfileDefinition
---@field options {limit:number,cancel:number,inherit:string,finish:string,range:number[]}
local CycleMacro = MacroDefinition:new()

function CycleMacro:parseInstructions()
  if self.options.limit == 0 or not self.options.limit then self.options.limit = huge end 
  self.singleTrigger = false
  self.options.inherit = self.options.inherit or "all"
  self.options.cancel = self.options.cancel or 0
  self.options.finish = self.options.finish or "stall"
  self.unstable = (self.options.cancel == 1 or self.options.cancel < 0)
  self.command = {}
  local processed = 0
  local offset = 0
  local command = {}

  local function finalIteration()
    if self.init then return end
    self.command = command
    for i = 1, #self.command do local finCm = self.command[i]
      if finCm._ref then local ref = finCm._ref
        self.command[i] = {ref}
        self:async(self.replaceWithReferenceId,self,ref,i,self.command,true)
      end
    end
    self:finishInit()
  end

  local function fetcher(tNum,class)
    local initId = class:awaitOwnId()
    if initId then self.subMacros[#self.subMacros+1] = initId end
    command[tNum] = {initId}
    processed = processed + 1
    if processed == #self.rawCommand then finalIteration() end
  end

  for i = 1, #self.rawCommand do local cmd = self.rawCommand[i]
    local cType = type(cmd)
    if cType =="table"  and (not tl.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
      command[i-offset] = {_ref = cmd[1]}
      processed = processed+1
    elseif cType =="table"  then
      local elClass---@type MacroDefinition
      if (not tl.tbl:hasProperties(cmd)) and tl.tbl:isSingleTypeTable(cmd,"string")then cmd.type = "key" end
      local tableType = self.profile:identifyTableType(cmd)
      if tableType == "group" then
        elClass = tl:classImport('GroupMacro')
      elseif tableType == "macro" then elClass = self.profile:getMacroClass(cmd)  end
      if not elClass then return end
      local elInstance = elClass:new(cmd,self.profile,nil,self.overrides,self.stack,self.sourceDevice)
      self:async(fetcher,(i-offset),elInstance)    
    elseif cType == "number" or cType == "string" then
      command[i-offset] = cmd
      processed = processed+1
    else
      offset = offset +1
      processed = processed+1
    end
    if processed == #self.rawCommand then finalIteration() end
  end
end

---@param event Event
function CycleMacro:execute(event)
  local dir,vir,virtParent,fam,num = event.direction,event.virtualType,event.originator,event.family,event.keyNum
  local cycles = self.command
  local options = self.options
  local pID = self.pID
  local meta = self.state
  if type(cycles) ~= "table" then return end
  local step = 1
  local lim = options.limit 
  local inherit = options.inherit
  local rupture = options.cancel
  local parent = (virtParent and type(virtParent) ~= "number" and virtParent) or virtParent or 999
  local quitter = options.finish
  local start = 1
  local init = start
  local finish = #cycles
  if type(options.range) == "table" and tl.tbl:isSingleTypeTable(cycles.range, "number") then
    local range = options.range
    for j = 1, range do
      if range[j] <= 0 then range[j] = #cycles + range[j] end
    end
    if range[2] and range[2] < #cycles then init = range[2] end
    if range[1] < #cycles then start = range[1] end
    finish = range[3] or finish
    if finish > #cycles then finish = #cycles end
  end
  local directed = vir and 2 or 3
  ---@type Event
  local virtualEvent = self:virtualize(event,directed)
  local press = self:keyPress(event)
  if meta.position == nil or (vir and dir == "down" and (self.profile.macroIndex[parent].state.position == 1)
  and meta.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
    meta.position = init
    meta.cyclesComplete = 1
    meta.cycleTimer = GetRunningTime()
  elseif rupture ~= 0 and rupture ~= 1 and (vir ~= nil or dir == "down") and (GetRunningTime() - meta.cycleTimer > abs(rupture)) then
    meta.position = init
    meta.cyclesComplete = 1
  end
  if type(meta.cyclesComplete) == "number" and meta.cyclesComplete > lim then
    if quitter == "end" then
     return
    elseif quitter == "reset" then
      meta.position = init
      meta.cyclesComplete = 1
    elseif type(quitter) == "table" then
      self.profile.macroIndex[quitter[1]]:run(virtualEvent)
      return
    end
  end
  if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
    meta.cycleTimer = (self.profile.macroIndex[parent].state and self.profile.macroIndex[parent].state.cycleTimer) or GetRunningTime()
  else
    meta.cycleTimer = GetRunningTime()
  end
  if meta.position ~= 1 or type(cycles[meta.position]) ~= "number" then
    local mac = cycles[meta.position]
    local macType =  type(mac)
    if macType == "table" then 
      self.profile.macroIndex[mac[1]]:run(virtualEvent)
    elseif macType == "string" then
      if self.state.matchUp or self.state.matchDown then 
       tl.str:typingDelegator(tl.str:applyStringBuffer(mac,press,1),press) 
      end
    end
  end
  if vir ~= nil or dir == "up" then
    while type(cycles[meta.position + step]) == "number" do step = step + 1 end
    meta.position = meta.position + step
    if meta.position > finish or meta.position > #cycles then
      if not (init > finish and meta.position <= #cycles and meta.cyclesComplete == 1) then
        if meta.cyclesComplete < lim then
          meta.position = start
          meta.cyclesComplete = meta.cyclesComplete + 1
        else
          meta.cyclesComplete = lim + 1
          meta.position = #cycles
        end
      end
    end
  end
end

function CycleMacro:setCyclePosition(position,fam)
  if type(position) ~= "number" then return end
  local options,devices = self.options,self.profile.deviceState
  local cycleState = options.cancel > 0 and self.state.position
  tl.tbl:cycleIndex(#self.command,position,cycleState)
end

function CycleMacro:setCyclesCompleted(cycleName, number)
  if type(number)~="number" then return end
  self.state.cyclesComplete = number
end

function CycleMacro:control(name,positionOption,completedOption,fam)
  if positionOption == 0 then  self.state.position = nil
  else self:setCyclePosition(positionOption,fam) end
  if completedOption then self:setCyclesCompleted(completedOption,fam) end
end

return CycleMacro