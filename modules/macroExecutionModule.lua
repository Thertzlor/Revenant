local tl = ...
local ceil,huge, abs, GetRunningTime = math.ceil,math.huge, math.abs, GetRunningTime
---->>> Functions controlling Macros that are run on key press ========================================

function tl.executor(convict) --Executes functions (recursively)
  if type(convict) == "string" then
    _G[convict]()
  elseif type(convict) == "table" then
    local namu = convict[1]
    table.remove(convict,1)
    _G[namu](unpack(convict))
    table.insert(convict,1,namu)
  end
end
---[[

function tl.normKey(tg,dir,relmod,vir,bid,del,dev,fam,num) --Handles the default key functions, called by key name or as simple sequence
  if type(tg) == "table" and #tg ==1 then tg = tg[1] end
  local releaseToggle = false
  if (coroutine.running() and relmod == 0) or (vir and relmod==0 and (vir==1 or dir == nil)) then
    if type(tg) == "string" and tl._KEYBOARD[tg] == nil and tl.logiKeys[tg] == nil then
      tl.typer(tl.applyBuffer(tg,fam,num,1),nil,del,nil,dev,fam,num)
    else
      if type(tg) ~= "table" then tg= {tg} end
      tl.bothRay(tg,del,dev)
      releaseToggle = true
    end
  else
    if (dir == "down" and relmod == 0) or relmod == 1 or (relmod == 4 and (dir=="down" or vir) )or (relmod == 3 and tl.toggled["_"..bid] == nil) then
      if relmod == 3 then tl.toggled["_"..bid] = 1 
      elseif relmod == 4  then
        local releaseBuffer = tl.state[fam]['_auto'..num] or {}
        releaseBuffer[#releaseBuffer+1] = tg
        tl.state[fam]['_auto'..num] = releaseBuffer
      end
      if type(tg) == "string" then
        tl.Press(tl.applyBuffer(tg,fam,num),del,dev,fam,num)
      elseif type(tg) == "table" then
        tl.preRay(tg,del,dev)
      end
    elseif (dir =="up" and relmod == 0) or relmod == 2 or (dir == "down" and relmod == 3 and tl.toggled["_"..bid] ~= nil) then
      if relmod ~= 5 then releaseToggle = true end
      if type(tg) == "string" then
        tl.Release(tl.applyBuffer(tg,fam,num,1),del,dev)
      elseif type(tg) == "table" then
        if tg.unreverse ~= nil then tl.Reverse(tg) end
        tl.relRay(tg,del,dev)
        if tg.unreverse ~= nil then tl.Reverse(tg) end
      end
      if relmod == 3 then
        tl.toggled["_"..bid] = nil
      end
    end
  end
  if releaseToggle then tl.autoRelease(fam,num,del,dev) end 
end

function tl.histoRase(num,d)
  if type(num) ~= "number" or num < 1 then
    tl.wipe(tl.lastKeysDown)
  else
    for g=1, num+1 do
      table.remove(tl.lastKeysDown)
    end
  end
end

function tl.quiKey(targ,name,dir,descPlay,mos,vir,fam) --main function for executing macro sequences
  local tg = targ
  local descDir = descPlay or "normal"
  local mode = tg.play or "normal"
  if ((mode == "normal" or mode == "toggle" or mode=="ptoggle") and (dir ~= nil and dir ~= "down") and descDir ~= "up") or (descDir == "up" and dir=="down") then
    return -1
  end
  local ride = tg.stack or tl.defaultStacking
  local mouseN = mos or 0
  local seqProperties ={}
  local seqModifier={
    {"delayer","actionDelay"},
    {"dekayer","keyDelay"},
    {"actionDeviator","randomActionDeviation"},
    {"keyDeviator","randomKeyDeviation"}}

  for m=1, #seqModifier do local mod = seqModifier[m]
     seqProperties[mod[1]] = tg[mod[2]] or tl[mod[2]]; 
  end

  if tl.TaskList[name] ~= nil then
    if mode == "toggle" or mode == "hold" then
      tl.TaskAbort(name,fam,mouseN) 
    elseif (mode == "ptoggle" or mode == "phold") and tl.TaskList[name].paused == false then
      tl.tPause(name) 
    elseif  (mode == "ptoggle" or mode == "phold") then
      tl.tRes(name) 
    elseif mode == "normal" and tl.TaskList.paused == false then
      if ride == 0 then
        tl.TaskAbort(name,fam,mouseN)
        tl.TaskRun(name,fam,mouseN,tl.quiKey,tg,nil,dir,descDir,mouseN,vir,fam)
      elseif ride == 2 then
        tl.seQueue(name,tg,nil,dir,descDir,mouseN,vir,fam)
      elseif ride == 1 then
        tl.TaskAbort(name,fam,mouseN)
      end
    end
    return -1
  elseif dir == "up" and descDir ~= "up" then 
    return -1
  end
    --^^ dealing with toggling sequences
  if coroutine.running() == nil and vir ~= 1 and vir ~= 3  and name and tl.TaskList[tg.pID] == nil and tl.TaskList[name] == nil and tl.exitus == 0 then --launching coroutines
    tl.TaskRun(name,fam,mouseN,tl.quiKey,tg,nil,dir,descDir,mouseN,vir,fam)
    return -1
  end

  local function processTable() --process nested tables storing special information
    local looper = tg.loop or 1
    local loopNum = #tg*looper
    local loopStart = tl.macroStats[tg.pID or "null"].seqPosition or 1
    if looper == 0 then return -1 elseif looper < 0 then loopNum = huge end
    local noWait = false
    for g = loopStart , loopNum do
      local i = g - (#tg*(ceil((g/#tg-1)+1)-1))
      local obj = tg[i]
      if i ~= 1 and noWait == false and type(obj) ~= "number" then
        tl.wait(seqProperties.delayer,seqProperties.actionDeviator)
      elseif noWait == true  then
        noWait = false
      end
      if type(obj) == "string" then
        tl.typer(tl.applyBuffer(obj,fam,mouseN,1),seqProperties.delayer,seqProperties.dekayer,seqProperties.actionDeviator,seqProperties.keyDeviator,fam,mouseN)
      elseif type(obj) == "table" then
        if tl.props(obj) == false then
          if tl.allType(obj,"string") then
            if #obj == 1 then tl.keyGen(mouseN,fam,tl.resolveLink(tl.macroStats[obj[1]].macro),0,1,dir) else tl.normKey(obj,nil,0,1,obj.pID,seqProperties.delayer,seqProperties.keyDeviator,fam,mouseN)end
          elseif tl.allType(obj,"number") then
            for n=1, #seqModifier do local mod = seqModifier[n]
              if obj[n] ~= nil and obj[n] >= 0 then  seqProperties[mod[1]] = obj[n] 
              elseif obj[n] == -1 then  seqProperties[mod[1]] = tg[mod[2]] or tl[mod[2]] 
              elseif obj[n] == -2 then  seqProperties[mod[1]] = tl[mod[2]]  end
            end
          end
        else
          obj.delay = obj.delay or seqProperties.delayer
          obj.kdelay = obj.kdelay or seqProperties.dekayer
          tg[i] = tl.heir(obj,tg)
          if tg[i].type == nil and tg[i].loop ~=nil then tg[i].type = "s" elseif tg[i].type == nil and #tg[i] == 1 and type(tg[i][1]) == "string" then
            tg[i].type = "bf"
          end
          tl.keyGen(mouseN,fam,tg[i],0,1,dir)
        end
      elseif type(obj) == "number" then
          noWait = true
          tl.wait(obj,seqProperties.actionDeviator)
      end
    end
  end

  if type(tg) == "table" then
    processTable()
  elseif type(tg) == "string" then
    tl.typer(tl.applyBuffer(tg,fam,mouseN,1),seqProperties.delayer,seqProperties.dekayer,seqProperties.actionDeviator,seqProperties.keyDeviator,fam,mouseN)
  end

  return -1
end

function tl.agnostiCycle(tarry,dir,vir,virpar,fam,num) --main function for cycling sequences
  local tar = tarry
  if type(tar) ~= "table" then return end
  local step = 1
  local lim = tar.limit or huge
  local inherit = tar.inherit or "all"
  if lim == 0 then lim = huge end
  local rupture = tar.cancel or 0
  local parent = virpar or 999
  if type(parent) ~= "number" then parent= "_"..parent end
  local numlog = tl.state[fam].stable
  local quitter = tar.finish or "stall"
  local start = 1
  local init = start
  local finish = #tar
  if type(tar.range) == "table" and tl.allType(tar.range,"number") then
    for  j=1, #tar.range do
      if tar.range[j] <= 0 then tar.range[j] = #tar + tar.range[j] end
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

  local directed = 2
  if vir then directed = 3 end
  if rupture == 1 or rupture < 0 then numlog = tl.state[fam].unstable end
  if numlog["_"..tar.pID] == nil or (vir and dir=="down" and (tl.state[fam].unstable[parent] == 1 or tl.state[fam].stable[parent] == 1) and tl.macroStats[parent].cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
    numlog["_"..tar.pID] = init
    tl.macroStats[tar.pID].cyclesComplete = 1
    tl.macroStats[tar.pID].cycleTimer = GetRunningTime()
  elseif rupture ~=0 and rupture ~=1 and (vir ~= nil or dir == "down") and (GetRunningTime() -tl.macroStats[tar.pID].cycleTimer > abs(rupture)) then
    numlog["_"..tar.pID] = init
    tl.macroStats[tar.pID].cyclesComplete = 1
  end
  
  if type(tl.macroStats[tar.pID].cyclesComplete) == "number" and tl.macroStats[tar.pID].cyclesComplete > lim then
    if  quitter=="end" then
      return
    elseif quitter == "reset" then
      numlog["_"..tar.pID] = init
      tl.macroStats[tar.pID].cyclesComplete = 1
    elseif type(quitter) == "table" then
      tar.finish = tl.heir(quitter,tar)
      tl.keyGen(num,fam,tar.finish,0,directed,dir,quitter.pID)
      return
    end
  end
  if vir and virpar and inherit ~= "status" and inherit ~= "none" then
    tl.macroStats[tar.pID].cycleTimer = tl.macroStats[parent].cycleTimer
  else
    tl.macroStats[tar.pID].cycleTimer = GetRunningTime()
  end
  if numlog["_"..tar.pID] ~= 1 or type(tar[numlog["_"..tar.pID]]) ~= "number" then
    tar[numlog["_"..tar.pID]] = tl.heir(tar[numlog["_"..tar.pID]],tar)
    tl.keyGen(num,fam,tar[numlog["_"..tar.pID]],0,directed,dir,tar.pID)
  end
  if vir ~= nil or dir == "up" then
    while type(tar[numlog["_"..tar.pID]+step]) == "number" do step=step+1 end
    numlog["_"..tar.pID] = numlog["_"..tar.pID] + step
    if numlog["_"..tar.pID] > finish or numlog["_"..tar.pID] > #tar then
      if not (init > finish and numlog["_"..tar.pID] <= #tar  and tl.macroStats[tar.pID].cyclesComplete == 1) then
        if tl.macroStats[tar.pID].cyclesComplete < lim then
          numlog["_"..tar.pID] = start
          tl.macroStats[tar.pID].cyclesComplete = tl.macroStats[tar.pID].cyclesComplete + 1
        else
          tl.macroStats[tar.pID].cyclesComplete = lim+1
          numlog["_"..tar.pID] = #tar
        end
      end
    end
  end
end

function tl.cycleReset(buts)  --here, cycles for cycling sequences are reset, either for a specific one or all of them.
  if buts and type(buts) == "table" then
    for k=1,#buts do local v = buts[k] tl.cycleReset(v) end
    return
  end
  if buts and type(buts) == "string" and buts ~= "" then
    for g = 1, #tl.families do local tk = tl.token(tl.families[g])
    tl.state[tk].stable["_"..buts] = nil
    tl.state[tk].unstable["_"..buts] = nil
    end
  elseif buts == "" or buts == 0 then
        for g = 1, #tl.families do local tk = tl.token(tl.families[g])
    tl.wipe(tl.state[tk].stable["_"..buts])
    tl.wipe(tl.state[tk].unstable["_"..buts])
    end
  end
end

function tl.timer(key,endMoment,id,fam,num)
  tl.macroStats[id].multiTimer=endMoment
  while GetRunningTime() < endMoment do
    tl.wait(tl.PollInterval)
  end
  tl.macroStats[id].multiTimer=nil
  if tl.macroStats[id].multiClick ~= nil and (key.mode == "single" or not key.mode) then
    tl.keyGen(num,fam,key[tl.macroStats[id].multiClick],0,4)
  end
  tl.macroStats[id].multiClick = nil
  return -1
end

function tl.timerKey(cont,dir,fam,num)
  local  time = cont.timer or tl.multiClickTime

  if not tl.macroStats[cont.pID].multiTimer and not tl.macroStats[cont.pID].multiClick then
    tl.macroStats[cont.pID].multiClick = 1
    tl.TaskRun(cont.pID,fam,num,tl.timer,cont,(GetRunningTime()+time),cont.pID)
  elseif tl.macroStats[cont.pID].multiTimer ~= nil  then
    tl.macroStats[cont.pID].multiClick = tl.macroStats[cont.pID].multiClick + 1
  end

  local timeActive = tl.macroStats[cont.pID].multiTimer
  local clickNum = tl.macroStats[cont.pID].multiClick

  if cont.mode == nil or cont.mode == "single" then
    if timeActive == nil and cont[clickNum] ~= nil then tl.keyGen(num,fam,cont[clickNum],dir,4)
      tl.macroStats[cont.pID].multiClick = nil
    end

  elseif cont.mode == "continous" then
    if cont[clickNum] ~= nil then tl.keyGen(num,fam,cont[clickNum],0,4) else tl.keyGen(num,fam,cont[#cont],0,4)  end
  elseif cont.mode == "stack" then
    for i=1, clickNum do
      if cont[i] ~=nil then tl.keyGen(num,fam,cont[i],0,4) else tl.keyGen(num,fam,cont[#cont],0,4)  end
    end
  end
  if timeActive == nil then  tl.macroStats[cont.pID].multiClick = nil end
  return -1
end

function tl._finalStagger(con,startval,tID,fam,num)
  while GetRunningTime() < (startval + con[1]) do
    tl.wait(tl.PollInterval)
  end
  if tl.macroStats[tID].stagTimer ~= nil then
    tl.macroStats[tID].stagTimer = nil
    tl.keyGen(num,fam,con[2],0,4)
  end
  return -1
end

function tl.stagger(cam, dira,fam,num)
  local com = cam
  if type(com) ~="table" or #com < 2 then return end
  local deflay = com.holdTime or tl.defaultHold
  local curlay = 0
  local lastLay
  local initas = com.init or 0
  local lease = com.release or "auto"
  local dirge = dira or tl.state[fam].dir
  local comray = com
  local lastNum = -20
  local stagMode = com.mode or "relative"
  local commy = tl.intersect(com,{})
  local lastN = table.remove(commy)
  if type(lastN) == "number" then
  comray = commy
  deflay = lastN
  lastLay=lastN
  end

  local workTab={}
  for i=1, #comray do local that = comray[i]
    if type(that) == "number" then
        deflay = that
        lastNum = i
    elseif initas == 1 and #workTab == 0 then
      initas = 0
      deflay = 0
      if dirge == "down" then
        comray[i] = tl.heir(comray[i],com)
        tl.keyGen(num,fam,comray[i],0,4)
      end
    else
    if #workTab ~= 0 then
      if stagMode == "absolute" then
        curlay =  deflay
      else
        if stagMode~="additive" and i ~= lastNum+1 then deflay = lastLay or com.defaultHold or tl.standartStagger end
        curlay = curlay + deflay
      end
    end
      table.insert(workTab,{curlay,that})
    end
  end

  if dirge == "down" then
    if lease == "auto" then
      local seppy = table.remove(workTab)
      seppy = tl.heir(seppy,com)
      tl.TaskRun(com.pID,fam,num,tl._finalStagger,seppy,GetRunningTime(),com.pID,fam,num)
    end

    tl.macroStats[com.pID].stagTimer = GetRunningTime()
  elseif dirge =="up" and tl.macroStats[com.pID].stagTimer ~= nil then
    local timeNow = GetRunningTime() - tl.macroStats[com.pID].stagTimer
      for g=1, #workTab do
        local i = #workTab-g+1
        local tabsi = workTab[i]
        if tabsi[1] < timeNow then
          tl.keyGen(num,fam,tabsi[2],0,4)
          break
        end
      end
    tl.macroStats[com.pID].stagTimer = nil
  end
end

function tl.lcancel(buts,dir)   -- function for cancelling the execution of staggered sequences
  if dir and dir ~= "down" then return end
  if buts and type(buts) == "table" then
    for k=1,#buts do local v = buts[k] tl.lcancel(v) end
    return
  end
  if buts and type(buts) == "string" and buts ~= "" then
    tl.macroStats[buts].stagTimer = nil
  elseif buts == nil or buts == 0 then
    tl.wipe(tl.stagTimer)
  end
end

function tl.outputWrapper(msg)
  if msg[1] == nil then error("No Message to Display") end
  local persist = tl.persistLCD
  local stay = msg[2] or tl.persistLCD
  if msg.debug then  OutputDebugMessage(msg[1]) return end
  if type(msg[1]) == "table" then
    tl.prettyTab(msg[1])
  elseif msg.noLCD == 1 then
    tl.putNoLCD(msg[1])
  else
    tl.persistLCD = stay
    tl.put(msg[1])
    tl.persistLCD = persist
  end
end

function tl.setVar(varCmd)
  if type(varCmd) == "string" or (type(varCmd) == "table" and varCmd[2] ==nil)then
    if type(varCmd) == "table" then varCmd = varCmd[1]end
    tl.stateVars[varCmd] = not tl.stateVars[varCmd]
  else
    tl.stateVars[varCmd[1]] = varCmd[2]
  end
end

function tl.docSwitch()
  local docMessage = "Documentation Mode Activated"
  if tl.docMode then docMessage = "Documentation Mode Deactivated" end
  tl.docMode = not tl.docMode
  tl.put(docMessage)
end

function tl.document(macro,fam,num)
  local macroString = macro.doc or tl.assign.documentation[macro.pID] or (fam and num and (tl.assign.documentation[tl.rename[fam..num]] or tl.assign.documentation[fam..num]))
  if macro.pID == tl.lastDocumented then tl.lastDocumented ="" return end
  if macroString and macroString ~= "" then tl.put(macroString)elseif macroString ~= "" then tl.prettyTab(macro,nil,1) end
  tl.lastDocumented = macro.pID;
end