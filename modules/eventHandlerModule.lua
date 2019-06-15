local tl = ...

--->>>> Functions that directly listen to events =================================================================================================

function OnEvent(event, arg, family) -- Triggers whenever a mouse button is pressed, virtual or real.
    tl.EventReceiver(event,arg,family)
    tl.DoTasks()
    tl.Poll(event, arg, family, st)
    if event == "MOUSE_BUTTON_PRESSED" and arg == tl.sKey then
      tl.mBeforeG = tl.modus
    elseif arg == tl.sKey and  tl.mBeforeG ~= tl.modus then
      tl.mSync(tl.modus,tl.mBeforeG)
      tl.mBeforeG = tl.modus
    end
  end
  

function tl.launch() --compile and display stats on script startup
    tl.quickGen(tl.assign.start)
    local defnum = 0
    local nanum = 0
    local gennum = #tl.arn
    local monum = #tl.resolutions
    local moray = {}
    local moplural = ""
    if monum > 1 then moplural = "s" end
    for k,_ in pairs(tl.assign.key) do if k ~= "pID" then defnum = defnum+1 end end
    for _,i in pairs(tl.macroStats) do if i.macro and i.macro.name then nanum = nanum+1 end end
    for g=1, #tl.resolutions do local mon = tl.resolutions[g]
      moray[#moray+1] = mon[1].."x"..mon[2]    
    end

  
  
    tl.put("\n\nG600 Profile '"..tl.profileName.."' powered by T-lib v"..tl.version.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n"..monum.." Monitor"..moplural.." configured ("..table.concat(moray,",")..")")
    if tl.autoHot == 1 then
      PlayMacro("~actiScript")
      tl.wait(250)
      PressAndReleaseKey("f13")
      for _ = tl.maxMode, 1, -1 do
        PressAndReleaseKey("f14")
      end
  
      for _ = tl.nameIndex, 1, -1 do
        PressAndReleaseKey("f17")
      end
    end
  end
  
  function tl.shutDown() --send shutdown message, abort all tasks, and set mode back to 1.
    tl.exitus = 1
    tl.quickGen(tl.assign.exit)
    tl.put("Profile '"..tl.profileName.."' deactivated.")
    tl.multiAbort("")
    tl.molect(1,true)
  end
  
  function tl.defTab(num) --compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
    if num ~= tl.sKey then
      if tl.press == true then
        local cody = num
        if tl.shiftor == true then
          cody = cody.."t"
        else
          cody = cody.."f"
        end
  
        cody = cody..tl.modus
        cody = cody..tl.mods
  
        local curNum = {}
        local curSt = string.match(cody, "%a")
        local curMo = string.match(cody,"%a+$")
  
        for i in string.gmatch(cody, "%d+") do
          curNum[#curNum+1] = i
        end
  
        if tl.dir == "up" then --this part makes sure that if the state of of modifiers has changed since a button has been pressed, keyup events of the same button will still funtion correctly
          for i=1,#tl.downs do local obj = tl.downs[i]
            local tempNum = {}
            local tempSt =  string.match(obj, "%a")
            local tempMo = string.match(obj, "%a+$")
  
            for d in string.gmatch(obj, "%d+") do
              tempNum[#tempNum+1] = d
            end
            if tempNum[1] == curNum[1]  then
              if tempSt ~= curSt then
                tl.invertG=true
              else
                tl.invertG = false
              end
              if tempNum[2] ~= curNum[2] then
                tl.altMode = tempNum[2]
              else
                tl.altMode = 0
              end
              if curMo ~= tempMo then
                tl.altMods = tempMo
              else
                tl.altMods = 0
              end
              table.remove(tl.downs,i)
            end
          end
        else
          tl.downs[#tl.downs+1] = cody
        end
      end
    end
  end
  
  function tl.setArgsB(ev,ar) --IDs for modifiers are set here
    tl.invertG = false
    tl.altMode = 0
    tl.mods = ""
    tl.finMods=""
    tl.altMods=0
    tl.conKey = 0
    local morail = {
      {"ralt","ra"},
      {"lalt","la"},
      {"alt","ga"},
      {"rshift","rs"},
      {"lshift","ls"},
      {"shift","gs"},
      {"rctrl","rc"},
      {"lctrl","lc"},
      {"ctrl","gc"}
    }
  
    for i=1,#morail do local obj = morail[i]
      if IsModifierPressed(obj[1]) then
        tl.mods = tl.mods..obj[2]
      end
    end
  
    if ev == "MOUSE_BUTTON_PRESSED" then
      tl.dir = "down"
      tl.press = true
    elseif ev == "MOUSE_BUTTON_RELEASED" then
      tl.dir = "up"
    end
  
    if ar == tl.sKey then
      tl.but = 0
      if tl.dir == "down" then
        tl.shiftor=true
      elseif tl.dir == "up" then
        tl.shiftor=false
      end
    else
      tl.but = ar
    end
  
    tl.defTab(ar)
  
    if tl.invertG == true then
      tl.shiftus = not tl.shiftor
    else
      tl.shiftus = tl.shiftor
    end
  
    if tl.altMode ~= 0 then
      tl.pMod = tl.altMode
    else
      tl.pMod = tl.modus
    end
  
    if tl.altMods ~= 0 then
      tl.finMods = tl.altMods
    else
      tl.finMods = tl.mods
    end
    --At this point, a status message is generated, for the console to show current button states.
  
    local mads,tabs,tabs2
  
      if tl.finMods == nil or #tl.finMods == 0 then
      mads=""
    else
      mads = " , modifiers pressed: "..tl.finMods
    end
  
    if table.getn(tl.downs) == 0 then
      tabs = ""
    else
      tabs = " , Keys Down = "..table.concat(tl.downs,",")
    end
  
    if #tl.dump(tl.cList) == 0 then
      tabs2 = ""
    else
      tabs2 = " , keys locked: "..tl.dump(tl.cList)
    end
    local logKey = ""
    if tl.logicalMouse == 1 then
      logKey = " ("..tl.reMouse["m"..ar]..")"
    end
    local lKey = " , Last Keys: "..table.concat(tl.lastKeysDown,",").."(down) , "..table.concat(tl.lastKeysUp,",").."(up)"
  
    OutputLogMessage("Key-Event = %s , Current Key = %s"..logKey.." , G-Shift = %s , Mode = %s%s%s%s%s\n", tl.dir, ar, tostring(tl.shiftus), tl.pMod, tabs, mads, tabs2, lKey)
  end
  
  function tl.setArgsE() --Make sure, no buttons that have been listed up are still listed as pressed down.
    if tl.invertG == true then
      tl.shiftus = tl.shiftor
    end
    tl.conKey = 0
    tl.finMods = tl.mods
  
    if tl.dir == "up"then
      for k in pairs(tl.cList) do
        if type(k) == 'string' then
          if string.match(k,"_"..tl.but.."t%-?%g*") then
            tl.cList[k]=nil
          end
        end
      end
    end
  end
  
  function tl.newSet(k) --evaluate inputs to see what kind of bindings they have
    local bCode
    if tl.logicalMouse == 1 then
      bCode = tl.reMouse["m"..k]
    else
      bCode = "m"..k
    end
  
    if tl.logEmpty == 1 then
      tl.mouseMem(k,tl.dir)
    end
  
    local args = tl.assign.key[bCode]
  
    if type(k) ~= "number" or k == 0 or k > tl.buttonCount then --can't press buttons that don't exist...
      error(" invalid mouse button")
    elseif args == nil then
      return
    elseif type(args) == "string" then
      tl.keyGen(k,args,bCode)
    elseif type(args) == "table" then
      if tl.multiTab(args) == true then
        for num=1,#args do local coms = args[num]
          if #coms ~= 0 then
            tl.keyGen(k,coms,bCode)
          end
        end
      else
        tl.keyGen(k,args,bCode)
      end
    end
  end
  
  function tl.EventReceiver(event,arg,family) --set how to react to the differend kind of events
    if family == "" then family = "audio" end
    if string.sub(event,1,7) == "PROFILE" then family = "profile" end
    if event == "PROFILE_ACTIVATED" then
      tl.compileScreenCoordinates();
      tl.switchCustom()
      tl.funcRayD = tl.intersect(tl.defaultFuncs,tl.upDownFuncs)
      tl.funcRayU = tl.intersect(tl.upFuncs,tl.funcRayD)
      tl.funcRayM = tl.intersect(tl.macFuncs,tl.funcRayD)
      tl.wipe(tl.assign)
      tl.prepKeys()
      tl.OnPollEventIni()
      tl.InitPolling()
      tl.setKeys()
      tl.toKey(tl.assign)
      tl.compileAssignments(tl.assign)
      tl.setDefaults(tl.assign.key)
      tl.inherit(tl.assign.key,1)
      tl.tablecrawl(tl.assign)
      if tl.showCompiled == 1 then
        tl.prettyTab(tl.assign.key,"Assignments:")
        if #tl.assign.start ~= 0 then
          tl.prettyTab(tl.assign.start,"Start Function:")
        end
        if #tl.assign.exit ~= 0 then
          tl.prettyTab(tl.assign.exit,"Exit Function:")
        end
        if #tl.assign.null ~= 0 then
          tl.prettyTab(tl.assign.null,"Null Storage:")
        end
      end
     
      tl.launch()
    elseif event == "PROFILE_DEACTIVATED" then
      tl.shutDown()
    elseif family ~= tl.PollFamily then
      tl.setArgsB(event,arg)
      tl.newSet(arg)
      tl.untempMode()
      tl.setArgsE(event,arg)
      if arg ~= tl.sKey then
        tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
      end
    end
  end