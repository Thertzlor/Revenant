local tl = ...---@type MainLibObject
local type,GetRunningTime,abs,huge = type, GetRunningTime,math.abs,math.huge
local BaseMacro = tl:classImport('BaseMacro')

---@class CycleMacro:BaseMacro
---@field options {limit:number,cancel:number,inherit:string,finish:string,range:number[]}
---@field profile ProfileDefinition
local CycleMacro = BaseMacro:new()

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
  local lim =  (options.limit == 0 and huge) or self.options.limit or huge
  local inherit = options.inherit or "all"
  local rupture = options.cancel or 0
  local parent = (virtParent and type(virtParent) ~= "number" and "_" .. virtParent) or virtParent or 999
  local currentPosition = ((rupture == 1 or rupture < 0) and self.profile.deviceState[fam].unstable) or self.profile.deviceState[fam].stable
  local quitter = options.finish or "stall"
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

function CycleMacro:parseSubMacros()
--self:finishInit()
end

return CycleMacro