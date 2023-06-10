local rv = ... ---@type Revenant
local PlayMacro, AbortMacro, OutputLogMessage, sub, gsub, type, concat, tostring, SetBacklightColor, arg, tonumber, error, SetMKeyState, GetMKeyState, pairs, next = PlayMacro, AbortMacro, OutputLogMessage, string.sub, string.gsub, type, table.concat, tostring, SetBacklightColor, arg, tonumber, error, SetMKeyState, GetMKeyState, pairs, next
local unLogiToken = {m = "mouse", k = "kb", l = "lhc"} ---family tokens to logitech names
local famTokens = rv.tbl:getKeys(unLogiToken) ---@type FamilyToken[]

---Functions that interact directly with the LGS software
---@class LogitechInterfaceModule
local LogitechInterfaceModule = rv.baseClass:new()
LogitechInterfaceModule.macPlay = false ---@private is a logitech macro currently playing?
LogitechInterfaceModule.unlogiToken = unLogiToken ---Get longhand designation of shorthand families

---sub function to make sure the modes cycle back correctly
---@param fam FamilyToken #the logitech family to cycle
local function _cycleMode(fam)
   local deviceState = rv.profile.deviceState[fam]
   deviceState.modus = (deviceState.modus < deviceState.modeCount) and deviceState.modus + 1 or 1
end

---@private
---Put devices in a specific mode.
---@param target integer | string | table #any sort of mode selector
---@param fam l<FamilyToken|HardwareFamily|"all"> #the family targeted by this mode, can be more than one or "all"
function LogitechInterfaceModule:_modeSelect(target, fam)
   if fam == "all" then
      for g = 1, #famTokens do self:_modeSelect(target, famTokens[g]) end -- call again for every device
   elseif type(fam) == "table" then
      for g = 1, #fam do self:_modeSelect(target, fam[g]) end -- call again for all entries
   else
      ---@cast fam FamilyToken
      fam = rv.str:token(fam) -- tokenized family
      local state = rv.profile.deviceState[fam]
      if state then -- if there's no state, there's no mode
         local config = rv.profile.config
         if type(target) == "table" then target = target[1] end -- now we definitely only have one mode
         if type(target) == "string" then -- if it's a stroing we need to resolve the number of the mode
            for i = 1, state.modeCount do
               local mod = state.modeConfig[i]
               if mod and mod == target or type(mod) == "table" and mod[1] == target then
                  target = i
                  break
               end
            end
         end
         target = rv.tbl:cycleIndex(state.modeCount, target, state.modus) -- make sure we're within range
         if type(target) ~= "number" or state.modeCount < 2 or state.modus == target then return end
         if ((config.globalGShift and rv.profile.globalState.shift) or state.shift) == 0 then self:syncModes(target, nil, fam) end
         if target == nil or target == 0 then
            _cycleMode(fam) -- if the target mode is 0, just cycle to the next mode
         elseif target <= state.modeCount then
            while target ~= state.modus do _cycleMode(fam) end -- else cycle until you reach the target mode
         else
            self:_modeSelect(state.modeCount, fam)
         end -- if the target is too high, we select the highest available mode
         if state.bindHardwareModes and state.family ~= config.pollFamily and type(target) == "number" then SetMKeyState(target, unLogiToken[state.token]) end -- syncing hardware
         rv.lcd:displayOnLCD("__" .. fam .. "_m" .. state.modus, nil, config.LCDMessageDuration) -- showing mode change on lcd
         self:setModeBacklight(target, fam)
      end
   end
end

---@private
---toggling a different mouse mode as long as a button is held down
---@param md integer| string|table integer | string | table #any sort of mode selector
---@param fam l<FamilyToken|HardwareFamily|"all"> #the family targeted by this mode, can be more than one or "all"
function LogitechInterfaceModule:_toggleMode(md, fam)
   if type(fam) == "string" and fam == "all" then
      for g = 1, #famTokens do self:_toggleMode(md, famTokens[g]) end -- same logic as in main selector
   elseif type(fam) == "table" then
      for g = 1, #fam do self:_toggleMode(md, fam[g]) end
   else
      ---@cast fam FamilyToken
      fam = rv.str:token(fam)
      local deviceState = rv.profile.deviceState[fam]
      if deviceState.dir == "down" then -- triggering toggle on key press
         deviceState.lastMod = deviceState.modus
         self:_modeSelect(md, fam)
      else -- undoing mode change on key release
         self:_modeSelect(rv.profile.deviceState.lastMod, fam)
         deviceState.lastMod = 0
      end
   end
end

---Makes sure all modes are sensible on startup
function LogitechInterfaceModule:initModes()
   local config = rv.profile.config -- if there's global modes, we take one family's m key state as the definite mode
   local globalTarget = config.globalModes and next(config.globalModes) and GetMKeyState(unLogiToken[rv.str:token(config.globalModeFamily)])
   for k, v in pairs(rv.profile.deviceState) do -- checking the saved state of all devices
      local currentMode = GetMKeyState(unLogiToken[k])
      v.modus = currentMode
      if config.modeReset and currentMode ~= 1 then -- resetting the mode to 1
         self:syncModes(1, currentMode, k) -- syncing reset with hardware
         if not v.family ~= config.pollFamily then SetMKeyState(1, unLogiToken[k]) end -- not messing with the polling family
         v.modus = 1
      elseif (not config.modeReset) and globalTarget and currentMode ~= globalTarget then
         self:syncModes(globalTarget, currentMode, k) -- syncing with persistent global target
         if not v.family ~= config.pollFamily then SetMKeyState(globalTarget, unLogiToken[k]) end
         v.modus = globalTarget
      end
      local cmc = v.modeConfig[v.modus]
      if type(cmc) == "table" and cmc[2] then self:backLightControl(cmc[2], k) end -- setting backlight
   end
end

---@private
---Change the mode temporarily, revert after a certain number of button presses.
---@param md integer | string |table #any sort of mode selector
---@param num integer|false|string #the number of key presses after which to reset to the last mode, or "false" to reset after the next press
---@param fam l<FamilyToken|HardwareFamily|"all"> #the family targeted by this mode, can be more than one or "all"
function LogitechInterfaceModule:_temporaryMode(md, num, fam)
   if fam == "all" then
      for g = 1, #famTokens do self:_temporaryMode(md, num, famTokens[g]) end -- same logic as in main selector
   elseif type(fam) == "table" then
      for g = 1, #fam do self:_temporaryMode(md, num, fam[g]) end
   else -- setting the stats for when to toggle back on the device
      local token = rv.str:token(fam) --[[@as FamilyToken]]
      local deviceState = rv.profile.deviceState[token]
      if deviceState.lastModN == 0 and deviceState.dir == "down" then
         deviceState.lastModN = deviceState.modus
         deviceState.nextModN = rv.states.scriptStates.keyCount + ((num and type(num) == "number" and num + ((num > 2 and 1) or -1)) or 0) -- key count at which to reset
         self:_modeSelect(md, token)
      end
   end
end

---@private
---Play an external LGS macro
---@param nam string #the name of the macro
---@param blocking? 1|2|3 #blocking setting from the macro options
function LogitechInterfaceModule:_playExternalMacro(nam, blocking)
   if blocking == 2 or blocking == 3 then
      AbortMacro() -- if macro blocking is activated no other macro can run
      self.macPlay = false
   end
   PlayMacro(nam)
   return true
end

---@private
---toggle an external LGS macro
---@param name string #the name of the lgs macro
---@param direction? string #current direction of the event
---@param blocking? 1|2|3 #the blocking setting from the options
---@return boolean? #true if the macro was run, false if it was cancelled
function LogitechInterfaceModule:_toggleExternalMacro(name, direction, blocking)
   if direction and direction ~= "down" then return end -- not toggling on keyup
   if self.macPlay == false then -- playing the macro
      self:_playExternalMacro(name, blocking)
      self.macPlay = true
      return true
   else -- cancelling the macro
      AbortMacro()
      self.macPlay = false
      return false
   end
end

---calling the logitech mode change macro on mice
---@param mod integer #the current mode number
---@param fam FamilyToken #the device family to target
---@return integer #the mode number we just switched to
local function _iterateMode(mod, fam)
   if fam == "m" then -- I don't know if any keyboards have modes
      AbortMacro() -- cancelling any currently running macro so ours can run
      PlayMacro("Mode Switch (" .. rv.profile.deviceState[fam].name .. ")") -- getting the right name
   end
   return mod + 1
end

---Outputs messages to the Logitech lua log
---@vararg string #the message(s) to send
function rv:put(...) ---@cast arg {n:number}
   for i = 1, arg.n do if type(arg[i]) ~= "string" then arg[i] = tostring(arg[i]) end end
   local fin = concat(arg, " ") -- appending all strings
   OutputLogMessage(fin .. "\n") -- logging with newline
end

---output a value and then pipe it back
---@generic T
---@param ... T
---@return T
function rv:pipe(...)
   rv:put(...)
   return ...
end

---Set the backlight of compatible logitech devices to a specific color
---@param vals {[1]:integer,[2]:integer,[3]:integer}|l<string> #a color array or hex string
---@param fam FamilyToken #family with backlight support
function LogitechInterfaceModule:backLightControl(vals, fam)
   local finalVals ---@type {[1]:integer,[2]:integer,[3]:integer}
   if #vals == 3 and rv.tbl:isSingleTypeTable(vals --[[@as table]] , "number") then
      finalVals = vals --[[@as table]]
   elseif type(vals) == "string" or (#vals == 1 and type(vals[1]) == "string") then ---@cast vals string[]
      local strippedVals = gsub((type(vals) == "table" and vals[1] or vals --[[@as string]] ), "^#", "") -- excluding the # at start
      if #strippedVals == 6 or #strippedVals == 3 then
         if #strippedVals == 3 then strippedVals = gsub(strippedVals, "(.)", "%1%1") end -- expanding 3 value hex strings
         finalVals = {tonumber(sub(strippedVals, 1, 2), 16), tonumber(sub(strippedVals, 3, 4), 16), tonumber(sub(strippedVals, 5), 16)} -- converting hex to rgb
      end
   end -- quick validity check
   if not finalVals then error("invalid color value") end
   SetBacklightColor(finalVals[1], finalVals[2], finalVals[3], unLogiToken[fam]) -- applying rgb
end

---Set the backlight for a specific mode
---@param modeNum? integer #the numeric value of a mode
---@param fam FamilyToken #the device family to target
function LogitechInterfaceModule:setModeBacklight(modeNum, fam)
   if (not modeNum) or (not fam) then return end -- aborting in nonsensical situations
   local modeConf = rv.profile.deviceState[fam].modeConfig[modeNum] -- getting mode data
   if not modeConf or type(modeConf) ~= "table" or not modeConf[2] then return end -- aborting if no color is specified
   self:backLightControl(modeConf[2], fam)
end

---This function keeps the internal script mode in synch with the hardware's mode
---@param targetMode? integer #numeric mode
---@param orig? integer #the current mode
---@param fam FamilyToken #device to target
function LogitechInterfaceModule:syncModes(targetMode, orig, fam)
   local deviceState = rv.profile.deviceState[fam] -- devices only support 3 modes so we don't sync if more are defined
   if deviceState.modeCount > 3 or (not deviceState.bindHardwareModes) or deviceState.modeCount < 2 then return end
   local mod = orig or deviceState.modus
   local target = targetMode or mod + 1
   if target == 0 then target = mod + 1 end -- a value of 0 simply iterates
   if target > deviceState.modeCount then target = 1 end -- cycling back if the target is too high
   if mod == target then return end
   if mod > target then -- calling the LGS mode macro until we are synced
      while deviceState.modeCount >= mod do mod = _iterateMode(mod, fam) end
      if deviceState.modeCount == 2 then _iterateMode(mod, fam) end
      mod = 1
   end
   while target > mod do mod = _iterateMode(mod, fam) end
end

---set the mode back to the standard mode once a enough button presses have been executed.
---@param fam l<FamilyToken|"all"> #the family targeted by this mode, can be more than one or "all"
function LogitechInterfaceModule:undoTempMode(fam)
   if type(fam) == "string" and fam == "all" then
      for g = 1, #famTokens do self:undoTempMode(famTokens[g]) end
   elseif type(fam) == "table" then
      for g = 1, #fam do self:undoTempMode(fam[g]) end
   else
      local deviceState = rv.profile.deviceState[fam]
      if deviceState.lastModN ~= 0 and (rv.states.scriptStates.keyCount - deviceState.nextModN) > 2 then
         self:_modeSelect(deviceState.lastModN, fam) -- going back to the last recorded mode
         deviceState.lastModN = 0 -- no temporary mode active
         rv:put("mode reset")
      end
   end
end

---Wrapper function for internal macro control methods
---@param cmd string #the name of the logitech macro
---@param options _ExternalMacroOptions #play options for the macro
---@param dir DirectionValue #the direction of the event
function LogitechInterfaceModule:externalMacroWrapper(cmd, options, dir)
   local block = options.macroBlocking -- triggering the macro in different ways depending on our options
   if options.play == "toggle" then
      return self:_toggleExternalMacro(cmd, nil, block)
   elseif options.play == "hold" then
      return self:_toggleExternalMacro(cmd, dir, block)
   end
   return self:_playExternalMacro(cmd, block)
end

---Wrapper for internal mode changing functions
---@param target integer|string|table #any sort of mode selector
---@param mod integer|boolean|string #the selection mode from the macro option or temporary mode number
---@param fam l<FamilyToken|HardwareFamily|"all"> #the family targeted by this mode, can be more than one or "all"
function LogitechInterfaceModule:modeWrapper(target, mod, fam)
   mod = mod or "normal" -- selecting, toggling, or temp mode based on options
   if mod == "normal" then
      self:_modeSelect(target, fam)
   elseif mod == "toggle" then
      self:_toggleMode(target, fam)
   else
      self:_temporaryMode(target, mod, fam)
   end
end

return LogitechInterfaceModule
