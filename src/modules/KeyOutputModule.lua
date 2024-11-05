local rv = ... ---@type Revenant
local ReleaseKey, PressKey, sub, gsub, type, PressMouseButton, ReleaseMouseButton, MoveMouseWheel, pairs, find, concat, remove = ReleaseKey, PressKey, string.sub, string.gsub, type, PressMouseButton, ReleaseMouseButton, MoveMouseWheel, pairs, string.find, table.concat, table.remove

--[[=============================================================]] --
---@class KeyObject #Everything Revenant needs to know about a Key in order to press it.
---@field mb? integer #numeric designation of a normal windows mouse button
---@field key string|integer #Key ID as string or number
---@field modifier l<string> #One or more modifier keys (alt/shift...) as strings.
---@field buffer KeyObject[] #Buffered keys that should be pressed before the current one
---@field designation string #Combined designation for key and modifiers. Used to release already held keys
--[[=============================================================]] --
---Output functions nabbed from ll.project (modified)
---@class KeyOutputModule:BaseClass
---@field keyboardDefinition table<string, l<KeyObject>>
local KeyOutputModule = rv.baseClass:new()

local modPattern = "^[" .. rv.utils.escapeString(concat(rv.tbl:getKeys(rv.presets.stringPresets.modKeys), "")) .. "]+" ---an escaped pattern for all modifier prefixes

---adds currently pressed down keys to a table on an per-thread basis
---@param key KeyObject #the key to add
local function _addDown(key)
   local act = rv.threading.activeTask ---@cast act string
   if act == 0 or (key.mb and key.mb > 5) then return end -- nothing to add if no task is running, and we don't cound mouse wheel scrolls
   rv.states.keyStates.taskDown[act][#rv.states.keyStates.taskDown[act] + 1] = key
end

---removes keys from the held down list, when a task ends
---@param key KeyObject #the key to release
---@param skip? boolean #if true key won't be released after all
local function _removeDown(key, skip)
   local act = rv.threading.activeTask
   if skip or act == 0 or (key.mb and key.mb > 5) then return end -- nothing to do when no task is running or the key is a mouse wheel action
   ---@cast act string
   for i, va in pairs(rv.states.keyStates.taskDown[act]) do if va.designation == key.designation then rv.states.keyStates.taskDown[act][i] = nil end end
end

---inserts modifier into strings.
---@param keyObj KeyObject #the key object to be modified
---@param mod string #the modifier to add
---@return KeyObject #the key object with modifiers added
local function _insertModifiers(keyObj, mod)
   keyObj.modifier = keyObj.modifier or {}
   if type(keyObj.modifier) == "string" then
      if keyObj.modifier == mod then return keyObj end -- key already has this modifier
      keyObj.modifier = {keyObj.modifier} -- converting into a list to hold multiple modifiers
   elseif rv.tbl:find(keyObj.modifier, mod) == true then
      return keyObj
   end -- modifier already in list
   keyObj.modifier[#keyObj.modifier + 1] = mod -- adding modifier to list
   return keyObj
end

---Combine two lists of strings
---@param keysA KeyObject[]|nil
---@param keysB KeyObject[]|nil
---@return KeyObject[]
local function combineKeyArray(keysA, keysB)
   if (not keysA) or (not keysB) then return rv.utils.deepCopy((keysA or keysB)) or {} end
   if #keysA == 0 then return rv.utils.deepCopy(keysB) end
   if #keysB == 0 then return rv.utils.deepCopy(keysA) end
   keysA, keysB = rv.utils.deepCopy(keysA), rv.utils.deepCopy(keysB)
   local lastA = keysA[#keysA]
   if lastA.key == "" then
      remove(keysA)
      local lMods = lastA.modifier
      if lMods and #lMods ~= 0 then
         if type(lMods) ~= "table" then lMods = {lMods} end
         if not keysB[1].modifier or #keysB[1].modifier == 0 then
            keysB[1].modifier = lMods
         else
            for i = 1, #lMods do _insertModifiers(keysB[1], lMods[i]) end
         end
      end
   end
   return rv.tbl:add(keysA, keysB)
end

---Press a SINGLE key object
---@async
---@param k KeyObject #the key to press
---@param press KeyPress #The key press settings defined by the macro
local function _pressKey(k, press)
   if rv.states.scriptStates.docMode then return end -- not pressing anything in documentation mode
   if k.modifier then -- pressing modifiers
      if type(k.modifier) == "table" then
         for i = 1, #k.modifier do
            PressKey(k.modifier[i])
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) -- delay after modifiers
         end
      else
         PressKey(k.modifier --[[@as string]] )
         rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) -- delay after modifiers
      end
   end
   if k.key then
      if k.key ~= "" then PressKey(k.key) end -- press either key or mouse button
   elseif k.mb and k.mb < 6 then
      PressMouseButton(k.mb)
   elseif k.mb then
      MoveMouseWheel(k.mb == 6 and 1 or -1)
   end
end

---Release a SINGLE key object
---@param k KeyObject #the key to release
---@param press KeyPress #The key press settings defined by the macro
---@async
local function _releaseKey(k, press)
   if rv.states.scriptStates.docMode then return end -- not releasing anything in documentation mode
   if k.key then
      if k.key ~= "" then ReleaseKey(k.key) end -- releasing key or mouse button
   elseif k.mb and k.mb < 6 then
      ReleaseMouseButton(k.mb)
   end
   if k.modifier then -- now releasing modifiers
      if type(k.modifier) == "table" then
         for i = 1, #k.modifier do
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) -- delay after modifiers
            ReleaseKey(k.modifier[i])
         end
      else
         rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) -- delay after modifiers
         ReleaseKey(k.modifier --[[@as string]] )
      end
   end
end

---Load a Keyboard file for a specified locale.
---@param locale string #The locale to use
function KeyOutputModule:loadKeyboard(locale)
   self.keyboardDefinition = rv.importer:import(rv.paths.configPath .. "/keyboard_" .. locale --[[@as 'keyboard']] ) -- getting the keyboard file
   for k in pairs(self.keyboardDefinition) do self.keyboardDefinition[k].designation = k end
end

---Converts the logitech key name table into an more easily indexed format.
function KeyOutputModule:constructKeyTable()
   for i = 1, #rv.presets.stringPresets.logitechKeyNames do -- iterate over all logitech keys
      rv.states.keyStates.logiKeys[rv.presets.stringPresets.logitechKeyNames[i]] = true
   end
end

---Wrapper parses a single key name
---@param keyString string #string or name of a key
---@param noLogi? boolean #if true do not try to parse the string as the name of a key
---@param allowSingleModifier? boolean #allow a single modifier shortcut.
---@return l<KeyObject>? #The found or constructed key object
function KeyOutputModule:parseKeyName(keyString, noLogi, allowSingleModifier)
   if ((not allowSingleModifier) or not rv.presets.stringPresets.modKeys[keyString]) and self.keyboardDefinition[keyString] then return rv.utils.deepCopy(self.keyboardDefinition[keyString]) end -- deep copy, so modifiers don't carry over
   if (not noLogi) and rv.states.keyStates.logiKeys[keyString] then return {designation = keyString, key = keyString} end -- output as logitech key
   local mods = rv.presets.stringPresets.modKeys
   if not mods[sub(keyString, 1, 1)] then return nil end -- if it's not a normal key, not a logitech key and does not begin with a modifier, we abort.
   if mods[keyString] then return (allowSingleModifier and {key = mods[keyString]}) or rv.utils.deepCopy(self.keyboardDefinition["/" .. keyString]) end
   local rawKey = self:parseKeyName(gsub(keyString, modPattern, ""), true) ---key name without modifier strings
   if not rawKey then return nil end -- if we can't parse the raw key we abort
   local newKey = rv.utils.deepCopy(rawKey) -- deep copy, so modifiers don't carry over
   newKey.designation = keyString
   for i = 1, #keyString do
      local mod = mods[sub(keyString, i, i)] -- start could be a modifier
      if not mod then break end
      if newKey.key or newKey.mb then ---@cast newKey KeyObject
         newKey = _insertModifiers(newKey, mod) -- converting modifier prefix into actual modifier on the object
      else
         for n = 1, #newKey do newKey[n] = _insertModifiers(newKey[n], mod) end
      end -- handle each entry separately
   end
   return newKey
end

---parse a string consisting of one or more keystrokes into an array of key objects
---@param str string #The string to parse
---@param allowTrailingMods? boolean #Are the last characters allowed to be modifiders?
---@return KeyObject[] #The array of keys representing the string
function KeyOutputModule:keyParser(str, allowTrailingMods)
   local arr = {} ---@type KeyObject[]
   local current ---@type string
   local len = #str -- length of our string
   local pos = 1 ---current position in the string
   local mods = rv.presets.stringPresets.modKeys
   if len == 0 then return rv.utils.deepCopy({self.keyboardDefinition[str]}) end
   if allowTrailingMods and len == 1 then
      local singleKey = self:parseKeyName(str, true, true)
      return #singleKey == 0 and {singleKey} or singleKey --[[@as KeyObject[] ]]
   end
   while pos <= len do
      local modOffset = 0 ---positions skipped because of modifiers
      current = sub(str, pos, pos)
      while mods[sub(str, pos + modOffset, pos + modOffset)] do modOffset = modOffset + 1 end -- finding modifiers
      if sub(str, pos + modOffset, pos + modOffset) == "/" then -- Here we handle the special case of F-Key shorthands
         modOffset = modOffset + (find(sub(str, pos + modOffset + 1, pos + modOffset + 2), "[012]%d") and 2 or 1)
      end
      if modOffset ~= 0 then current = sub(str, pos, pos + modOffset) end -- parsing the extracted key
      local kn = self:parseKeyName(current, true, pos == len and allowTrailingMods)
      if kn then
         local lastArr = arr[#arr]
         if lastArr and lastArr.key == "" then
            remove(arr)
            if lastArr.modifier then kn = combineKeyArray({lastArr}, #kn == 0 and {kn} or kn) end
         end
         if #kn == 0 then ---@cast kn KeyObject
            arr[#arr + 1] = kn
         else
            for i = 1, #kn do arr[#arr + 1] = kn[i] end
         end
      end ---adding our object ro the array
      pos = pos + 1 + modOffset -- continuing to iterate
   end
   return arr
end

---@param keys KeyObject[]
---@param fam FamilyToken
---@param num integer
---@param scope "family"| "global"|"key"
---@param exclusive? boolean
function KeyOutputModule:addKeyBuffer(keys, fam, num, scope, exclusive)
   local bufferTarget ---@type table
   local state = rv.profile.deviceState
   if scope == "family" then
      bufferTarget = state[fam]
   elseif scope == "global" then
      bufferTarget = rv.profile.globalState
   else
      if (not state[fam].keyBuffers["_b" .. num]) then state[fam].keyBuffers["_b" .. num] = {} end
      bufferTarget = state[fam].keyBuffers["_b" .. num]
   end
   if exclusive and #keys == 1 and keys[1].key == "" and not keys[1].modifier then
      bufferTarget.bufferContent = nil
   else
      bufferTarget.bufferContent = ((not exclusive) and bufferTarget.bufferContent ~= nil and combineKeyArray(bufferTarget.bufferContent, keys)) or keys
   end
end

---@param key KeyObject
---@param press KeyPress #The key press settings defined by the macro
---@param forcePress? boolean
---@async
function KeyOutputModule:processBufferDown(key, press, forcePress)
   local keys = key.buffer
   if (#keys == 1 and (not keys[1].modifier or #keys[1].modifier == 0)) or forcePress then
      self:press(keys[1], press)
   else
      self:pressAndRelease(keys, press)
      key.buffer = nil
   end
end

---Press one or more Keys
---@param key l<KeyObject> #one or more key Objects
---@param press KeyPress #The key press settings defined by the macro
---@param exclusiveDown? boolean #do not press and and release key buffers
---@async
function KeyOutputModule:press(key, press, exclusiveDown)
   if rv.states.scriptStates.docMode then return end -- cancelling if in documentation mode
   press.keyDelay = press.keyDelay or 0
   if not key[1] then -- checking if there's only a single key
      ---@cast key KeyObject
      if key.buffer and #key.buffer ~= 0 then -- applying buffer
         self:processBufferDown(key, press, exclusiveDown)
         if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
      end
      _addDown(key) -- adding to pressed list
      _pressKey(key, press) -- if there is no key, there are tables of keys.
   else
      for i = 1, #key do -- processing an array of keys
         if key[i].buffer then -- applying buffer
            self:processBufferDown(key[i], press, exclusiveDown)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
         end
         _addDown(key[i]) -- adding to pressed list
         _pressKey(key[i], press)
         if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
      end
   end
end

---Release one or more keys
---@param key l<KeyObject> #one or more key Objects
---@param press KeyPress #The key press settings defined by the macro
---@param skipRemove? boolean
---@async
function KeyOutputModule:release(key, press, unreverse, skipRemove)
   if rv.states.scriptStates.docMode then return end
   if not key[1] then ---@cast key KeyObject
      _releaseKey(key, press)
      _removeDown(key, skipRemove) -- removing from pressed list
      if key.buffer then -- releasing buffer
         self:release(key.buffer, press)
         if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
      end
   else
      for i = 1, #key do
         local k = key[(unreverse and i or (#key + 1 - i))]
         _releaseKey(k, press) -- removing from pressed list
         _removeDown(k, skipRemove)
         if k.buffer then
            self:release(k.buffer, press) -- releasing buffer
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
         end
         if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
      end
   end
end

function KeyOutputModule:useHID()
   PressKey = PressHidKey
   ReleaseKey = ReleaseHidKey
end

---Presses and releases keys in order.
---@param key l<KeyObject> #one or more key Objects
---@param press KeyPress #The key press settings defined by the macro
---@async
function KeyOutputModule:pressAndRelease(key, press)
   if rv.states.scriptStates.docMode then return end
   local delay = press.keyDelay
   if key[1] then -- if a multiple key press key is found, we must handle each key separately.
      local n = #key
      for i = 1, n do -- iterating the list of keys
         _addDown(key[i])
         _pressKey(key[i], press)
         if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
         _releaseKey(key[i], press)
         _removeDown(key[i])
         if i < n then rv.threading:wait(delay, press.actionVariance, press.forceSleep) end -- not waiting on last key
      end
   else
      self:press(key, press)
      if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end -- only waiting if there's a delay
      self:release(key, press)
   end
end

---function for deciding how to type different strings and arrays
---@param keys l<KeyObject> #one or more key Objects
---@param press KeyPress #The key press settings defined by the macro
---@param id? string #id of the origin macro
---@param noBuffer? boolean #if true buffer strings are not applied
---@param unreverse? boolean #if true does not reverse the order of wrapped keys on keyup
---@async
function KeyOutputModule:typingDelegator(keys, press, id, noBuffer, unreverse)
   if not keys then return end
   local keyArr = keys[1]
   ---one or more modifier keys originally found on the key
   local origMods ---@type l<string>|nil
   if not noBuffer then -- applying the buffer
      local foundMods = keyArr and keys[1].modifier or keys.modifier
      if foundMods then origMods = rv.tbl:intersectSimple(type(foundMods) == "table" and foundMods or {foundMods}, {}) end -- intersect acts as copy for shallow arrays
      keys = rv.keys:applyKeyBuffer(keys, press)
   end
   self:wrap(press, true, unreverse)
   if id and rv.states.scriptStates.docMode then return rv.lcd:displayOnLCD(id) end -- in documentation mode we show the macro info
   if not keys[1] or self.keyboardDefinition[keys.designation] then
      self:pressAndRelease(keys, press) -- pressing and releasing a single key
   else
      for i = 1, #keys do -- iterating over key array
         self:pressAndRelease(keys[i], press)
         rv.threading:wait(press.actionDelay, press.actionVariance)
      end
   end
   if not noBuffer then
      self:wrap(press, false, unreverse) -- unwrapping wraps
      if keyArr then
         keys[1].buffer = nil
         keys[1].modifier = origMods or {}
      else
         keys.buffer = nil
         keys.modifier = origMods or {}
      end -- removing buffers from the key
   end
end

---Releases all keys currently locked/held down, called at the end of the script or when aborting tasks.
---@param key string #the mouse button that triggered the key presses
---@async
function KeyOutputModule:releaseAll(key)
   ---press with default delay settings
   local metaPress = {keyDelay = rv.profile.config.keyDelay, keyVariance = rv.profile.config.keyVariance} ---@type KeyPress
   for k in pairs(rv.states.keyStates.taskDown[key]) do -- checking if any held down keys are associated with the button
      local va = rv.states.keyStates.taskDown[key][k]
      if va ~= nil then self:release(va, metaPress, false, true) end -- releasing all keys
   end
   rv.utils.wipe(rv.states.keyStates.taskDown[key]) -- emptying the key's table
end

---@param keys KeyObject | KeyObject[]
---@param press KeyPress #The key press settings defined by the macro
---@return l<KeyObject> #the key object with buffer applied
function KeyOutputModule:applyKeyBuffer(keys, press)
   if not press.family then return keys end -- no buffer for keys without family
   local fam, num = press.family or "m", press.keyNum

   local bufferLocations = { ---all possible locations for different buffers
      rv.profile.deviceState[fam].keyBuffers["_b" .. num], rv.profile.deviceState[fam], rv.profile.globalState
   }

   local buffTable = {} ---the string buffer to be appended
   for i = 1, #bufferLocations do
      local obj = bufferLocations[i]
      if obj and obj.bufferContent then -- getting the content from each buffer location
         buffTable = combineKeyArray(obj.bufferContent, buffTable)
         obj.bufferContent = nil -- erasing the buffer after applying
      end
   end

   local bn = #buffTable ---length of the buffer
   if bn == 0 then return keys end -- nothing to do if there's no buffer
   local buffKeys = keys
   if buffKeys.key or buffKeys.mb then buffKeys = {buffKeys --[[@as KeyObject]] } end -- key needs to be an array

   local modKeys = {} ---@type string[]

   local lastBuff = buffTable[#buffTable]
   if lastBuff.key == "" and lastBuff.modifier and #lastBuff.modifier ~= 0 then
      remove(buffTable)
      modKeys = type(lastBuff.modifier) ~= "table" and {lastBuff.modifier} or lastBuff.modifier --[[@as string[] ]]
   end
   local mn = #modKeys
   for i = 1, mn do
      local md = modKeys[mn + 1 - i] -- applying all modification prefixes
      _insertModifiers(buffKeys[1], md)
   end
   buffKeys[1].buffer = buffTable -- setting the actual buffer
   return buffKeys
end

---Automatically presses or releases "wrapped" modifier keys.
---@param press KeyPress #The key press settings defined by the macro
---@param wrapDown boolean #if true does not reverse the order on keyup
---@param unreverse? boolean #if true does not reverse the order on keyup
---@async
function KeyOutputModule:wrap(press, wrapDown, unreverse)
   local bufferLocations = { -- possible buffer locations
      rv.profile.deviceState[press.family or "m"].keyBuffers["_b" .. press.keyNum], rv.profile.deviceState[press.family or "m"], rv.profile.globalState
   }
   for i = 1, #bufferLocations do
      local obj = bufferLocations[i]
      local wraps = obj and obj[wrapDown and "wrapperContentDown" or "wrapperContentUp"] --[[@as KeyObject[]|nil]]
      if wraps and #wraps ~= 0 then -- checking if there's any wrapped keys
         if not wrapDown and press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end -- waiting if there's a delay
         if wrapDown then
            self:press(wraps, press, unreverse)
         else
            self:release(wraps, press, unreverse)
         end -- releasing buffers
         if wrapDown then
            obj.wrapperContentDown = {}
         else
            obj.wrapperContentUp = {}
         end -- emptying the list
      end
   end
end

---clear the contents of wrap keys
---@param press KeyPress #The key press settings defined by the macro
---@param wrapDown boolean #if true does not reverse the order on keyup
function KeyOutputModule:clearWrap(press, wrapDown)
   local bufferLocations = { -- possible buffer locations
      rv.profile.deviceState[press.family or "m"].keyBuffers["_b" .. press.keyNum], rv.profile.deviceState[press.family or "m"], rv.profile.globalState
   }
   for i = 1, #bufferLocations do
      local obj = bufferLocations[i]
      if obj then obj[wrapDown and "wrapperContentDown" or "wrapperContentUp" --[[@as any]] ] = {} end
   end
end

return KeyOutputModule
