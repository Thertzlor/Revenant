local tl = ...---@type MainLibObject
local type,GetRunningTime,abs,huge = type, GetRunningTime,math.abs,math.huge
local MacroDefinition = tl:classImport('MacroDefinition')

---@class CycleMacro:MacroDefinition
---@field options {limit:number,cancel:number,inherit:string,finish:string,range:number[]}
---@field profile ProfileDefinition
local CycleMacro = MacroDefinition:new()

function CycleMacro:parseInstructions()
  if self.options.limit == 0 or not self.options.limit then self.options.limit = huge end 
  self.options.inherit = self.options.inherit or "all"
  self.options.cancel = self.options.cancel or 0
  self.options.finish = self.options.finish or "stall"
  local processed = 0
  local offset = 0
  local command = {}

  for i = 1, #self.rawCommand do
          self:async(function(tNum)
        local initId = elClass:awaitOwnId()
        if initId then self.subMacros[#self.subMacros+1] = initId end
        tempCommand[tNum] = {initId} or {0,sequenceDelays.randomActionDeviation}
        processed = processed + 1
        if processed == #self.rawOptions then finalIteration() end
      end,(i-offset))
  end

  self:finishInit()
end

---@param event Event
function CycleMacro:execute(event)
  local dir = event.direction
  local vir = event.virtualType
  local virtParent = event.originator
  local fam = event.family
  local num = event.keyNum
  local cycles = self.command
  local options = self.options
  local pID = self.pID
  if type(cycles) ~= "table" then return end
  local step = 1
  local lim = self.options.limit 
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
  local virtualEvent = {virtualType = directed,originator = pID,keyNum = num,family = fam, virtualDirection = dir}
  
  if currentPosition["_" .. pID] == nil or (vir and dir == "down" and (self.profile.deviceState[fam].unstable[parent] == 1 
  or self.profile.deviceState.deviceState[fam].stable[parent] == 1) and self.state.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
    currentPosition["_" .. pID] = init
    self.state.cyclesComplete = 1
    self.state.cycleTimer = GetRunningTime()
  elseif rupture ~= 0 and rupture ~= 1 and (vir ~= nil or dir == "down") and (GetRunningTime() - cycles._meta.cycleTimer > abs(rupture)) then
    currentPosition["_" .. pID] = init
    self.state.cyclesComplete = 1
  end

  if type(self.state.cyclesComplete) == "number" and self.state.cyclesComplete > lim then
    if quitter == "end" then
     return
    elseif quitter == "reset" then
      currentPosition["_" .. pID] = init
      self.state.cyclesComplete = 1
    elseif type(quitter) == "table" then
      self.profile.macroIndex[quitter[1]]:run(virtualEvent)
      return
    end
  end
  if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
    self.state.cycleTimer = self.profile.macroIndex[parent].state.cycleTimer
  else
    self.state.cycleTimer = GetRunningTime()
  end
  if currentPosition["_" .. pID] ~= 1 or type(cycles[currentPosition["_" .. pID]]) ~= "number" then
    local mac = cycles[currentPosition["_" .. pID]]
    if type(mac) == "table" and not mac.type then mac.type = options.cast end
    self.profile.macroIndex[mac[1]]:run(virtualEvent)
  end
  if vir ~= nil or dir == "up" then
    while type(cycles[currentPosition["_" .. pID] + step]) == "number" do step = step + 1 end
    currentPosition["_" .. pID] = currentPosition["_" .. pID] + step
    if currentPosition["_" .. pID] > finish or currentPosition["_" .. pID] > #cycles then
      if not (init > finish and currentPosition["_" .. pID] <= #cycles and self.state.cyclesComplete == 1) then
        if cycles._meta.cyclesComplete < lim then
          currentPosition["_" .. pID] = start
          cycles._meta.cyclesComplete = self.state.cyclesComplete + 1
        else
          cycles._meta.cyclesComplete = lim + 1
          currentPosition["_" .. pID] = #cycles
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