---@type MainLibObject
local tl = ...
local ceil, huge, abs, GetRunningTime, type, insert, remove, unpack, OutputDebugMessage, running =
  math.ceil,math.huge,math.abs,GetRunningTime,type,table.insert,table.remove,unpack,OutputDebugMessage,coroutine.running
local toggled
-->>>>> Functions controlling Macros that are run on key press ========================================

local function _fetchMacro(key)
  while tl.macroIndex[key]._meta.redirect do
    key = tl.macroIndex[key]._meta.redirect
  end
  return tl.macroIndex[key]
end

---Auto execute function for staggered keys after timer runs out
---@param con (number|GenericMacro)[]
---@param startval number
---@param tID string
---@param fam string
---@param num number
local function _finalStagger(con, startval, tID, fam, num)
  while GetRunningTime() < (startval + con[1]) do
    tl.wait(tl.config.pollInterval)
  end
  if tl.macroIndex[tID]._meta.stagTimer ~= nil then
    tl.macroIndex[tID]._meta.stagTimer = nil
    tl.launchMacro(num, fam, con[2], 4)
  end
  return -1
end

---Alternate waiting function for multi click keys
---@param key string
---@param endMoment number
---@param id string
---@param fam string
---@param num number
local function _altTimer(key, endMoment, _, _, fam, num)
  key._meta.multiTimer = endMoment
  while GetRunningTime() < endMoment do
    tl.wait(tl.config.pollInterval)
  end
  key._meta.multiTimer = nil
  if key._meta.multiClick ~= nil and (key.mode ~= "stack" or not key.mode) then
    tl.launchMacro(num, fam, key[key._meta.multiClick], 4)
  end
  key._meta.multiClick = nil
  return -1
end

local function _timer(key, endMoment, interval, curNum, fam, num)
  if curNum > #key then
    curNum = #key
  end
  key._meta.multiTimer = endMoment
  while GetRunningTime() < endMoment and key._meta.multiClick == curNum do
    tl.wait(tl.config.pollInterval)
  end
  if key._meta.multiClick == curNum or curNum == #key then
    if key.mode ~= "stack" then
      for i = 1, curNum do
        tl.launchMacro(num, fam, key[i], 4)
      end
    else
      tl.launchMacro(num, fam, key[curNum], 4)
    end
    key._meta.multiTimer = nil
    key._meta.multiClick = nil
  else
    _timer(key, (GetRunningTime() + interval), curNum, fam, num)
  end
  return -1
end

---Executes functions (recursively)
---@param func function
function tl.executeFunction(func)
  if type(func) == "string" then
    _G[func]()
  elseif type(func) == "table" then
    local namu = func[1]
    remove(func, 1)
    _G[namu](unpack(func))
    insert(func, 1, namu)
  end
end

---Handles the default key functions, called by key name or as simple sequence.
---@param tg string|table<string>
---@param dir string
---@param triggerMode number
---@param vir number
---@param bId string
---@param del number
---@param dev number
---@param fam string
---@param num number
function tl.simpleKey(tg, dir, triggerMode, vir, bId, del, dev, fam, num)
  local keyString = tg
  if type(keyString) == "table" and #keyString == 1 then
    keyString = keyString[1]
  end
  local releaseToggle = false
  if (running() and triggerMode == 0) or (vir and triggerMode == 0 and (vir == 1 or dir == nil)) then
    if type(keyString) == "string" and (tl.state[fam]["_b" .. num] or not (tl.keyboardDefinition[keyString] or tl.logiKeys[keyString])) then
      tl.typingDelegator(tl.applyStringBuffer(keyString, fam, num, 1), nil, del, nil, dev, fam, num)
    else
      if type(keyString) ~= "table" then keyString = {keyString}end
      tl.bothRay(keyString, del, dev, fam, num)
      releaseToggle = true
    end
  else
    if
      (dir == "down" and triggerMode == 0) or triggerMode == 1 or (triggerMode == 4 and (dir == "down" or vir)) or
        (triggerMode == 3 and toggled["_" .. bId] == nil)
     then
      if triggerMode == 3 then
        toggled["_" .. bId] = 1
      elseif triggerMode == 4 then
        local wrapperTargets = {key=tl.state[fam]["_b" .. num], family = tl.state[fam], global=tl.state}
        local releaseWrapper = wrapperTargets[(type(tg) == "table" and tg.scope) or "key"]
        if not releaseWrapper then 
          tl.state[fam]["_b"..num] = {}
          releaseWrapper = tl.state[fam]["_b"..num]
        end 
        if not releaseWrapper.wrapperContent then
          releaseWrapper.wrapperContent = {}
        end
        releaseWrapper.wrapperContent[#releaseWrapper.wrapperContent + 1] = keyString
      end
      if type(keyString) == "string" then
        tl.press(tl.applyStringBuffer(keyString, fam, num), del, dev, fam, num)
      elseif type(keyString) == "table" then
        tl.preRay(keyString, del, dev, fam, num)
      end
    elseif
      (dir == "up" and triggerMode == 0) or triggerMode == 2 or (dir == "down" and triggerMode == 3 and toggled["_" .. bId] ~= nil)
     then
      if triggerMode ~= 5 then
        releaseToggle = true
      end
      if type(keyString) == "string" then
        tl.release(tl.applyStringBuffer(keyString, fam, num, 1), del, dev)
      elseif type(keyString) == "table" then
        if keyString.unreverse ~= nil then
          tl.reverseTable(keyString)
        end
        tl.relRay(keyString, del, dev)
        if keyString.unreverse ~= nil then
          tl.reverseTable(keyString)
        end
      end
      if triggerMode == 3 then
        toggled["_" .. bId] = nil
      end
    end
  end
  if releaseToggle then
    tl.autoRelease(fam, num, del, dev)
  end
end

---Erases button log history
---@param num number
function tl.histoRase(num)
  if type(num) ~= "number" or num < 1 then
    tl.wipe(tl.lastKeysDown)
  else
    for _ = 1, num + 1 do
      remove(tl.lastKeysDown)
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
function tl.keySequence(targ, name, dir, descPlay, mos, vir, fam)
  local tg = targ
  local descDir = descPlay or "normal"
  local mode = tg.play or "normal"
  if
    ((mode == "normal" or mode == "toggle" or mode == "ptoggle") and (dir ~= nil and dir ~= "down") and descDir ~= "up") or
      (descDir == "up" and dir == "down")
   then
    return -1
  end
  local ride = tg.stack or tl.config.defaultStacking
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
    seqProperties[mod[1]] = tg[mod[2]] or tl.config[mod[2]]
  end

  if tl.taskList[name] ~= nil then
    if mode == "toggle" or mode == "hold" then
      tl.taskAbort(name, fam, mouseN)
    elseif (mode == "ptoggle" or mode == "phold") and tl.taskList[name].paused == false then
      tl.tPause(name)
    elseif (mode == "ptoggle" or mode == "phold") then
      tl.tRes(name)
    elseif mode == "normal" and tl.taskList.paused == false then
      if ride == 0 then
        tl.taskAbort(name, fam, mouseN)
        tl.taskRun(name, fam, mouseN, tl.keySequence, tg, nil, dir, descDir, mouseN, vir, fam)
      elseif ride == 2 then
        tl.seQueue(name, tg, nil, dir, descDir, mouseN, vir, fam)
      elseif ride == 1 then
        tl.taskAbort(name, fam, mouseN)
      end
    end
    return -1
  elseif dir == "up" and descDir ~= "up" then
    return -1
  end
  --^^ dealing with toggling sequences
  if
    running() == nil and vir ~= 1 and vir ~= 3 and name and tl.taskList[tg.pID] == nil and tl.taskList[name] == nil and
      tl.exitingScript == 0
   then --launching coroutines
    tl.taskRun(name, fam, mouseN, tl.keySequence, tg, nil, dir, descDir, mouseN, vir, fam)
    return -1
  end

  if type(tg) == "table" then
    local looper = tg.loop or 1
    local loopNum = #tg * looper
    local loopStart = (tg._meta and tg._meta.seqPosition) or 1
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
        tl.wait(seqProperties.delayer, seqProperties.actionDeviator)
      elseif noWait == true then
        noWait = false
      end
      if type(obj) == "string" then
        tl.typingDelegator(
          tl.applyStringBuffer(obj, fam, mouseN, 1),
          seqProperties.delayer,
          seqProperties.dekayer,
          seqProperties.actionDeviator,
          seqProperties.keyDeviator,
          fam,
          mouseN
        )
      elseif type(obj) == "table" then
        if tl.hasProperties(obj) == false then
          if tl.isSingleTypeTable(obj, "string") then
            if #obj == 1 then
              obj.type = "l"
              obj.keepExisting = 1
              obj.delay = obj.delay or seqProperties.delayer
              obj.kdelay = obj.kdelay or seqProperties.dekayer
              tl.launchMacro(mouseN, fam, tg[i], 1)
            else
              tl.simpleKey(obj, nil, 0, 1, obj.pID, seqProperties.delayer, seqProperties.keyDeviator, fam, mouseN)
            end
          elseif tl.isSingleTypeTable(obj, "number") then
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
          tl.launchMacro(mouseN, fam, tg[i], 1)
        end
      elseif type(obj) == "number" then
        noWait = true
        tl.wait(obj, seqProperties.actionDeviator)
      end
      while denyDelay and type(tg[i + 1]) == "number" do
        g = g + 1
        i = g - (#tg * (ceil((g / #tg - 1) + 1) - 1))
      end
    end
  elseif type(tg) == "string" then
    tl.typingDelegator(tl.applyStringBuffer(tg, fam, mouseN, 1),seqProperties.delayer,seqProperties.dekayer,seqProperties.actionDeviator,seqProperties.keyDeviator,fam,mouseN)
  end

  return -1
end

---main function for cycling sequences
---@param cycleTarget CycleMacro
---@param dir string
---@param vir number
---@param virtParent string
---@param fam string
---@param num number
function tl.keyCycle(cycleTarget, dir, vir, virtParent, fam, num)
  local tar = cycleTarget
  if type(tar) ~= "table" then
    return
  end
  local step = 1
  local lim =  (tar.limit == 0 and huge) or tar.limit or huge
  local inherit = tar.inherit or "all"
  local rupture = tar.cancel or 0
  local parent = (virtParent and type(virtParent) ~= "number" and "_" .. parent) or virtParent or 999
  local currentPosition = ((rupture == 1 or rupture < 0) and tl.state[fam].unstable) or tl.state[fam].stable
  local quitter = tar.finish or "stall"
  local start = 1
  local init = start
  local finish = #tar
  if type(tar.range) == "table" and tl.isSingleTypeTable(tar.range, "number") then
    for j = 1, #tar.range do
      if tar.range[j] <= 0 then
        tar.range[j] = #tar + tar.range[j]
      end
    end
    if tar.range[2] and tar.range[2] < #tar then
      init = tar.range[2]
    end
    if tar.range[1] < #tar then
      start = tar.range[1]
    end
    finish = tar.range[3] or finish
    if finish > #tar then finish = #tar end
  end

  local directed = vir and 2 or 3
  if
    currentPosition["_" .. tar.pID] == nil or
      (vir and dir == "down" and (tl.state[fam].unstable[parent] == 1 or tl.state[fam].stable[parent] == 1) and
        tl.macroIndex[parent]._meta.cyclesComplete == 1 and
        inherit ~= "timing" and
        inherit ~= "none")
   then
    currentPosition["_" .. tar.pID] = init
    tar._meta.cyclesComplete = 1
    tar._meta.cycleTimer = GetRunningTime()
  elseif
    rupture ~= 0 and rupture ~= 1 and (vir ~= nil or dir == "down") and
      (GetRunningTime() - tar._meta.cycleTimer > abs(rupture))
   then
    currentPosition["_" .. tar.pID] = init
    tar._meta.cyclesComplete = 1
  end

  if type(tar._meta.cyclesComplete) == "number" and tl.macroIndex[tar.pID]._meta.cyclesComplete > lim then
    if quitter == "end" then
      return
    elseif quitter == "reset" then
      currentPosition["_" .. tar.pID] = init
      tar._meta.cyclesComplete = 1
    elseif type(quitter) == "table" then
      tar.finish = quitter
      if not quitter.type then
        quitter.type = tar.cast
      end
      tl.launchMacro(num, fam, tar.finish, directed, dir, quitter.pID)
      return
    end
  end
  if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
    tar._meta.cycleTimer = tl.macroIndex[parent]._meta.cycleTimer
  else
    tar._meta.cycleTimer = GetRunningTime()
  end
  if currentPosition["_" .. tar.pID] ~= 1 or type(tar[currentPosition["_" .. tar.pID]]) ~= "number" then
    local mac = tar[currentPosition["_" .. tar.pID]]
    if type(mac) == "table" and not mac.type then
      mac.type = tar.cast
    end
    tl.launchMacro(num, fam, mac, directed, dir, tar.pID)
  end
  if vir ~= nil or dir == "up" then
    while type(tar[currentPosition["_" .. tar.pID] + step]) == "number" do
      step = step + 1
    end
    currentPosition["_" .. tar.pID] = currentPosition["_" .. tar.pID] + step
    if currentPosition["_" .. tar.pID] > finish or currentPosition["_" .. tar.pID] > #tar then
      if not (init > finish and currentPosition["_" .. tar.pID] <= #tar and tar._meta.cyclesComplete == 1) then
        if tar._meta.cyclesComplete < lim then
          currentPosition["_" .. tar.pID] = start
          tar._meta.cyclesComplete = tar._meta.cyclesComplete + 1
        else
          tar._meta.cyclesComplete = lim + 1
          currentPosition["_" .. tar.pID] = #tar
        end
      end
    end
  end
end

function tl.cycleReset(buts) --here, cycles for cycling sequences are reset, either for a specific one or all of them.
  if buts and type(buts) == "table" then
    for k = 1, #buts do
      local v = buts[k]
      tl.cycleReset(v)
    end
  elseif buts and type(buts) == "string" and buts ~= "" then
    for g = 1, #tl.families do
      local tk = tl.token(tl.families[g])
      tl.state[tk].stable["_" .. buts] = nil
      tl.state[tk].unstable["_" .. buts] = nil
    end
  elseif buts == "" or buts == 0 then
    for g = 1, #tl.families do
      local tk = tl.token(tl.families[g])
      tl.wipe(tl.state[tk].stable["_" .. buts])
      tl.wipe(tl.state[tk].unstable["_" .. buts])
    end
  end
end

local function _setCyclePosition(cycleName, position,fam)
  if type(position) ~= "number" then return end
  local cycleMacro = tl.macroIndex[cycleName]
  
  local cycleState = cycleMacro.cancel > 0 and tl.state[fam].stable["_" .. cycleName] or tl.state[fam].unstable["_" .. cycleName]
  tl.cycleIndex(#cycleMacro,position,cycleState)
end

local function _setCyclesCompleted(cycleName, number)
  if type(number)~="number" then return end
  tl.macroIndex[cycleName]._meta.cyclesComplete = number
end

function tl.cycleControl(name,positionOption,completedOption,fam)
  if name and type(name) == "table" then
    for k = 1, #name do
      local v = name[k]
      tl.cycleControl(v,positionOption)
    end
    return
  end
  if positionOption == 0 then 
    tl.cycleReset(name)
  else
    _setCyclePosition(name,positionOption,fam)
  end
  if completedOption then
    _setCyclesCompleted(completedOption,fam)
  end
end

function tl.sequenceControl(name,option)
  if name and type(name) == "table" then
    for k = 1, #name do
      local v = name[k]
      tl.sequenceControl(v,option)
    end
    return
  end

  local setting = option
  local controls ={
    p=tl.tPause,
    pause=tl.tPause,
    c=tl.taskAbort,
    cancel=tl.taskAbort,
    r=tl.tRes,
    resume=tl.tRes,
  }

  if not setting then
    if tl.config.pauseOnDefault then
      if tl.taskRunning(name) then  setting = "p"
      else setting = "r" end
    else setting = "c" end
  end
  
  controls[setting](name)
end

---timing function for multi-click keys
---@param cont GenericMacro
---@param fam string
---@param num number
function tl.timerKey(cont, fam, num)
  local time = cont.timer or tl.config.multiClickTime
  local meta = cont._meta
  if not meta.multiTimer and not meta.multiClick then
    meta.multiClick = 1
    tl.taskRun(cont.pID,fam,num,((cont.timer == "absolute" and _altTimer) or _timer),cont,(GetRunningTime() + time),time,1)
  elseif meta.multiTimer ~= nil then
    meta.multiClick = meta.multiClick + 1
  end
  if cont.timer ~= "absolute" then
    return -1
  end

  local timeActive = meta.multiTimer
  local clickNum = meta.multiClick

  if cont.mode == nil or cont.mode ~= "stack" then
    if timeActive == nil and cont[clickNum] ~= nil then
      tl.launchMacro(num, fam, cont[clickNum], 4)
      meta.multiClick = nil
    end
  else
    for i = 1, clickNum do
      if cont[i] ~= nil then
        tl.launchMacro(num, fam, cont[i], 4)
      end
    end
  end
  if timeActive == nil then
    meta.multiClick = nil
  end
  return -1
end

---Timing function for held down keys
---@param cam HoldMacro
---@param buttonDirection string
---@param fam string
---@param num number
function tl.staggeredkey(cam, buttonDirection, fam, num)
  local com = cam
  if type(com) ~= "table" or #com < 2 then
    return
  end
  local deflay = com.holdTime or tl.config.defaultHold
  local curlay = 0
  local lastLay
  local initas = com.init or false
  local lease = com.release or "auto"
  local dirge = buttonDirection or tl.state[fam].dir
  local comray = com
  local lastNum = -20
  local stagMode = com.mode or "relative"
  local commy = tl.intersect(com, {})
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
        tl.launchMacro(num, fam, comray[i], 4)
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
      tl.taskRun(com.pID, fam, num, _finalStagger, seppy, GetRunningTime(), com.pID, fam, num)
    end

    com._meta.stagTimer = GetRunningTime()
  elseif dirge == "up" and com._meta.stagTimer ~= nil then
    local timeNow = GetRunningTime() - com._meta.stagTimer
    for g = 1, #workTab do
      local i = #workTab - g + 1
      local tabsi = workTab[i]
      if tabsi[1] < timeNow then
        if not tabsi[2].type then
          tabsi[2].type = workTab.cast
        end
        tl.launchMacro(num, fam, tabsi[2], 4)
        break
      end
    end
    com._meta.stagTimer = nil
  end
end

---function for cancelling the execution of staggered sequences
---@param buttons string|table
---@param dir string
function tl.staggerCancel(buttons, dir)
  if dir and dir ~= "down" then
    return
  end
  if buttons and type(buttons) == "table" then
    for k = 1, #buttons do
      local v = buttons[k]
      tl.staggerCancel(v)
    end
  elseif buttons and type(buttons) == "string" and buttons ~= "" then
    tl.macroIndex[buttons]._meta.stagTimer = nil
  elseif buttons == nil or buttons == 0 then
    for k, _ in pairs(tl.macroIndex) do
      local cStat = tl.macroIndex[k]._meta
      cStat.stagTimer = nil
    end
  end
end

---Logging and LCD output function
---@param msg string
function tl.outputWrapper(msg)
  if msg[1] == nil then
    error("No Message to Display")
  end
  local persist = tl.config.persistLCD
  local stay = msg[2] or tl.config.persistLCD
  if msg.debug then
    OutputDebugMessage(msg[1])
    return
  end
  if type(msg[1]) == "table" then
    tl.prettyTab(msg[1])
  elseif msg.noLCD == 1 then
    tl.putNoLCD(msg[1])
  else
    tl.config.persistLCD = stay
    tl.put(msg[1])
    tl.config.persistLCD = persist
  end
end

---variable setter
---@param varCmd string|table
function tl.setFlag(varCmd)
  if type(varCmd) == "string" or (type(varCmd) == "table" and varCmd[2] == nil) then
    if type(varCmd) == "table" then
      varCmd = varCmd[1]
    end
    tl.flags[varCmd] = not tl.flags[varCmd]
  else
    tl.flags[varCmd[1]] = varCmd[2]
  end
end

---function for toggling documentation mode
function tl.toggleDocs()
  tl.docMode = not tl.docMode
  tl.put((not tl.docMode) and "Documentation Mode Deactivated" or "Documentation Mode Activated")
end

---@class doc
---key documentation function for documentation mode
---@param macro GenericMacro
---@param fam string
---@param num number
function tl.documentKey(macro, fam, num)
  local macroString =
    macro.doc or tl.assign.documentation[macro.pID] or
    (fam and num and (tl.assign.documentation[tl.config.rename[fam .. num]] or tl.assign.documentation[fam .. num]))
  if macro.pID == tl.lastDocumented then
    tl.lastDocumented = ""
    return
  end
  if macroString and macroString ~= "" then
    tl.put(macroString)
  elseif macroString ~= "" then
    tl.prettyTab(macro, nil, 1)
  end
  tl.lastDocumented = macro.pID
end
