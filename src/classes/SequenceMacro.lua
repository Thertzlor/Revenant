local tl = ...---@type MainLibObject
local type,running,huge,ceil = type,coroutine.running,huge,math.ceil
local BaseMacro = tl:classImport('BaseMacro')

---@alias SequenceOptions {play:'"normal"'|'"toggle"'|'"hold"'|'"phold"'|'"ptoggle"',actionDelay:number,keyDelay:number,loop:number}

---@class SequenceMacro:BaseMacro
---@field profile ProfileDefinition
---@field options  SequenceOptions
local SequenceMacro = BaseMacro:new()
function SequenceMacro:parseSubMacros()
  for i = 1, #self.command do local el = self.command[i]
    if type(el) == "table" and not tl.tbl:isSingleTypeTable(ev,"number")then

    end
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
  local seqProperties = {}
  local seqModifier = {
    {"delayer", "actionDelay"},
    {"dekayer", "keyDelay"},
    {"actionDeviator", "randomActionDeviation"},
    {"keyDeviator", "randomKeyDeviation"}
  }

  for m = 1, #seqModifier do
    local mod = seqModifier[m]
    seqProperties[mod[1]] = self.options[mod[2]] or self.profile.config[mod[2]]
  end

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
        tl.str:typingDelegator(
          tl.str:applyStringBuffer(obj, fam, mouseN, 1),
          seqProperties.delayer,
          seqProperties.dekayer,
          seqProperties.actionDeviator,
          seqProperties.keyDeviator,
          fam,
          mouseN
        )
      elseif type(obj) == "table" then
        if tl.tbl:hasProperties(obj) == false then
          if tl.tbl:isSingleTypeTable(obj, "string") then
            if #obj == 1 then
             self.profile.macroIndex[obj[1]]:execute(virtualEvent)
            else
              self:simpleKey(obj, nil, 0, 1, obj.pID, seqProperties.delayer, seqProperties.keyDeviator, fam, mouseN)
            end
          elseif tl.tbl:isSingleTypeTable(obj, "number") then
            for n = 1, #seqModifier do
              local mod = seqModifier[n]
              if obj[n] ~= nil and obj[n] >= 0 then
                seqProperties[mod[1]] = obj[n]
              elseif obj[n] == -1 then
                seqProperties[mod[1]] = tg[mod[2]] or tl.config[mod[2]]
              elseif obj[n] == -2 then
                seqProperties[mod[1]] = tl.config[mod[2]]
              end
            end
            denyDelay = true
          end
        else
          obj.delay = obj.delay or seqProperties.delayer
          obj.kdelay = obj.kdelay or seqProperties.dekayer
          if tg[i].type == nil and tg[i].loop ~= nil then
            tg[i].type = "s"
          elseif i ~= #tg and tg[i].type == nil and #tg[i] == 1 and type(tg[i][1]) == "string" then
            tg[i].type = "kw"
            denyDelay = true
          end
          tl.bindings:launchMacro(mouseN, fam, tg[i], 1)
        end
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