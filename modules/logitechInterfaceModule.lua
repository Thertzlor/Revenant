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
          if tl.modes[tl.modus] then local mod = tl.modes[tl.modus]
            modeState="\nMode:"..mod[1]
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
  
  function tl.mSync(torg,orig) --This function keeps the internal script mode in synch with the hardware's mode
    if tl.maxMode > 3 or tl.modeBound == 0 or tl.maxMode == 1 then return end
    local mod = orig or tl.modus
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
  
  function tl.molect(targ) --Put the mouse in a specific mode.
    if type(targ) == "table"then targ = targ[1] end
    if type(targ) ~= "number" then
      tl.checkM() return
    elseif tl.maxMode == 1 or tl.modus == targ then
      return
    end
    if tl.shiftor == 0 then
      tl.mSync(targ)
    end
    function sMode() --sub function to make sure the modes cycle back correctly
      if tl.modus < tl.maxMode then
        tl.modus = tl.modus +1
      else
        tl.modus = 1
      end
    end
    if targ == nil or targ == 0 then --if the target mode is 0, just cycle to teh next mode
      sMode()
    elseif targ <= tl.maxMode then --else cycle until you reach teh target mode
      while targ ~= tl.modus do
        sMode()
      end
    else
      tl.molect(tl.maxMode)
    end
    if tl.autoHot == 1 then
      PressAndReleaseKey("f15")
    end
    tl.put("changed to mode "..tl.modus)
  end
  
  function tl.togMode(md) --toggling a different mouse mode as long as a button is held down
    if tl.dir == "down" then
      tl.lastMod = tl.modus
      tl.molect(md)
    else
      tl.molect(tl.lastMod)
      tl.lastMod=0
    end
  end
  
  function tl.tempMode(md) --changing the mode temporarily, but even after the button is released.
    if tl.lastModN == 0 and tl.dir == "down" then
      tl.lastModN = tl.modus
      tl.lastModC = tl.keyCount
      tl.molect(md)
    end
  end
  
  function tl.untempMode() --set the mode back to the standard mode once a single button press has been executed.
    if tl.lastModN ~=0 and (tl.keyCount - tl.lastModC) > 2 then
      tl.molect(tl.lastModN)
      tl.lastModN = 0
      tl.put("mode reset")
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