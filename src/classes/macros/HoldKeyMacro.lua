local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local remove,type,insert,GetRunningTime = table.remove,type,table.insert,GetRunningTime

local HoldKeyMacro = MacroDefinition:new()---@class HoldKeyMacro:MacroDefinition

function HoldKeyMacro:parseInstructions()
  self.state = self.state or {}
  local options = self.options
  options.holdTime = options.holdTime or self.profile.config.defaultHold
  if not options.init then options.init = false end
  options.release = options.release or "auto"
  options.mode = options.mode or "relative"

  local processed = 0
  local offset = 0
  local command = {}

  local function finalIteration()
    if self.init then return end
    local lastN = remove(command)
    if type(lastN) == "number" then
      self.defaultDelay = lastN
      self.lastDelay = lastN
    else command[#command+1] = lastN end
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
      local elInstance = elClass:new(cmd,self.profile,nil,self.overrides,self.stack,self.sourceDevice)
      self:async(fetcher,(i-offset),el)    
    elseif cType == "string" or cType =="number" then
      command[i-offset] = cmd
      processed = processed+1
    else
      offset = offset +1
      processed = processed+1
    end
    if processed == #self.rawCommand then finalIteration() end
  end

end

---Auto execute function for staggered keys after timer runs out
---@param con (number|GenericMacro)[]
---@param startval number
---@param tID string
---@param fam string
---@param num number
function HoldKeyMacro:finalStagger(mac, startval, event)
  local fam,num = event.family,event.keyNum
  while GetRunningTime() < (startval + mac[1]) do--TODO:Probably a better way to do this,
    tl.coroutines:wait(self.profile.config.pollInterval)
  end
  if self.state.stagTimer ~= nil then
    self.state.stagTimer = nil
    self:subRun(mac[2], event)
  end
  return -1
end

---Timing function for held down keys
---@param cam HoldMacro
---@param buttonDirection string
---@param fam string
---@param event Event
function HoldKeyMacro:execute(event)
  local fam, num, dir,com,options,pID = event.family,event.keyNum,event.direction,self.command,self.options,self.pID
  if #com < 2 then return end
  local deflay = self.defaultDelay or options.holdTime
  local curlay = 0
  local lastLay = self.lastDelay
  local initas = options.init
  local lease = options.release
  local dirge = dir or self.profile.deviceState[fam].dir
  local comray = com
  local lastNum = -20
  local stagMode = options.mode
  local virtualEvent = event
  virtualEvent.virtualType = 4
  virtualEvent.virtualDirection = dir
  --TODO: move the creation of teh workTable into the parsing phase
  local workTab = {}
  for i = 1, #comray do
    local that = comray[i]
    if type(that) == "number" then
      deflay = that
      lastNum = i
    elseif initas and #workTab == 0 then
      initas = false
      deflay = 0
      if dirge == "down" then self:subRun(comray[i],virtualEvent) end
    else
      if #workTab ~= 0 then
        if stagMode == "absolute" then
          curlay = deflay
        else
          if stagMode ~= "additive" and i ~= lastNum + 1 then
            deflay = lastLay or options.defaultHold
          end
          curlay = curlay + deflay
        end
      end
      insert(workTab, {curlay, that})
    end
  end

  if dirge == "down" then
    if lease == "auto" then
      local seppy = remove(workTab)
      tl.coroutines:taskRun(pID, fam, num, self.finalStagger, self,seppy, GetRunningTime(), virtualEvent)
    end

    self.state.stagTimer = GetRunningTime()
  elseif dirge == "up" and self.state.stagTimer ~= nil then
    local timeNow = GetRunningTime() - self.state.stagTimer
    for g = 1, #workTab do
      local i = #workTab - g + 1
      local tabsi = workTab[i]
      if tabsi[1] < timeNow then self:subRun(tabsi[2],virtualEvent) break end
    end
    self.state.stagTimer = nil
  end
end

---@param evStr string[]|string
---@param event Event
function HoldKeyMacro:subRun(evStr,event)
  if type(evStr) == "table" then self.profile.macroIndex[evStr[1]]:run(event) 
  else tl.str:typingDelegator(evStr,self:keyPress(event)) end
end

function HoldKeyMacro:control(event)
  local dir = event.direction
  if dir and dir ~= "down" then return end
  self.state.stagTimer = nil
end

return HoldKeyMacro