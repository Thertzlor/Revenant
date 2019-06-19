local tl = ...

--->>>> Functions that directly listen to events =================================================================================================

function OnEvent(event, arg, family) -- Triggers whenever a mouse button is pressed, virtual or real.
    tl.EventReceiver(event,arg,family)
    tl.DoTasks()
    tl.Poll(event, arg, family, st)
    local fam = tl.token(family)
    if event == "MOUSE_BUTTON_PRESSED" and arg == tl.state[fam].sKey then
      tl.state[fam].mBeforeG = tl.state[fam].modus
    elseif tl.state[fam] and arg == tl.state[fam].sKey and  tl.state[fam].mBeforeG ~= tl.state[fam].modus then
      tl.mSync(tl.state[fam].modus,tl.state[fam].mBeforeG,fam)
      tl.state[fam].mBeforeG = tl.state[fam].modus
    end
  end

function tl.launch() --compile and display stats on script startup
    tl.quickGen(tl.assign.start)
    local defnum = 0
    local nanum = 0
    local gennum = tl.tabNum
    local monum = #tl.resolutions
    local moray = {}
    local moplural = ""
    if monum > 1 then moplural = "s" end
    for k,_ in pairs(tl.assign.key) do if k ~= "pID" then defnum = defnum+1 end end
    for _,i in pairs(tl.macroStats) do if i.macro and i.macro.name then nanum = nanum+1 end end
    for g=1, #tl.resolutions do local mon = tl.resolutions[g]
      moray[#moray+1] = mon[1].."x"..mon[2]    
    end
  
    tl.putNoLCD("\n\nG600 Profile '"..tl.profileName.."' powered by T-lib v"..tl.version.." succesfully launched.\n"..tl.findEx.."\nCurrent stats:\nButtons Assigned: "..defnum.."\nNamed Sequences: "..nanum.."\nGenerically Identified Tables: "..gennum.."\n"..monum.." Monitor"..moplural.." configured ("..table.concat(moray,",")..")")
    if tl.outputLCD == 1 then tl.putLCD('')end
  end
  
  function tl.shutDown() --send shutdown message, abort all tasks, and set mode back to 1.
    tl.exitus = 1
    tl.quickGen(tl.assign.exit)
    tl.putNoLCD("Profile '"..tl.profileName.."' deactivated.")
    if tl.outputLCD == 1 then ClearLCD()end
    tl.multiAbort("")
    tl.molect(1,"all")
  end
  
  function tl.defTab(num,fam) --compile table of pressed keys with all key, g-shift and mode properties to be stored for evaluation
    if num == tl.state[fam].sKey or not tl.press then return end
    local keyNum = fam..num

    tl.downs[keyNum] = tl.downs[keyNum] or {}
    local saver = tl.downs[keyNum]

    if tl.state[fam].dir == "down" then 
      saver.shift = tl.state[fam].shift
      saver.mode = tl.state[fam].modus
      saver.modKeys = tl.mods
    elseif tl.state[fam].dir == "up" then
      saver.shiftUp = tl.state[fam].shift
      saver.modeUp = tl.state[fam].modus
      saver.modKeysUp = tl.mods

      tl.downs[keyNum] = nil
    end
  end
  
  function tl.setArgsB(ev,ar,fam) --IDs for modifiers are set here
    local famto = tl.token(fam)
    tl.altMode = 0
    tl.mods = ""
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
      tl.state[famto].dir = "down"
      tl.press = true
    elseif ev == "MOUSE_BUTTON_RELEASED" then
      tl.state[famto].dir = "up"
    end
  
    if ar == tl.state[famto].sKey then
      tl.but = 0
      if tl.state[famto].dir == "down" then
        tl.state[famto].shift=1
      elseif tl.state[famto].dir == "up" then
        tl.state[fam].shift=0
      end
    else
      tl.but = ar
    end
  
    tl.defTab(ar,fam)
  
    --At this point, a status message is generated, for the console to show current button states.
  
    local mads,tabs,tabs2
  
      if tl.mods == nil or #tl.mods == 0 then
      mads=""
    else
      mads = " , modifiers pressed: "..tl.mods
    end

    tabs = ""

    for k,_ in pairs(tl.downs) do
      if tabs == "" then
        tabs = " , Keys Down = "..k
      else
        tabs = tabs..", "..k
      end
    end
  
    local logKey = ""
    if tl.customNames == 1 then
      logKey = " ("..tl.rename[fam..ar]..")"
    end
    local lKey = " , Last Keys: "..table.concat(tl.lastKeysDown,",").."(down) , "..table.concat(tl.lastKeysUp,",").."(up)"

    tl.putNoLCD("Key-Event = "..tl.state[fam].dir..", Current Key = "..fam..ar..logKey..", G-Shift = "..tl.state[fam].shift..", Mode = "..tl.pMod..tabs..mads..lKey)
  end
  
  function tl.setArgsE() --Make sure, no buttons that have been listed up are still listed as pressed down.
    tl.conKey = 0

  end
  
  function tl.newSet(k,fam) --evaluate inputs to see what kind of bindings they have
    local bCode
    if tl.customNames == 1 then
      bCode = tl.rename[fam..k]
    else
      bCode = fam..k
    end
  
    if tl.logEmpty == 1 then
      tl.mouseMem(k,tl.state[fam].dir)
    end
  
    local args = tl.assign.key[bCode]
    if type(k) ~= "number" or k == 0 or k > tl.state[fam].buttonCount then --can't press buttons that don't exist...
      error(" invalid mouse button")
    elseif args == nil then
      return
    elseif type(args) == "string" then
      tl.keyGen(k,fam,args,bCode)
    elseif type(args) == "table" then
      if tl.multiTab(args) == true then
        for num=1,#args do local coms = args[num]
          if #coms ~= 0 then
            tl.keyGen(k,fam,coms,bCode)
          end
        end
      else
        tl.keyGen(k,fam,args,bCode)
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
      tl.tablecrawl(tl.assign)
      tl.launch()
    elseif event == "PROFILE_DEACTIVATED" then
      tl.shutDown()
    elseif family ~= tl.PollFamily then
      local famName = tl.token(family)
      tl.setArgsB(event,arg,famName)
      tl.newSet(arg,famName)
      tl.untempMode(famName)
      tl.setArgsE(event,arg)
      if arg ~= tl.state[famName].sKey then
        tl.keyCount = tl.keyCount +1 --counting keys for temporary cycles
      end
    end
  end