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
  self.command = {}
  local processed = 0
  local offset = 0
  local command = {}

  local function finalIteration()
    if self.init then return end
    self.command = command
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
    if cType =="table"  and not tl.tbl:hasProperties(cmd) then
      local elClass---@type MacroDefinition
      if tl.tbl:isSingleTypeTable(cmd,"string")then cmd.type= (#cmd ==1 and "link") or "key" end
      local tableType = self.profile:identifyTableType(cmd)
      if tableType == "group" then
        elClass = tl:classImport('GroupMacro')
      elseif tableType == "macro" then elClass = self.profile:getMacroClass(cmd)  end
      if not elClass then return end
      local elInstance = elClass:new(cmd,self.profile,nil,self.overrides,self.stack)
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
  local parent = (virtParent and type(virtParent) ~= "number" and "_" .. virtParent) or virtParent or 999
  local currentPosition = ((rupture == 1 or rupture < 0) and self.profile.deviceState[fam].unstable) or self.profile.deviceState[fam].stable
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
  local virtualEvent = event
  virtualEvent.virtualType = directed
  virtualEvent.originator = virtualEvent.originator or self.pID
  virtualEvent.virtualDirection = dir
  
  if currentPosition[pID] == nil or (vir and dir == "down" and (self.profile.deviceState[fam].unstable[parent] == 1 
  or self.profile.deviceState[fam].stable[parent] == 1) and meta.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
    currentPosition[pID] = init
    meta.cyclesComplete = 1
    meta.cycleTimer = GetRunningTime()
  elseif rupture ~= 0 and rupture ~= 1 and (vir ~= nil or dir == "down") and (GetRunningTime() - meta.cycleTimer > abs(rupture)) then
    currentPosition[pID] = init
    meta.cyclesComplete = 1
  end

  if type(meta.cyclesComplete) == "number" and meta.cyclesComplete > lim then
    if quitter == "end" then
     return
    elseif quitter == "reset" then
      currentPosition[pID] = init
      meta.cyclesComplete = 1
    elseif type(quitter) == "table" then
      self.profile.macroIndex[quitter[1]]:run(virtualEvent)
      return
    end
  end
  if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
    meta.cycleTimer = self.profile.macroIndex[parent].state.cycleTimer
  else
    meta.cycleTimer = GetRunningTime()
  end
  if currentPosition[pID] ~= 1 or type(cycles[currentPosition[pID]]) ~= "number" then
    local mac = cycles[currentPosition[pID]]
    local macType =  type(mac)
    if macType == "table" then 
      self.profile.macroIndex[mac[1]]:run(virtualEvent)
    elseif macType == "string" then
      if self.state.matchUp or self.state.matchDown then 
       tl.str:typingDelegator(tl.str:applyStringBuffer(mac,fam,num,1),0,0,0,0,fam,num) 
      end
    end
  end
  if vir ~= nil or dir == "up" then
    while type(cycles[currentPosition[pID] + step]) == "number" do step = step + 1 end
    currentPosition[pID] = currentPosition[pID] + step
    if currentPosition[pID] > finish or currentPosition[pID] > #cycles then
      if not (init > finish and currentPosition[pID] <= #cycles and meta.cyclesComplete == 1) then
        if meta.cyclesComplete < lim then
          currentPosition[pID] = start
          meta.cyclesComplete = meta.cyclesComplete + 1
        else
          meta.cyclesComplete = lim + 1
          currentPosition[pID] = #cycles
        end
      end
    end
  end
end

function CycleMacro:cycleReset() --here, cycles for cycling sequences are reset, either for a specific one or all of them.
  for g = 1, #tl.stringPresets.families do
    local tk = tl.str:token(tl.stringPresets.families[g])
    self.profile.deviceState[tk].stable["_" .. self.pID] = nil
    self.profile.deviceState[tk].unstable["_" .. self.pID] = nil
  end
end

function CycleMacro:setCyclePosition(position,fam)
  if type(position) ~= "number" then return end
  local options,devices = self.options,self.profile.deviceState
  local cycleState = options.cancel > 0 and devices[fam].stable["_" .. self.pID] or devices[fam].unstable["_" .. self.pID]
  tl.tbl:cycleIndex(#self.command,position,cycleState)
end

function CycleMacro:setCyclesCompleted(cycleName, number)
  if type(number)~="number" then return end
  self.state.cyclesComplete = number
end

function CycleMacro:control(name,positionOption,completedOption,fam)
  if positionOption == 0 then  self:cycleReset()
  else self:setCyclePosition(positionOption,fam) end
  if completedOption then self:setCyclesCompleted(completedOption,fam) end
end

return CycleMacro