local tl = ...---@type MainLibObject
local type,running,huge,ceil,next, pairs = type,coroutine.running,huge,math.ceil,next,pairs
local BaseMacro = tl:classImport('BaseMacro')

---@alias SequenceOptions {play:'"normal"'|'"toggle"'|'"hold"'|'"phold"'|'"ptoggle"',actionDelay:number,keyDelay:number,loop:number}

---@class SequenceMacro:BaseMacro
---@field profile ProfileDefinition
---@field options  SequenceOptions
local SequenceMacro = BaseMacro:new()
function SequenceMacro:parseSubMacros()
  self.command = {}
  local offset = 0
  local processed = 0
  local tempCommand = {}
  local sequenceDelays = {}
  local defOrder = {"actionDelay","keyDelay","randomActionDeviation", "randomKeyDeviation"}
  for i = 1, #defOrder do local def = defOrder [i]
    sequenceDelays[def] = self.options[def] or self.profile.config[def]
  end

  ---@param options OptionsCollection
  local function stringOutputGenerator(string,defaults)
    local options = {}
    for k, v in pairs(defaults) do options[k] = v end
    return function(fam,mouseN) tl.str:typingDelegator(tl.str:applyStringBuffer(string, fam, mouseN, 1),options.actionDelay,options.keyDelay,options.randomActionDeviation,options.randomKeyDeviation,fam,mouseN) end 
  end 

  local function delayGenerator(time, deviation) return function() tl.coroutines:wait(time,deviation) end end
  
  local function finalIteration()
    local waitCache = 0
    for i = 1, #tempCommand do local cmd, cmdNext = tempCommand[i],tempCommand[i+1]
      if type(cmd) == "table" and type(cmd[1]) == "number" then
        waitCache = waitCache + cmd[1]
        if not cmdNext or type(cmdNext) ~= "table" or type(cmdNext[1]) ~= "number" or not tl.tbl:sameContent(cmd[2],cmdNext[2]) then
          self.command[#self.command+1] = delayGenerator(waitCache,cmd[2])
          waitCache = 0
        end
      else self.command[#self.command+1] = cmd end
    end
    self:finishInit()
  end

  if type(self.rawCommand) == "string" then 
    self.command = {stringOutputGenerator(self.rawCommand,sequenceDelays)} 
    return finalIteration()
  end

  for i = 1, #self.rawCommand do local el, elNext = self.rawCommand[i],self.rawCommand[i+1]
    if type(el) == "table" and not (tl.tbl:isSingleTypeTable(el,"number") and not tl.tbl:hasProperties(el))then
      ---@type BaseMacro
      local elClass
      if(tl.tbl:isSingleTypeTable(el,"string") and not tl.tbl:hasProperties(el)) then el.type= (#el ==1 and "link") or "key" end
      local tableType tl.tbl:identifyTableType(el)
      if tableType == "group" then
        if el.loop ~=nil or el.l ~=nil then elClass = tl:classImport('SequenceMacro')
        else elClass = tl:classImport('GroupMacro') end
      elseif tableType == "macro" then elClass = tl.bindings:getMacroClass(el)  end
      if not elClass then return end
      local autoDefaults = {}
      local elInstance = elClass:new(el,self.profile,sequenceDelays,self.overrides,self.stack)
      self:async(function(tNum)
        local initId = elClass:awaitOwnId()
        if initId then self.subMacros[#self.subMacros+1] = initId end
        tempCommand[tNum] = {initId} or {0,sequenceDelays.randomActionDeviation}
        processed = processed + 1
        if processed == #self.rawOptions then finalIteration() end
      end,(i-offset))
    elseif tl.tbl:isSingleTypeTable(el,"number") and not tl.tbl:hasProperties(el) then
      offset=offset+1
      processed = processed + 1
      for i = 1, #defOrder do local def = defOrder[i]
        if el[i] and el[i] >= 0 then sequenceDelays[def] = el[i]
        elseif el[i] == -1 then sequenceDelays[def] = self.options[def] or self.profile.config[def] 
        elseif el[i] == -2 then sequenceDelays[def] = self.profile.config[def] end
      end
    elseif type(el) == "number" then
      tempCommand[i-offset] = {el,sequenceDelays.randomActionDeviation}
      processed = processed + 1
    elseif type(el) == "string" then
      processed = processed + 1
      tempCommand[i-offset] = stringOutputGenerator(el,sequenceDelays)
    else
      offset=offset+1
      processed = processed + 1
    end
    if processed == #self.rawOptions then finalIteration() end
  end
end

---Main function for executing macro sequences
---@param targ SequenceMacro
---@param name string
---@param dir string
---@param descPlay string
---@param mos number
---@param vir number
---@param fam string
---@return number
function SequenceMacro:execute(event)
  self.state = self.state or {}
  local name = self.pID
  local dir = event.dir
  local vir = event.vir
  local fam = event.family
  local mos = event.mos
  local tg = self.command
  local descDir = descPlay or "normal"
  local mode = self.options.play or "normal"
  local virtualEvent = event
  virtualEvent.vir = 1
  if
    ((mode == "normal" or mode == "toggle" or mode == "ptoggle") and (dir ~= nil and dir ~= "down") and descDir ~= "up") or
      (descDir == "up" and dir == "down")
   then
    return -1
  end
  local ride = self.options.stack or self.profile.config.defaultStacking
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
        tl.coroutines:taskRun(name, fam, mouseN, self.keySequence,self, tg, nil, dir, descDir, mouseN, vir, fam)
      elseif ride == 2 then
        tl.coroutines:seQueue(name, tg, nil, dir, descDir, mouseN, vir, fam)
      elseif ride == 1 then
        tl.coroutines:taskAbort(name, fam, mouseN)
      end
    end
    return -1
  elseif dir == "up" and descDir ~= "up" then
    return -1
  end
  --^^ dealing with toggling sequences
  if
    running() == nil and vir ~= 1 and vir ~= 3 and name and tl.coroutines.taskList[tg.pID] == nil and tl.coroutines.taskList[name] == nil and
     not tl.scriptStates.exitingScript
   then --launching coroutines
    tl.coroutines:taskRun(name, fam, mouseN, self:execute, self, tg, nil, dir, descDir, mouseN, vir, fam)
    return -1
  end

  if type(tg) == "table" then
    local looper = tg.loop or 1
    local loopNum = #tg * looper
    local loopStart = (self.state.seqPosition) or 1
    if looper == 0 then
      return -1
    elseif looper < 0 then
      loopNum = huge
    end
    local noWait = false
    for g = loopStart, loopNum do
      local i = g - (#tg * (ceil((g / #tg - 1) + 1) - 1))
      local obj = tg[i]
      local denyDelay = false
      if i ~= 1 and noWait == false and type(obj) ~= "number" then
        tl.coroutines:wait(seqProperties.delayer, seqProperties.actionDeviator)
      elseif noWait == true then
        noWait = false
      end
      if type(obj) == "string" then
        tl.str:typingDelegator(tl.str:applyStringBuffer(obj, fam, mouseN, 1),seqProperties.delayer,seqProperties.dekayer,seqProperties.actionDeviator,seqProperties.keyDeviator,fam,mouseN)
      elseif type(obj) == "table" then
        self.profile.macroIndex[obj[1]]:execute(virtualEvent)
      elseif type(obj) == "number" then
        noWait = true
        tl.coroutines:wait(obj, seqProperties.actionDeviator)
      end
      while denyDelay and type(tg[i + 1]) == "number" do
        g = g + 1
        i = g - (#tg * (ceil((g / #tg - 1) + 1) - 1))
      end
    end
  elseif type(tg) == "string" then
    tl.str:typingDelegator(tl.str:applyStringBuffer(tg, fam, mouseN, 1),seqProperties.delayer,seqProperties.dekayer,seqProperties.actionDeviator,seqProperties.keyDeviator,fam,mouseN)
  end

  return -1
end

return SequenceMacro