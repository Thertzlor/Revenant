local tl = ...

---->>> Functions that interact directly with the LGS software ==========================================

function tl.put(...) --Outputs messages to lua log
    for i=0, arg.n do
    if type(arg[i]) ~= "string" then arg[i]=tostring(arg[i])end
    end
    local fin = table.concat(arg," ")
    OutputLogMessage(fin.."\n")
    if tl.outputLCD == 1 then
      tl.putLCD(fin)
    end
  end

  function tl.putNoLCD(...) --Outputs messages to lua log
    for i=0, arg.n do
    if type(arg[i]) ~= "string" then arg[i]=tostring(arg[i])end
    end
    local fin = table.concat(arg," ")
    OutputLogMessage(fin.."\n")
  end

  function tl.putLCD(msg,dur) --Outputs messages to lua log
    if tl.outputLCD == 0 then return false end
    local duration = dur or tl.persistLCD
    if tl.outputLCD == 1 then 
      if tl.clearLCD == 1 then
        ClearLCD()
        if tl.keepNameOnLCD ==1 then
          local modeState =""
          local famlist = {"Mouse","Keyboard","LHC","Audio"}
          for g=1, #famlist do local l = famlist[g]
            if tl.modes[tl.state[tl.token(l)].modus] then local mod = tl.modes[tl.state[tl.token(l)].modus]
              modeState="\n"..l.." Mode:"..mod[1]
            end
          end
          OutputLCDMessage("Profile: "..tl.profileName..modeState)
        end
      end
      OutputLCDMessage(msg,duration)
      for g=1, tl.appendNewLines do
        OutputLCDMessage("",duration)
      end 
    end
  end
  
  
  function tl.profileCycle() -- cycles to the next LOGITECH Profile
    tl.normKey(tl.cycleCombi,nil,0,1)
  end
  
  function tl.mSync(torg,orig,fam) --This function keeps the internal script mode in synch with the hardware's mode
    if tl.maxMode > 3 or tl.modeBound == 0 or tl.maxMode == 1 then return end
    local mod = orig or tl.state[fam].modus
    local targ = torg or mod+1
    if targ == 0 then targ = mod + 1 end
    if targ > tl.maxMode then targ = 1 end
    if mod == targ then return end
    function pm()
      AbortMacro();
      PlayMacro("Mode Switch (G600)")
      --PlayMacro("Moduswechsel (G600)")
      mod = mod+1
    end
    if mod > targ then
      while tl.maxMode >= mod do
        pm()
      end
      if tl.maxMode ==2 then pm() end
      mod = 1
    end
    while targ > mod do
      pm()
    end
  end
  
  function tl.molect(targ,fam) --Put the mouse in a specific mode.
    if type(fam) == "string" and fam == "all" then
      local famArr = {"m","a","l","k"}
      for g=1, #famArr do
        tl.molect(targ,famArr[g])
      end
    elseif type(fam) == "table" then 
      for g=1, #fam do
        tl.molect(targ,fam[g])
      end
    else
      fam = tl.token(fam)
      if type(targ) == "table"then targ = targ[1] end
      if type(targ) ~= "number" then
        tl.checkM() return
      elseif tl.maxMode == 1 or tl.state[fam].modus == targ then
        return
      end
      if tl.state[fam].shift == 0 then
        tl.mSync(targ,nil,fam)
      end
      function sMode() --sub function to make sure the modes cycle back correctly
        if tl.state[fam].modus < tl.maxMode then
          tl.state[fam].modus = tl.state[fam].modus +1
        else
          tl.state[fam].modus = 1
        end
      end
      if targ == nil or targ == 0 then --if the target mode is 0, just cycle to teh next mode
        sMode()
      elseif targ <= tl.maxMode then --else cycle until you reach teh target mode
        while targ ~= tl.state[fam].modus do
          sMode()
        end
      else
        tl.molect(tl.maxMode,fam)
      end
      if tl.autoHot == 1 then
        PressAndReleaseKey("f15")
      end
      tl.put("changed to mode "..tl.state[fam].modus)
    end
  end
  
  function tl.togMode(md,fam) --toggling a different mouse mode as long as a button is held down
    if type(fam) == "string" and fam == "all" then
      local famArr = {"m","a","l","k"}
      for g=1, #famArr do
        tl.togMode(targ,famArr[g])
      end
    elseif type(fam) == "table" then 
      for g=1, #fam do
        tl.togMode(targ,fam[g])
      end
    else
      if tl.state[fam].dir == "down" then
        tl.state[fam].lastMod = tl.state[fam].modus
        tl.molect(md,fam)
      else
        tl.molect(tl.state[fam].lastMod,fam)
        tl.state[fam].lastMod=0
      end
    end
  end
  
  function tl.tempMode(md,fam) --changing the mode temporarily, but even after the button is released.
    if type(fam) == "string" and fam == "all" then
      local famArr = {"m","a","l","k"}
      for g=1, #famArr do
        tl.tempMode(targ,famArr[g])
      end
    elseif type(fam) == "table" then 
      for g=1, #fam do
        tl.tempMode(targ,fam[g])
      end
    else
      if tl.state[fam].lastModN == 0 and tl.state[fam].dir == "down" then
        tl.state[fam].lastModN = tl.state[fam].modus
        tl.lastModC = tl.keyCount
        tl.molect(md,fam)
      end
    end
  end
  
  function tl.untempMode(fam) --set the mode back to the standard mode once a single button press has been executed.
    if type(fam) == "string" and fam == "all" then
      local famArr = {"m","a","l","k"}
      for g=1, #famArr do
        tl.untempMode(famArr[g])
      end
    elseif type(fam) == "table" then 
      for g=1, #fam do
        tl.untempMode(fam[g])
      end
    else
      if tl.state[fam].lastModN ~=0 and (tl.keyCount - tl.lastModC) > 2 then
        tl.molect(tl.state[fam].lastModN,fam)
        tl.state[fam].lastModN = 0
        tl.put("mode reset")
      end
    end
  end
  
  function tl.checkM() --tells the autohotkey GUI to display the current mode.
    if tl.autoHot == 1 then
      PressAndReleaseKey("f16")
    end
  end
  
  function tl.PlayMac(nam,c) --play an external LGS macro
    if type(nam) == "table"then
    nam = nam[1]
    c = nam.consume
    end
    if c == 2 or c == 3 then
      AbortMacro()
      tl.macPlay = false
    end
    PlayMacro(nam)
  end
  
  function tl.togMac(nam,c,d) --toggle an external LGS macro
    if type(nam) == "table"then
      nam = nam[1]
      c = nam.consume
    end
    if d and d ~= "down" then return end
    if tl.macPlay == false then
      if c == 2 or c==3 then
        AbortMacro()
        tl.macPlay = false
      end
      PlayMacro(nam)
      tl.macPlay = true
    else
      AbortMacro()
      tl.macPlay = false
    end
  end