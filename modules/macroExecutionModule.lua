local tl = ...

---->>> Functions controlling Macros that are run on key press ========================================

function tl.executor(convict) --Executes named sequences (recursively)
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
  
  function tl.normKey(tg,dir,relmod,vir,bid,del) --Handles the default key functions, called by key name or as simple sequence
    if vir and relmod==0 and (vir==1 or dir == nil) then
      if type(tg) == "string" then
        tl.PressAndRelease(tg,del)
      elseif type(tg) == "table" then
        tl.bothRay(tg,del)
      end
    else
      if (dir == "down" and relmod == 0) or relmod == 1 or (relmod == 3 and tl.toggled["_"..bid] == nil) then
        if relmod == 3 then
        tl.toggled["_"..bid] = 1
        end
        if type(tg) == "string" then
          tl.Press(tg)
        elseif type(tg) == "table" then
          tl.preRay(tg,del)
        end
      elseif (dir =="up" and relmod == 0) or relmod == 2 or (dir == "down" and relmod == 3 and tl.toggled["_"..bid] ~= nil) then
        if type(tg) == "string" then
          tl.Release(tg)
        elseif type(tg) == "table" then
          if tg.unreverse ~= nil then tl.Reverse(tg) end
          tl.relRay(tg,del)
          if tg.unreverse ~= nil then tl.Reverse(tg) end
        end
        if relmod == 3 then
          tl.toggled["_"..bid] = nil
        end
      end
    end
  end
  
  function tl.histoRase(num,d)
    if type(num) ~= "number" or num < 1 then
      tl.wipe(tl.lastKeysDown)
      tl.wipe(tl.lastKeysUp)
    else
      for _=1, num+1 do
        table.remove(tl.lastKeysDown)
        table.remove(tl.lastKeysUp)
      end
    end
    if #tl.lastKeysUp == 0 and d=="up" then table.insert(tl.lastKeysUp,0) end
  end
  
  function tl.quiKey(targ,name,dir,descPlay,mos,vir) --main function for executing macro sequences
    local tg = targ._tablified_s or targ
    if tg.cast then tg = tg._tablified_s or tl.assumption(tg,"s") end
    local descDir = descPlay or "normal"
    local mode = tg.play or "normal"
    local ride = tg.stack or tl.defStack
    local mouseN = mos or 0
    local delayer = tg.delay or tl.actionDelay
    local dekayer = tg.keyDelay or tl.keyDelay
  
    --if mode ~= "phold" and mode ~="ptoggle" then local ident = name or tg.pID  if ident ~= nil then tl.macroStats[ident].seqPosition = nil end end
  
    if dir then
      if mode == "phold" and dir == "down" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==true then
        tl.tRes(name)
        return
      end
  
      if (mode == "ptoggle" and descDir == "normal" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==true and (dir == nil or dir == "down")) or (mode == "ptoggle" and descDir == "up" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==true and dir == "up") then
        tl.tRes(name)
        return
      end
  
      if ((mode == "normal" or mode == "toggle" or mode=="ptoggle") and ((dir == "up" and descDir == "normal") or (dir=="down" and descDir == "up" ))) then
        return --make sure we don't fire events meant to be played on keyup/keydown at the wrong time.
      elseif (mode == "hold" and dir == "up") then --pausing or aborting "hold" type sequences
        tl.TaskAbort(name)
        return
      elseif (mode == "phold" and dir == "up") then
        tl.tPause(name)
        return
      else
        if tl.TaskList[tg.pID] ~= nil and not vir then
          if ride == 0 then
            tl.TaskAbort(name)
            tl.TaskRun(name,tl.quiKey,tg,nil,dir,descDir,mouseN,vir)
            return
          elseif ride == 2 then
            tl.seQueue(name,tg,nil,dir,descDir,mouseN,vir)
          elseif ride == 1 then
            return
          end
        end
      end
    end
  
    if (mode == "ptoggle" and descDir == "normal" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==false and (dir == nil or dir == "down")) or (mode == "ptoggle" and descDir == "up" and tl.TaskList[name] ~= nil and tl.TaskList[name].paused==false and dir == "up") then
      tl.tPause(name)
      return
    end
  
    if (mode == "toggle" and descDir == "normal" and tl.TaskRunning(name) == true and (dir == nil or dir == "down")) or (mode == "toggle" and descDir == "up" and tl.TaskRunning(name) == true and dir == "up") then
      tl.put("trying to abort")
      tl.TaskAbort(name)
      return
    end
      --^^ dealing with toggling sequences
    if coroutine.running() == nil and vir ~= 1 and vir ~= 3  and name and tl.TaskList[tg.pID] == nil and tl.exitus == 0 then --launching coroutines
      if tl.TaskList[name] == nil then
        tl.TaskRun(name,tl.quiKey,tg,nil,dir,descDir,mouseN,vir)
      else
        if tl.TaskList[name].paused == true then
          tl.TaskList[name].paused = false
        end
      end
      return
    end
  
    local function processTable() --process nested tables storing special information
      local looper = tg.loop or 1
      local loopNum = #tg*looper
      local aDev = tg.randomActionDeviatioon or tl.randomActionDeviatioon
      local kDev = tg.randomKeyDeviation or tl.randomKeyDeviation
      local loopStart = tl.macroStats[tg.pID or "null"].seqPosition or 1
      if looper == 0 then return -1 elseif looper < 0 then loopNum = math.huge end
      local noWait = false
      for g = loopStart , loopNum do
    --    tl.macroStats[tg.pID].seqPosition = g
        local i = g - (#tg*(math.ceil((g/#tg-1)+1)-1))
        local obj = tg[i]
        if i ~= 1 and noWait == false and type(obj) ~= "number" then
          tl.wait(delayer,aDev)
        elseif noWait == true  then
          noWait = false
        end
        if type(obj) == "string" then
          tl.typer(obj,delayer,dekayer,aDev,kDev)
        elseif type(obj) == "table" then
          if tl.props(obj) == false then
            if tl.allType(obj,"string") then
              if #obj == 1 then tl.keyGen(mouseN,tl.resolveLink(tl.macroStats[obj[1]].macro),0,1,dir) else tl.normKey(obj,nil,0,1,obj.pID,delayer)end
            elseif tl.allType(obj,"number") then
              if obj[1] >= 0 then delayer = obj[1] elseif obj[1] == -1 then delayer = tg.delay or tl.actionDelay elseif obj[1] == -2 then delayer =  tl.actionDelay end
              if obj[2] ~= nil then
                 if obj[2] >= 0 then dekayer = obj[2] elseif obj[2] == -1 then dekayer = tg.kdelay or tl.keyDelay elseif obj[2] == -2 then delayer = tl.actionDelay end
              end
          end
          else
              obj.delay= obj.delay or delayer
              obj.kdelay=obj.kdelay or dekayer
              for m=1, #tl.sequenceInheritor do local attr = tl.sequenceInheritor[m]
              obj[attr] =  obj[attr] or tg[attr]
              end
              if obj.type == nil and obj.loop ~=nil then obj.type = "s" end
            tl.keyGen(mouseN,obj,0,1,dir)
          end
        elseif type(obj) == "number" then
            noWait = true
            tl.wait(obj,aDev)
          end
        end
      end
  
      if type(tg) == "string" then
        tl.typer(tg,delayer,dekayer,aDev,kDev)
      elseif type(tg) == "table" then
        processTable()
      end
      return -1
  end
  
  function tl.agnostiCycle(tarry,dir,vir,virpar) --main function for cycling sequences
    local tar = tarry._tablified_c or tl.assumption(tarry,"c")
    local lim = tar.limit or math.huge
    local inherit = tar.inherit or "all"
    if lim == 0 then lim = math.huge end
    local rupture = tar.cancel or 0
    local parent = virpar or 999
    if type(parent) ~= "number" then parent= "_"..parent end
    local numlog = tl.stable
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
    if rupture == 1 or rupture < 0 then numlog = tl.unstable end
  
    if type(tar) ~= "table" then
      return
    else
      tl.put(tar.pID)
      if numlog["_"..tar.pID] == nil or (vir and dir=="down" and (tl.unstable[parent] == 1 or tl.stable[parent] == 1) and tl.macroStats[parent].cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
        numlog["_"..tar.pID] = init
        tl.macroStats[tar.pID].cyclesComplete = 1
        tl.macroStats[tar.pID].cycleTimer = GetRunningTime()
      elseif rupture ~=0 and rupture ~=1 and (vir ~= nil or dir == "down") and (GetRunningTime() -tl.macroStats[tar.pID].cycleTimer > math.abs(rupture)) then
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
          tl.keyGen(0,quitter,0,directed,dir,quitter.pID)
          return
        end
      end
  
      if vir and virpar and inherit ~= "status" and inherit ~= "none" then
        tl.macroStats[tar.pID].cycleTimer = tl.macroStats[parent].cycleTimer
      else
        tl.macroStats[tar.pID].cycleTimer = GetRunningTime()
      end
      tl.keyGen(0,tar[numlog["_"..tar.pID]],0,directed,dir,tar.pID)
        if vir ~= nil or dir == "up" then
          numlog["_"..tar.pID] = numlog["_"..tar.pID] + 1
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
  end
  
  function tl.cycleReset(buts)  --here, cycles for cycling sequences are reset, either for a specific one or all of them.
    if buts and type(buts) == "table" then
      for k=1,#buts do local v = buts[k] tl.cycleReset(v) end
      return
    end
    if buts and type(buts) == "string" and buts ~= "" then
      tl.stable["_"..buts] = nil
      tl.unstable["_"..buts] = nil
    elseif buts == "" or buts == 0 then
      tl.wipe(tl.stable)
      tl.wipe(tl.unstable)
    end
  end
  
  function tl.timer(key,endMoment,id)
    tl.macroStats[id].multiTimer=endMoment
    while GetRunningTime() < endMoment do 
      tl.wait(tl.PollInterval)
    end
    tl.macroStats[id].multiTimer=nil
    if tl.macroStats[id].multiClick ~= nil and (key.mode == "single" or not key.mode) then
      tl.keyGen(0,key[tl.macroStats[id].multiClick],0,4)
    end
    tl.macroStats[id].multiClick = nil
  end
  
  function tl.timerKey(cont,dir)
    local  time = cont.timer or tl.multiClickTime
  
    if not tl.macroStats[cont.pID].multiTimer and not tl.macroStats[cont.pID].multiClick then
      tl.macroStats[cont.pID].multiClick = 1
      tl.TaskRun(cont.pID,tl.timer,cont,(GetRunningTime()+time),cont.pID)
    elseif tl.macroStats[cont.pID].multiTimer ~= nil  then
      tl.macroStats[cont.pID].multiClick = tl.macroStats[cont.pID].multiClick + 1
      tl.put(tl.macroStats[cont.pID].multiClick)
    end
  
    local timeActive = tl.macroStats[cont.pID].multiTimer
    local clickNum = tl.macroStats[cont.pID].multiClick
  
    if cont.mode == nil or cont.mode == "single" then
      if timeActive == nil and cont[clickNum] ~= nil then tl.keyGen(0,cont[clickNum],dir,4)
        tl.macroStats[cont.pID].multiClick = nil
      end
      
    elseif cont.mode == "continous" then
      if cont[clickNum] ~= nil then tl.keyGen(0,cont[clickNum],0,4) else tl.keyGen(0,cont[#cont],0,4)  end
    elseif cont.mode == "stack" then
      for i=1, clickNum do 
        if cont[i] ~=nil then tl.keyGen(0,cont[i],0,4) else tl.keyGen(0,cont[#cont],0,4)  end 
      end
    end
  
    if timeActive == nil then  tl.macroStats[cont.pID].multiClick = nil end
  end
  
  function tl.finalStagger(con,startval,tID)
    while GetRunningTime() < (startval + con[1]) do
      tl.wait(tl.PollInterval)
    end
    if tl.macroStats[tID].stagTimer ~= nil then
      tl.macroStats[tID].stagTimer = nil
      tl.keyGen(0,con[2],0,4)
    end
    return -1
  end
  
  function tl.stagger(cam, dira)
    local com = cam._tablified_s or cam
    if com.cast then com = com._tablified_s or tl.assumption(com,"s") end
    if type(com) ~="table" or #com < 2 then return end
    local deflay = com.holdTime or tl.defaultHold
    local curlay = 0
    local lastLay
    local initas = com.init or 0
    local lease = com.release or "auto"
    local dirge = dira or tl.dir
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
        if dirge == "down" then tl.keyGen(0,that,0,4) end
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
        tl.TaskRun(com.pID,tl.finalStagger,seppy,GetRunningTime(),com.pID)
      end
  
      tl.macroStats[com.pID].stagTimer = GetRunningTime()
    elseif dirge =="up" and tl.macroStats[com.pID].stagTimer ~= nil then
      local timeNow = GetRunningTime() - tl.macroStats[com.pID].stagTimer
        for g=1, #workTab do
          local i = #workTab-g+1
          local tabsi = workTab[i]
          if tabsi[1] < timeNow then
            tl.keyGen(0,tabsi[2],0,4)
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