local OutputLCDMessage,PlayMacro,AbortMacro,OutputLogMessage, sub, gsub, type,concat, tostring, SetBacklightColor, ClearLCD =
OutputLCDMessage,PlayMacro,AbortMacro,OutputLogMessage, string.sub, string.gsub,type, table.concat, tostring, SetBacklightColor, ClearLCD
local lastModC = 0;
---@type MainLibObject
local tl = ...
-->>>>> Functions that interact directly with the LGS software ==========================================

---Put the mouse in a specific mode.
---@param targ number | string | table
---@param fam string
local function _modeSelect(targ,fam)
  if type(fam) == "string" and fam == "all" then
    local famArr = {"m","a","l","k"}
    for g=1, #famArr do
      _modeSelect(targ,famArr[g])
    end
  elseif type(fam) == "table" then
    for g=1, #fam do
      _modeSelect(targ,fam[g])
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
    local function sMode() --sub function to make sure the modes cycle back correctly
      if tl.state[fam].modus < tl.state[fam].modeCount then
        tl.state[fam].modus = tl.state[fam].modus +1
      else
        tl.state[fam].modus = 1
      end
    end
    if targ == nil or targ == 0 then --if the target mode is 0, just cycle to the next mode
      sMode()
    elseif targ <= tl.state[fam].modeCount then --else cycle until you reach the target mode
      while targ ~= tl.state[fam].modus do
        sMode()
      end
    else
      _modeSelect(tl.state[fam].modeCount,fam)
    end
    if not tl.config.keepNameOnLCD then
      tl.put("changed to mode '"..(tl.state[fam].modeConfig[tl.state[fam].modus][1] or tl.state[fam].modus).."' for "..tl.unToken[fam])
    else
      tl.putNoLCD("changed to mode '"..(tl.state[fam].modeConfig[tl.state[fam].modus][1] or tl.state[fam].modus).."' for "..tl.unToken[fam])
      tl.put("")
    end
    if tl.state[fam].modeConfig[targ] and tl.state[fam].modeConfig[targ][2] then tl.backLighter(tl.state[fam].modeConfig[targ][2],fam) end
  end
end

---toggling a different mouse mode as long as a button is held down
---@param md number | string
---@param fam string
local function _togMode(md,fam) --
  if type(fam) == "string" and fam == "all" then
    local famArr = {"m","a","l","k"}
    for g=1, #famArr do
      _togMode(md,famArr[g])
    end
  elseif type(fam) == "table" then
    for g=1, #fam do
      _togMode(md,fam[g])
    end
  else
    if tl.state[fam].dir == "down" then
      tl.state[fam].lastMod = tl.state[fam].modus
      _modeSelect(md,fam)
    else
      _modeSelect(tl.state[fam].lastMod,fam)
      tl.state[fam].lastMod = 0
    end
  end
end

---Change the mode temporarily, revert after a certain number of button presses.
---@param md number | string
---@param num number
---@param fam string
local function _tempMode(md,num,fam)
  if fam == "all" then
    local famArr = {"m","a","l","k"}
    for g=1, #famArr do
      _tempMode(md,num,famArr[g])
    end
  elseif type(fam) == "table" then
    for g=1, #fam do
      _tempMode(md,num,fam[g])
    end
  else
    if tl.state[fam].lastModN == 0 and tl.state[fam].dir == "down" then
      tl.state[fam].lastModN = tl.state[fam].modus
      lastModC = tl.keyCount + ((num and num + ((num > 2 and 1) or -1)) or  0)
      _modeSelect(md,fam)
    end
  end
end

---Play an external LGS macro
---@param nam table|string
local function _playMac(nam)
  local c
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

---toggle an external LGS macro
---@param nam table|string
---@param direction string
local function _togMac(nam,direction)
  local c
  if type(nam) == "table"then
    nam = nam[1]
    c = nam.consume
  end
  if direction and direction ~= "down" then return end
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

---Outputs messages to the Logitech lua log and LCD display
---@vararg string
function tl.put(...)
  for i=0, arg.n do
    if type(arg[i]) ~= "string" then arg[i]=tostring(arg[i])end
  end
  local fin = concat(arg," ")
  OutputLogMessage(fin.."\n")
  if tl.config.outputLCD then
    tl.putLCD(fin)
  end
end

---Outputs messages to the Logitech lua log but not the LCD display
---@vararg string
function tl.putNoLCD(...)
  for i=0, arg.n do
    if type(arg[i]) ~= "string" then arg[i]=tostring(arg[i])end
  end
  local fin = concat(arg," ")
  OutputLogMessage(fin.."\n")
end

---Set the backlight of compatible logitech devices to a specific color
---@param vals number[]|string[]
---@param fam string
function tl.backLighter(vals,fam)
  local finVals
  if #vals == 3 and tl.allType(vals,"number") then
    finVals = vals
  elseif #vals == 1 and type(vals[1]) == "string" then
    local vols , _ = gsub(vals[1],'^#','')
    if #vols == 6 or #vols == 3 then
      if #vols == 3 then vols = gsub(vols,"(.)","%1%1") end
      finVals={tonumber(sub(vols,1,2)),tonumber(sub(vols,3,4)),tonumber(sub(vols,5))}
    end
  end
  if not finVals then error("invalid color value") end
  SetBacklightColor(finVals[1],finVals[2],finVals[3],tl.unLogiToken[fam])
end

---Outputs messages to the Logitech LCD display
---Includes formatters for paginating and splitting.
---@param msg string
---@param dur number
function tl.putLCD(msg,dur) --Outputs messages to lua log
  if not tl.config.outputLCD then return false end
  local duration = dur or tl.config.persistLCD
  if tl.config.outputLCD then
    if tl.config.clearLCD then
      ClearLCD()
      if tl.config.keepNameOnLCD then
        local modeState =""
        if tl.modeUsed == 1 then
          if tl.config.defaultModeTarget == "join" then
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
        OutputLCDMessage(tl.stringBreaker("Profile: "..tl.config.profileName..modeState,tl.config.charsPerLine))
      end
    end
    OutputLCDMessage(tl.stringBreaker(msg,tl.config.charsPerLine),duration)
    for _=1, tl.config.appendNewLines do
      OutputLCDMessage("",duration)
    end
  end
end

---This function keeps the internal script mode in synch with the hardware's mode
---@param torg number
---@param orig number
---@param fam string
function tl.mSync(torg,orig,fam)
  if tl.state[fam].modeCount > 3 or (not tl.state[fam].bindHardwareModes) or tl.state[fam].modeCount < 2 then return end
  local mod = orig or tl.state[fam].modus
  local targ = torg or mod+1
  if targ == 0 then targ = mod + 1 end
  if targ > tl.state[fam].modeCount then targ = 1 end
  if mod == targ then return end
  local function pm()
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

---set the mode back to the standard mode once a enough button presses have been executed.
---@param fam string
function tl.untempMode(fam)
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
    if tl.state[fam].lastModN ~=0 and (tl.keyCount - lastModC) > 2 then
      _modeSelect(tl.state[fam].lastModN,fam)
      tl.state[fam].lastModN = 0
      tl.putNoLCD("mode reset")
    end
  end
end

---Wrapper function for internal macro control methods
---@param cmd GenericMacro
---@param dir string
---@param dirMatch boolean
function tl.handleMacros(cmd,dir,dirMatch)
  if type(cmd) == "table" and cmd.play then
    if cmd.play == "toggle" then
      _togMac(cmd)
    elseif cmd.play == "hold" then
      _togMac(cmd,dir)
    end
  elseif dirMatch then
    _playMac(cmd)
  end
end

---Wrapper for internal mode changing functions
---@param target number|string|table
---@param mod string
---@param fam string
---@param dirMatch boolean
function tl.modeWrapper(target,mod,fam,dirMatch)
  mod = mod or "normal"
  if mod == "normal" then
   if dirMatch then _modeSelect(target, fam) end
  elseif mod == "toggle"then
    _togMode(target, fam)
  else
    _tempMode(target, mod, fam)
  end
end