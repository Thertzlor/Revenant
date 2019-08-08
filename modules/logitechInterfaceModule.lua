local tl = ...
local OutputLCDMessage,PlayMacro,AbortMacro,OutputLogMessage = OutputLCDMessage,PlayMacro,AbortMacro,OutputLogMessage
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

function tl.backLighter(vals,fam)
  local SetBacklightColor = SetBacklightColor
  local finVals
  if #vals == 3 and tl.allType(vals,"number") then
    finVals = vals
  elseif #vals == 1 and type(vals[1]) == "string" then
    local vols , _ = string.gsub(vals[1],'^#','')
    if #vols == 6 or #vols == 3 then
      if #vols == 3 then vols = string.gsub(vols,"(.)","%1%1") end
      finVals={tonumber(string.sub(vols,1,2)),tonumber(string.sub(vols,3,4)),tonumber(string.sub(vols,5))}
    end
  end
  if not finVals then error("invalid color value") end
  SetBacklightColor(finVals[1],finVals[2],finVals[3],tl.unLogiToken[fam])
end

function tl.putLCD(msg,dur) --Outputs messages to lua log
  local ClearLCD = ClearLCD
  if tl.outputLCD == 0 then return false end
  local duration = dur or tl.persistLCD
  if tl.outputLCD == 1 then
    if tl.clearLCD == 1 then
      ClearLCD()
      if tl.keepNameOnLCD ==1 then
        local modeState =""
        if tl.modeUsed == 1 then
          if tl.defaultModeTarget == "join" then
            modeState = "\nMode: "..tl.state.m.modus
          else
            for g=1, #tl.families do local l = tl.families[g]
              local tok = tl.token(l)
                if tl.state[tok].buttonCount ~= 0 and tl.state[tok].modeCount > 1 then
                  modeState=modeState.."\n"..tl.unToken[tok].." Mode: "
                  if tl.state[tok].modeConfig[tl.state[tok].modus] then local mod = tl.state[tok].modeConfig[tl.state[tok].modus]
                    modeState=modeState..mod[1]
                  else
                    modeState=modeState..tl.state[tok].modus
                  end
                end
              end
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

function tl.mSync(torg,orig,fam) --This function keeps the internal script mode in synch with the hardware's mode
  if tl.state[fam].modeCount > 3 or tl.state[fam].bindHardwareModes == 0 or tl.state[fam].modeCount < 2 then return end
  local mod = orig or tl.state[fam].modus
  local targ = torg or mod+1
  if targ == 0 then targ = mod + 1 end
  if targ > tl.state[fam].modeCount then targ = 1 end
  if mod == targ then return end
  function pm()
    AbortMacro();
    PlayMacro("Mode Switch (G600)")
    --PlayMacro("Moduswechsel (G600)")
    mod = mod+1
  end
  if mod > targ then
    while tl.state[fam].modeCount >= mod do
      pm()
    end
    if tl.state[fam].modeCount ==2 then pm() end
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
    if type(targ) ~= "number" then return
    elseif tl.state[fam].modeCount < 2 or tl.state[fam].modus == targ then
      return
    end
    if tl.state[fam].shift == 0 then
      tl.mSync(targ,nil,fam)
    end
    function sMode() --sub function to make sure the modes cycle back correctly
      if tl.state[fam].modus < tl.state[fam].modeCount then
        tl.state[fam].modus = tl.state[fam].modus +1
      else
        tl.state[fam].modus = 1
      end
    end
    if targ == nil or targ == 0 then --if the target mode is 0, just cycle to teh next mode
      sMode()
    elseif targ <= tl.state[fam].modeCount then --else cycle until you reach teh target mode
      while targ ~= tl.state[fam].modus do
        sMode()
      end
    else
      tl.molect(tl.state[fam].modeCount,fam)
    end
    if tl.keepNameOnLCD == 0 then
      tl.put("changed to mode '"..(tl.state[fam].modeConfig[tl.state[fam].modus][1] or tl.state[fam].modus).."' for "..tl.unToken[fam])
    else
      tl.putNoLCD("changed to mode '"..(tl.state[fam].modeConfig[tl.state[fam].modus][1] or tl.state[fam].modus).."' for "..tl.unToken[fam])
      tl.put("")
    end
    if tl.state[fam].modeConfig[targ] and tl.state[fam].modeConfig[targ][2] then tl.backLighter(tl.state[fam].modeConfig[targ][2],fam) end 
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
      tl.putNoLCD("mode reset")
    end
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