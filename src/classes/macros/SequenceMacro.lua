local tl = ...---@type MainLibObject
local type,running,huge,ceil,next, pairs,remove = type,coroutine.running,huge,math.ceil,next,pairs,table.remove
local MacroDefinition = tl:classImport('MacroDefinition')
---@alias SequenceOptions {play:'"normal"'|'"toggle"'|'"hold"'|'"phold"'|'"ptoggle"',actionDelay:number,keyDelay:number,loop:number}

local SequenceMacro = MacroDefinition:new()---@class SequenceMacro:MacroDefinition

function SequenceMacro:parseInstructions()
  self.command = {{},{}}
  self.options.play = self.options.play or "normal"
  self.options.stack = self.options.stack or self.profile.config.defaultStacking
  local offset = 0
  local processed = 0
  local tempCommand = {}
  local sequenceDelays = {}
  local delayTable = {}
  local defOrder = {"actionDelay","keyDelay","actionVariance","keyVariance"}
  for i = 1, #defOrder do local def = defOrder [i]
    sequenceDelays[def] = self.options[def] or self.profile.config[def]
  end

  ---@param options OptionsCollection
  local function stringOutputGenerator(string,defaults)
    return function(press) for k, v in pairs(defaults) do press[k] = v end
    tl.str:typingDelegator(string,press) end 
  end 

  local function delayGenerator(time, deviation) return function() tl.coroutines:wait(time,deviation) end end
  
  local function finalIteration()
    if self.init then return end
    local waitCache = 0
    for i = 1, #tempCommand do local cmd, cmdNext = tempCommand[i],tempCommand[i+1]
      if type(cmd) == "table" and type(cmd[1]) == "number" then
        waitCache = waitCache + cmd[1]
        if not cmdNext or type(cmdNext) ~= "table" or type(cmdNext[1]) ~= "number" or not tl.tbl:sameContent(cmd[2],cmdNext[2]) then
          self.command[1][#self.command[1]+1] = delayGenerator(waitCache,cmd[2])
          self.command[2][#self.command[2]+1] = delayTable[i]
          waitCache = 0
        end
      else 
        self.command[1][#self.command[1]+1] = cmd 
        self.command[2][#self.command[2]+1] = delayTable[i]
      end
    end
    for i = 1, #self.command[1] do local finCm = self.command[1][i]
      if type(finCm) ~= "function" and finCm._ref then local ref = finCm._ref
        self.command[1][i] = {ref}
        self:async(self.replaceWithReferenceId,self,ref,i,self.command[1],true)
      end
    end
    self:finishInit()
  end

  if type(self.rawCommand) == "string" then 
    self.command = {{stringOutputGenerator(self.rawCommand,sequenceDelays)},sequenceDelays} 
    return finalIteration()
  end

  local function fetchSubMacro(tNum,class)
    local initId = class:awaitOwnId()
    if initId then self.subMacros[#self.subMacros+1] = initId end
    tempCommand[tNum] = {initId}
    processed = processed + 1
    if processed == #self.rawCommand then finalIteration() end
  end

  for i = 1, #self.rawCommand do local el, elNext = self.rawCommand[i],self.rawCommand[i+1]
    delayTable[i] = tl.helperUtils.deepCopy(sequenceDelays)
    if type(el) == "table" then 
      if #el == 1 and  type(el[1]) == "string" and not tl.tbl:hasProperties(el) then
        processed = processed + 1
        tempCommand[i-offset] = {_ref=el[1]}
      elseif not (tl.tbl:isSingleTypeTable(el,"number") and not tl.tbl:hasProperties(el))then
        if(tl.tbl:isSingleTypeTable(el,"string") and not tl.tbl:hasProperties(el)) then el.type= "key" end
        local elClass---@type MacroDefinition
        local tableType = self.profile:identifyTableType(el)
        if tableType == "group" then
          if (el.loop or el.l) then elClass = tl:classImport('SequenceMacro')
          else elClass = tl:classImport('GroupMacro') end
        elseif tableType == "macro" then elClass = self.profile:getMacroClass(el)  end
        if not elClass then return end
        local autoDefaults = {}
        local elInstance = elClass:new(el,self.profile,sequenceDelays,self.overrides,self.stack,self.sourceDevice)
        self:async(fetchSubMacro,(i-offset),elInstance)
      elseif tl.tbl:isSingleTypeTable(el,"number") and not tl.tbl:hasProperties(el) then
        offset=offset+1
        processed = processed + 1
        for i = 1, #defOrder do local def = defOrder[i]
          if el[i] and el[i] >= 0 then sequenceDelays[def] = el[i]
          elseif el[i] == -1 then sequenceDelays[def] = self.options[def] or self.profile.config[def] 
          elseif el[i] == -2 then sequenceDelays[def] = self.profile.config[def] end
        end
       delayTable[i] = tl.helperUtils.deepCopy(sequenceDelays)
      end
    elseif type(el) == "number" then
      tempCommand[i-offset] = {el,sequenceDelays.actionVariance}
      processed = processed + 1
    elseif type(el) == "string" then
      processed = processed + 1
      tempCommand[i-offset] = stringOutputGenerator(el,sequenceDelays)
    else
      offset=offset+1
      processed = processed + 1
    end
    if processed == #self.rawCommand then finalIteration() end
  end
end

---Main function for executing macro sequences
---@param event Event
---@return number
function SequenceMacro:execute(event)
  self.state = self.state or {}
  local name = self.pID
  local dir = event.direction
  local vir = event.virtualType
  local fam = event.family
  local mos = event.keyNum
  local descPlay = self.direction
  local sequence = self.command[1]
  local delays = self.command[2]---@type OptionsCollection
  local descDir = descPlay or "normal"
  local mode = self.options.play
  local virtualEvent = self:virtualize(event,1)
  local press = self:keyPress(event)
  if ((mode == "normal" or mode == "toggle" or mode == "ptoggle") and(dir ~= nil and dir ~= "down") and descDir ~= "up") 
  or (descDir == "up" and dir == "down") then return -1 end

  local ride = self.options.stack
  local mouseN = mos or 0
  if tl.coroutines.taskList[name] ~= nil then
    if mode == "toggle" or mode == "hold" then
      tl.coroutines:taskAbort(name, fam, mouseN)
    elseif (mode == "ptoggle" or mode == "phold") and tl.coroutines.taskList[name].paused == false then
      tl.coroutines:tPause(name)
    elseif (mode == "ptoggle" or mode == "phold") then
      tl.coroutines:tRes(name)
    elseif mode == "normal" and tl.coroutines.taskList.paused == false then
      if ride == 0 then
        tl.coroutines:taskAbort(name, fam, mouseN)
        tl.coroutines:taskRun(name, fam, mouseN, self.execute,self, virtualEvent)
      elseif ride == 2 then
        tl.coroutines:seQueue(name, sequence, nil, dir, descDir, mouseN, vir, fam)
      elseif ride == 1 then
        tl.coroutines:taskAbort(name, fam, mouseN)
      end
    end
    return -1
  elseif dir == "up" and descDir ~= "up" then return -1 end
  --^^ dealing with toggling sequences
  if running() == nil and vir ~= 1 and vir ~= 3 and name and tl.coroutines.taskList[self.pID] == nil 
  and tl.coroutines.taskList[name] == nil and not tl.scriptStates.exitingScript then --launching coroutines
    tl.coroutines:taskRun(name, fam, mouseN, self.execute, self, virtualEvent)
    return -1
  end

  local looper = self.options.loop or 1
  local loopNum = #sequence * looper
  local loopStart = (self.state.seqPosition) or 1
  if looper == 0 then return -1
  elseif looper < 0 then loopNum = huge end
  for g = loopStart, loopNum do
    local i = g - (#sequence * (ceil((g / #sequence - 1) + 1) - 1))
    local obj = sequence[i]
    if i ~= 1 then tl.coroutines:wait(delays[i].actionDelay, delays[i].actionVariance) end
    if type(obj) == "table"then    
      self.profile.macroIndex[obj[1]]:run(virtualEvent)
    elseif type(obj) == "function" then obj(press) end
  end

  return -1
end

function SequenceMacro:control(option,event)
  local setting = option
  local controls ={
    pause="tPause",
    cancel="taskAbort",
    resume="tRes",
    toggle = (tl.polling:taskRunning(self.pID,true) and "tPause") or "tRes"
  }
  setting = setting or self.profile.config.defaultSequenceControl or "cancel" 
  tl:put(controls[setting])
  --TODO: Is this always the correct pID?
  tl.coroutines[controls[setting]](tl.coroutines,self.pID)
end

return SequenceMacro