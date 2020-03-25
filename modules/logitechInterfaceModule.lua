---@type MainLibObject
local tl = ...
local OutputLCDMessage,  PlayMacro,  AbortMacro,  OutputLogMessage,  sub,  gsub,  type,  concat,  tostring,  SetBacklightColor,  ClearLCD =
  (tl.config.hubMode and tl.helperUtils.dummy or OutputLCDMessage),  PlayMacro,  AbortMacro,  OutputLogMessage,  tl.utf8.sub,  tl.utf8.gsub,  type,  table.concat,  tostring,  SetBacklightColor,  tl.config.hubMode and tl.helperUtils.dummy or ClearLCD
--=============================================================
---@type LogitechInterface
---: Functions that interact directly with the LGS software
tl.logitech = {}

local lastModC = 0
local unToken = {m = "Mouse", k = "Keyboard", a = "Audio", l = "LHC"}
local unLogiToken = {m = "mouse", k = "kb", a = "audio", l = "lhc"}
local macPlay = false

local function _cycleMode(fam) --sub function to make sure the modes cycle back correctly
  tl.deviceState[fam].modus = (tl.deviceState[fam].modus < tl.deviceState[fam].modeCount) and tl.deviceState[fam].modus + 1 or 1
end

---Put the mouse in a specific mode.
---@param targ number | string | table
---@param fam string
local function _modeSelect(targ, fam)
  if type(fam) == "string" and fam == "all" then
    local famArr = {"m", "a", "l", "k"}
    for g = 1, #famArr do
      _modeSelect(targ, famArr[g])
    end
  elseif type(fam) == "table" then
    for g = 1, #fam do
      _modeSelect(targ, fam[g])
    end
  else
    fam = tl.str:token(fam)
    if type(targ) == "table" then
      targ = targ[1]
    end
    targ = tl.tbl:cycleIndex(tl.deviceState[fam].modeCount, targ, tl.deviceState[fam].modus)
    if type(targ) ~= "number" or tl.deviceState[fam].modeCount < 2 or tl.deviceState[fam].modus == targ then
      return
    end
    if tl.deviceState[fam].shift == 0 then
      tl.logitech:syncModes(targ, nil, fam)
    end
    if targ == nil or targ == 0 then --if the target mode is 0, just cycle to the next mode
      _cycleMode(fam)
    elseif targ <= tl.deviceState[fam].modeCount then --else cycle until you reach the target mode
      while targ ~= tl.deviceState[fam].modus do
        _cycleMode(fam)
      end
    else
      _modeSelect(tl.deviceState[fam].modeCount, fam)
    end
    if not tl.config.keepNameOnLCD then
      tl:put(
        "changed to mode '" ..
          (tl.deviceState[fam].modeConfig[tl.deviceState[fam].modus][1] or tl.deviceState[fam].modus) .. "' for " .. unToken[fam]
      )
    else
      tl.logitech:putNoLCD(
        "changed to mode '" ..
          (tl.deviceState[fam].modeConfig[tl.deviceState[fam].modus][1] or tl.deviceState[fam].modus) .. "' for " .. unToken[fam]
      )
      tl:put("")
    end
    if tl.deviceState[fam].modeConfig[targ] and tl.deviceState[fam].modeConfig[targ][2] then
      tl.logitech:backLightControl(tl.deviceState[fam].modeConfig[targ][2], fam)
    end
  end
end

---toggling a different mouse mode as long as a button is held down
---@param md number | string
---@param fam string
local function _toggleMode(md, fam) --
  if type(fam) == "string" and fam == "all" then
    local famArr = {"m", "a", "l", "k"}
    for g = 1, #famArr do
      _toggleMode(md, famArr[g])
    end
  elseif type(fam) == "table" then
    for g = 1, #fam do
      _toggleMode(md, fam[g])
    end
  else
    if tl.deviceState[fam].dir == "down" then
      tl.deviceState[fam].lastMod = tl.deviceState[fam].modus
      _modeSelect(md, fam)
    else
      _modeSelect(tl.deviceState[fam].lastMod, fam)
      tl.deviceState[fam].lastMod = 0
    end
  end
end

---Change the mode temporarily, revert after a certain number of button presses.
---@param md number | string
---@param num number
---@param fam string
local function _temporaryMode(md, num, fam)
  if fam == "all" then
    local famArr = {"m", "a", "l", "k"}
    for g = 1, #famArr do
      _temporaryMode(md, num, famArr[g])
    end
  elseif type(fam) == "table" then
    for g = 1, #fam do
      _temporaryMode(md, num, fam[g])
    end
  else
    if tl.deviceState[fam].lastModN == 0 and tl.deviceState[fam].dir == "down" then
      tl.deviceState[fam].lastModN = tl.deviceState[fam].modus
      lastModC = tl.scriptStates.keyCount + ((num and num + ((num > 2 and 1) or -1)) or 0)
      _modeSelect(md, fam)
    end
  end
end

---Play an external LGS macro
---@param nam table|string
local function _playExternalMacro(nam)
  local c
  if type(nam) == "table" then
    nam = nam[1]
    c = nam.consume
  end
  if c == 2 or c == 3 then
    AbortMacro()
    macPlay = false
  end
  PlayMacro(nam)
end

---toggle an external LGS macro
---@param nam table|string
---@param direction string
local function _toggleExternalMacro(nam, direction)
  local c
  if type(nam) == "table" then
    nam = nam[1]
    c = nam.consume
  end
  if direction and direction ~= "down" then
    return
  end
  if macPlay == false then
    if c == 2 or c == 3 then
      AbortMacro()
      macPlay = false
    end
    PlayMacro(nam)
    macPlay = true
  else
    AbortMacro()
    macPlay = false
  end
end

local function _iterateMode(mod)
  AbortMacro()
  PlayMacro("Mode Switch (G600)")
  return mod + 1
end

---Outputs messages to the Logitech LCD display
---Includes formatters for paginating and splitting.
---@param msg string
---@param dur number
local function _putLCD(msg, dur) --Outputs messages to lua log
  if not tl.config.outputLCD then
    return false
  end
  local duration = dur or tl.config.persistLCD
  if not tl.config.outputLCD then
    return
  end
  if tl.config.clearLCD then
    ClearLCD()
    if tl.config.keepNameOnLCD then
      local modeState = ""
      if tl.scriptStates.modeUsed == 1 then
        if tl.config.defaultModeTarget == "join" then
          modeState = "\nMode: " .. tl.deviceState.m.modus
        else
          for g = 1, #tl.stringPresets.families do
            local l = tl.stringPresets.families[g]
            local tok = tl.str:token(l)
            if tl.deviceState[tok].buttonCount ~= 0 and tl.deviceState[tok].modeCount > 1 then
              modeState = modeState .. "\n" .. unToken[tok] .. " Mode: "
              if tl.deviceState[tok].modeConfig[tl.deviceState[tok].modus] then
                modeState = modeState .. tl.deviceState[tok].modeConfig[tl.deviceState[tok].modus][1]
              else
                modeState = modeState .. tl.deviceState[tok].modus
              end
            end
          end
        end
      end
      OutputLCDMessage(tl.str:stringBreaker("Profile: " .. tl.config.profileName .. modeState, tl.config.charsPerLine))
    end
  end
  OutputLCDMessage(tl.str:stringBreaker(msg, tl.config.charsPerLine), duration)
  for _ = 1, tl.config.appendNewLines do
    OutputLCDMessage("", duration)
  end
end

---Outputs messages to the Logitech lua log and LCD display
---@vararg string
function tl:put(self,...)
  for i = 1, arg.n do
    if type(arg[i]) ~= "string" then
      arg[i] = tostring(arg[i])
    end
  end
  local fin = concat(arg, " ")
  OutputLogMessage(fin .. "\n")
  if tl.config.outputLCD then
    _putLCD(fin)
  end
end

---Outputs messages to the Logitech lua log but not the LCD display
---@vararg string
function tl.logitech:putNoLCD(...)
  for i = 1, arg.n do
    if type(arg[i]) ~= "string" then
      arg[i] = tostring(arg[i])
    end
  end
  local fin = concat(arg, " ")
  OutputLogMessage(fin .. "\n")
end

---Set the backlight of compatible logitech devices to a specific color
---@param vals number[]|string[]
---@param fam string
function tl.logitech:backLightControl(vals, fam)
  local finVals
  if #vals == 3 and tl.tbl:isSingleTypeTable(vals, "number") then
    finVals = vals
  elseif #vals == 1 and type(vals[1]) == "string" then
    local vols, _ = gsub(vals[1], "^#", "")
    if #vols == 6 or #vols == 3 then
      if #vols == 3 then
        vols = gsub(vols, "(.)", "%1%1")
      end
      finVals = {tonumber(sub(vols, 1, 2)), tonumber(sub(vols, 3, 4)), tonumber(sub(vols, 5))}
    end
  end
  if not finVals then
    error("invalid color value")
  end
  SetBacklightColor(finVals[1], finVals[2], finVals[3], unLogiToken[fam])
end

---This function keeps the internal script mode in synch with the hardware's mode
---@type fun (torg, orig, fam)
---@param torg number
---@param orig number
---@param fam string
function tl.logitech:syncModes(torg, orig, fam)
  if tl.deviceState[fam].modeCount > 3 or (not tl.deviceState[fam].bindHardwareModes) or tl.deviceState[fam].modeCount < 2 then
    return
  end
  local mod = orig or tl.deviceState[fam].modus
  local targ = torg or mod + 1
  if targ == 0 then
    targ = mod + 1
  end
  if targ > tl.deviceState[fam].modeCount then
    targ = 1
  end
  if mod == targ then
    return
  end
  if mod > targ then
    while tl.deviceState[fam].modeCount >= mod do
      mod = _iterateMode(mod)
    end
    if tl.deviceState[fam].modeCount == 2 then
      _iterateMode(mod)
    end
    mod = 1
  end
  while targ > mod do
    mod = _iterateMode(mod)
  end
end

---set the mode back to the standard mode once a enough button presses have been executed.
---@param fam string
function tl.logitech:undoTempMode(fam)
  if type(fam) == "string" and fam == "all" then
    local famArr = {"m", "a", "l", "k"}
    for g = 1, #famArr do
      self:undoTempMode(famArr[g])
    end
  elseif type(fam) == "table" then
    for g = 1, #fam do
      self:undoTempMode(fam[g])
    end
  else
    if tl.deviceState[fam].lastModN ~= 0 and (tl.scriptStates.keyCount - lastModC) > 2 then
      _modeSelect(tl.deviceState[fam].lastModN, fam)
      tl.deviceState[fam].lastModN = 0
      self:putNoLCD("mode reset")
    end
  end
end

---Wrapper function for internal macro control methods
---@param cmd GenericMacro
---@param dir string
---@param dirMatch boolean
function tl.logitech:externalMacroWrapper(cmd, dir, dirMatch)
  if type(cmd) == "table" and cmd.play then
    if cmd.play == "toggle" then
      _toggleExternalMacro(cmd)
    elseif cmd.play == "hold" then
      _toggleExternalMacro(cmd, dir)
    end
  elseif dirMatch then
    _playExternalMacro(cmd)
  end
end

---Wrapper for internal mode changing functions
---@type ModeWrapper
---@param target number|string|table
---@param mod string
---@param fam string
---@param dirMatch boolean
function tl.logitech:modeWrapper(target, mod, fam, dirMatch)
  mod = mod or "normal"
  if mod == "normal" then
    if dirMatch then
      _modeSelect(target, fam)
    end
  elseif mod == "toggle" then
    _toggleMode(target, fam)
  else
    _temporaryMode(target, mod, fam)
  end
end