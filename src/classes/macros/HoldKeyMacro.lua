local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local remove,type,insert,GetRunningTime = table.remove,type,table.insert,GetRunningTime
---@class HoldKeyMacro:MacroDefinition
local HoldKeyMacro = MacroDefinition:new()

function HoldKeyMacro:parseInstructions()
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
      local tableType self.profile:identifyTableType(cmd)
      if tableType == "group" then
        elClass = tl:classImport('GroupMacro')
      elseif tableType == "macro" then elClass = self.profile:getMacroClass(cmd)  end
      if not elClass then return end
      local elInstance = elClass:new(cmd,self.profile,nil,self.overrides,self.stack)
      self:async(fetcher,(i-offset),el)    
    elseif cType == "string" then
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
function HoldKeyMacro:finalStagger(macroID, num, startval, tID, event)
  local fam,num = event.family,event.keyNum
  while GetRunningTime() < (startval + con[1]) do
    tl.coroutines:wait(self.profile.config.pollInterval)
  end
  if self.state.stagTimer ~= nil then
    self.state.stagTimer = nil
    tl.validator:launchMacro(num, fam, con[2], 4)
  end
  return -1
end

---Timing function for held down keys
---@param cam HoldMacro
---@param buttonDirection string
---@param fam string
---@param event Event
function HoldKeyMacro:execute(event)
  local fam, num, buttonDirection = event.family,event.keyNum,event.direction
  local com = self.command
  local options = self.options
  if type(com) ~= "table" or #com < 2 then
    return
  end
  local deflay = options.holdTime
  local curlay = 0
  local lastLay
  local initas = options.init
  local lease = options.release
  local dirge = buttonDirection or self.profile.deviceState[fam].dir
  local comray = com
  local lastNum = -20
  local stagMode = options.mode
  local commy = tl.tbl:intersect(com, {})
  local lastN = remove(commy)
  if type(lastN) == "number" then
    comray = commy
    deflay = lastN
    lastLay = lastN
  end

  local workTab = {}
  for i = 1, #comray do
    local that = comray[i]
    if type(that) == "number" then
      deflay = that
      lastNum = i
    elseif initas and #workTab == 0 then
      initas = false
      deflay = 0
      if dirge == "down" then
        tl.validator:launchMacro(num, fam, comray[i], 4)
      end
    else
      if #workTab ~= 0 then
        if stagMode == "absolute" then
          curlay = deflay
        else
          if stagMode ~= "additive" and i ~= lastNum + 1 then
            deflay = lastLay or com.defaultHold
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
      if not seppy.type then
        seppy.type = workTab.cast
      end
      tl.coroutines:taskRun(pID, fam, num, self.finalStagger, self, GetRunningTime(), event, fam, num)
    end

    self.state.stagTimer = GetRunningTime()
  elseif dirge == "up" and self.state.stagTimer ~= nil then
    local timeNow = GetRunningTime() - self.state.stagTimer
    for g = 1, #workTab do
      local i = #workTab - g + 1
      local tabsi = workTab[i]
      if tabsi[1] < timeNow then
        if not tabsi[2].type then
          tabsi[2].type = workTab.cast
        end
        tl.validator:launchMacro(num, fam, tabsi[2], 4)
        break
      end
    end
    self.state.stagTimer = nil
  end
end

function HoldKeyMacro:control(event)
  local dir = event.direction
  if dir and dir ~= "down" then return end
  self.state.stagTimer = nil
end

return HoldKeyMacro