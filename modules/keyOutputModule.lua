---@type MainLibObject
local tl = ...
local ReleaseKey, PressKey, sub, find, gsub, type, insert, maxn, PressMouseButton, ReleaseMouseButton =
  ReleaseKey,PressKey,string.sub,string.find,string.gsub,type,table.insert,table.maxn,PressMouseButton,ReleaseMouseButton
-->>> Output functions nabbed from ll.project (modified) ===============================================================================

---Converts modifier shortcuts into key press instructions.

---adds currently pressed down keys to a table
---@param key string
local function _addDown(key)
  if tl.pollControls.cutine == 0 then
    return
  end
  tl.roDown[tl.pollControls.cutine][#tl.roDown[tl.pollControls.cutine] + 1] = key
end

---removes keys from the held down list, when they are released again
---@param key string
---@param sil boolean
local function _clearPushed(key, sil)
  if sil or tl.pollControls.cutine == 0 then
    return
  end
  for i, va in pairs(tl.roDown[tl.pollControls.cutine]) do
    if va == key then
      tl.roDown[tl.pollControls.cutine][i] = nil
    end
  end
end

---inserts modifier into strings.
---@param keyObj string|table
---@param index number
---@param mod string
local function _insertModifiers(keyObj, index, mod)
  keyObj.modifier = keyObj.modifier or {}
  if type(keyObj.modifier) == "string" then
    if keyObj.modifier == mod then
      return keyObj
    end
    keyObj.modifier = {keyObj.modifier}
  elseif tl.find(keyObj.modifier, mod) == nil then
    return keyObj
  end
  insert(keyObj.modifier, index, mod)
  return keyObj
end

---Wrapper function for identifying key names
---@param keyString string
local function _parseKeyName(keyString)
  if tl.keyboardDefinition[keyString] then
    return tl.keyboardDefinition[keyString]
  end
  if find(keyString, "^[%#~%*|]") == nil then
    return nil
  end
  local newKey
  local rawKey = _parseKeyName(gsub(keyString, "^[%#~%*|]+", ""))
  if rawKey ~= nil then
    newKey = tl.deepCopy(rawKey)
    for i = 1, #keyString do
      local part = sub(keyString, i, i)
      local mod
      if part == "*" then
        mod = "lctrl"
      elseif part == "#" then
        mod = "lalt"
      elseif part == "~" then
        mod = "lshift"
      elseif part == "|" then
        mod = "lgui"
      else
        break
      end
      if newKey.key then
        newKey = _insertModifiers(newKey, i, mod)
      else
        for n = 1, #newKey do
          newKey[n] = _insertModifiers(newKey[n], i, mod)
        end
      end
    end
  end
  return newKey
end

---Delegates Logitech key presses.
---@param k string
---@param delay number
---@param deviation number
local function _pressKey(k, delay, deviation)
  if tl.docMode and tl.config.docModeButtonLock then
    return
  end
  if k.modifier then
    if type(k.modifier) == "table" then
      for i = 1, #k.modifier do
        PressKey(k.modifier[i])
      end
    else
      PressKey(k.modifier)
    end
    tl.wait(delay or tl.config.keyDelay, deviation)
  end
  PressKey(k.key)
end

---Delegates Logitech key releases.
---@param k string
---@param delay number
---@param deviation number
local function _releaseKey(k, delay, deviation)
  if tl.docMode and tl.config.docModeButtonLock then
    return
  end
  ReleaseKey(k.key)
  if k.modifier then
    if type(k.modifier) == "table" then
      for i = 1, #k.modifier do
        tl.wait(delay or tl.config.keyDelay, deviation)
        ReleaseKey(k.modifier[i])
      end
    else
      tl.wait(delay or tl.config.keyDelay, deviation)
      ReleaseKey(k.modifier)
    end
  end
end

---Press one or more Keys
---@param key string
---@param delay number
---@param deviation number
---@param fam string
---@param num number
function tl.press(key, delay, deviation, fam, num)
  if tl.docMode and tl.config.docModeButtonLock then
    return
  end
  _addDown(key)
  local k = _parseKeyName(key)
  delay = delay or 0
  if k then
    if k.key then
      _pressKey(k, delay, deviation)
    elseif k[1] then -- if there is no key, there are tables of keys.
      local n
      n = maxn(k)
      for i = 1, n do
        _pressKey(k[i], delay, deviation)
      end
    elseif k.mb then
      PressMouseButton(k.mb)
    end
  elseif key ~= "" then
    if tl.logiKeys[key] then
      PressKey(key)
      return true
    elseif (#key ~= 2 or sub(key, 1, 1) ~= "/") then
      _clearPushed(key)
      tl.keySequence({key}, nil, nil, nil, num, 1, fam)
      return
    end
  end
end

---Converts the logitech key name table into an more easily indexed format.
function tl.constructKeyTable()
  for i = 1, #tl.logitechKeyNames do
    tl.logiKeys[tl.logitechKeyNames[i]] = true
  end
end

---Automatically releases "wrapped" modifier keys.
---@param fam string
---@param num number
---@param del number
---@param dev number
function tl.autoRelease(fam, num, del, dev)
  local bufferLocations = {
    tl.state[fam]["_b"..num],
    tl.state[fam],
    tl.state
  }
  for i = 1, #bufferLocations do local obj = bufferLocations[i]
    if obj and obj.wrapperContent then
      tl.relRay(obj.wrapperContent, del, dev)
      obj.wrapperContent = {}
    end
  end
end

---Release one or more keys
---@param key string
---@param delay number
---@param deviation number
---@param sil boolean
function tl.release(key, delay, deviation, sil)
  if tl.docMode and tl.config.docModeButtonLock then
    return
  end
  local k = _parseKeyName(key)
  delay = delay or 0
  if k then
    if k.key then
      _releaseKey(k, delay, deviation)
    elseif k[1] then -- if there is no key, there are tables of keys.
      local n
      n = maxn(k)
      for i = 1, n do
        _releaseKey(k[i], delay, deviation)
      end
    elseif k.mb then
      ReleaseMouseButton(k.mb)
    end
  elseif key ~= "" and tl.logiKeys[key] then
    ReleaseKey(key)
  end
  _clearPushed(key, sil)
end

---Presses and releases keys in order.
---@param key string
---@param delax number
---@param actionDeviation number
---@param deviation number
---@param fam string
---@param num number
function tl.pressAndRelease(key, delax, actionDeviation, deviation, fam, num)
  if tl.docMode and tl.config.docModeButtonLock then
    return
  end
  local k = _parseKeyName(key)
  local delay = delax or tl.config.keyDelay
  if k and k[1] then -- a multiple key press key is found, we must handle key key separate.
    _addDown(key)
    local n
    n = maxn(k)
    for i = 1, n do
      _pressKey(k[i], delay, deviation)
      if delay ~= 0 then
        tl.wait(delay, deviation)
      end
      _releaseKey(k[i], delay, deviation)
      if i < n then
        tl.wait(delay, actionDeviation)
      end
    end
    _clearPushed(key)
  else
    tl.press(key, delay, deviation, fam, num)
    if delay ~= 0 then
      tl.wait(delay, deviation)
    end
    tl.release(key, delay, deviation)
  end
end
