local ReleaseKey, PressKey, sub, find, gsub, type, insert, maxn, PressMouseButton, ReleaseMouseButton =
ReleaseKey, PressKey , string.sub, string.find, string.gsub,type, table.insert, table.maxn, PressMouseButton, ReleaseMouseButton
---@type MainLibObject
local tl = ...
-->>> Output functions nabbed from ll.project (modified) ===============================================================================

---Press one or more Keys
---@param key string
---@param delay number
---@param deviation number
---@param fam string
---@param num number
function tl.Press(key, delay,deviation,fam,num)
  if tl.docMode and tl.docModeButtonLock then return end
  tl.addDown(key)
  local k = tl._parseKeyName(key)
  delay = delay or 0
  if k then
    if k.key then
      tl._PressKey(k, delay,deviation)
    elseif k[1] then		-- if there is no key, there are tables of keys.
      local n
      n = maxn(k)
      for i = 1, n do
        tl._PressKey(k[i], delay,deviation)
      end
    elseif k.mb then
      PressMouseButton(k.mb)
    end
  elseif key ~="" then
    if tl.logiKeys[key] then PressKey(key)
      return true
    elseif (#key ~= 2 or sub(key,1,1) ~="/") then
      tl.remDown(key)
      tl.quiKey({key},nil,nil,nil,num,1,fam)
      return
    end
  end
end

---Converts the logitech key name table into an more easily indexed format.
function tl.constructKeyTable()
  for i=1,#tl.logitechKeyNames do local n = tl.logitechKeyNames[i]
    tl.logiKeys[n]=true
  end
end

---inserts modifier into strings.
---@param keyObj string|table
---@param index number
---@param mod string
function tl._insertModifiers(keyObj,index,mod)
  keyObj.modifier = keyObj.modifier or {}
  if type(keyObj.modifier) == "string" then
    if keyObj.modifier == mod then return keyObj end
    keyObj.modifier = {keyObj.modifier}
  elseif tl.find(keyObj.modifier,mod) == nil then return keyObj end
  insert(keyObj.modifier,index,mod)
  return keyObj
end

---Converts modifier shortcuts into key press instructions.
---@param keyString string
function tl._wrapKeys(keyString)
  if find(keyString,"^[%#~%*|]") == nil then return nil end
  local newKey
  local rawKey = tl._parseKeyName(gsub(keyString,"^[%#~%*|]+",""))
  if rawKey ~= nil then
    newKey = tl.deepcopy(rawKey)
    for i = 1, #keyString do
      local part = sub(keyString,i,i)
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
        newKey = tl._insertModifiers(newKey,i,mod)
      else
        for n = 1, #newKey do
          newKey[n]=tl._insertModifiers(newKey[n],i,mod)
        end
      end
    end
  end
  return newKey
end

---Wrapper function for identifying key names
---@param keyString string
function tl._parseKeyName(keyString)
   return tl._KEYBOARD[keyString] or tl._wrapKeys(keyString)
end

---Automatically releases "wrapped" modifier keys.
---@param fam string
---@param num number
---@param del number
---@param dev number
function tl.autoRelease(fam,num,del,dev)
  if tl.state[fam]["_auto"..num] and #tl.state[fam]["_auto"..num] ~= 0 then
    tl.relRay(tl.state[fam]["_auto"..num],del,dev)
    tl.state[fam]["_auto"..num] = {}
  end
end

---Release one or more keys
---@param key string
---@param delay number
---@param deviation number
---@param sil boolean
function tl.Release(key, delay,deviation,sil)
  if tl.docMode and tl.docModeButtonLock then return end
  local k = tl._parseKeyName(key)
  delay = delay or 0
  if k then
    if k.key then
      tl._ReleaseKey(k, delay, deviation)
    elseif k[1] then		-- if there is no key, there are tables of keys.
      local n
      n = maxn(k)
      for i = 1, n do
        tl._ReleaseKey(k[i], delay, deviation)
      end
    elseif k.mb then
      ReleaseMouseButton(k.mb)
    end
  elseif key ~="" and tl.logiKeys[key] then
    ReleaseKey(key)
  end
  tl.remDown(key,sil)
end

---Presses and releases keys in order.
---@param key string
---@param delax number
---@param actionDeviation number
---@param deviation number
---@param fam string
---@param num number
function tl.PressAndRelease(key, delax,actionDeviation,deviation,fam,num)
  if tl.docMode and tl.docModeButtonLock then return end
  local k = tl._parseKeyName(key)
  local delay = delax or tl.keyDelay
  if k and k[1] then	-- a multiple key press key is found, we must handle key key separate.
    tl.addDown(key)
    local n
    n = maxn(k)
    for i=1, n do
      tl._PressKey(k[i], delay,deviation)
      if delay ~=0 then tl.wait(delay,deviation) end
      tl._ReleaseKey(k[i], delay,deviation)
      if i < n then
        tl.wait(delay,actionDeviation)
      end
    end
    tl.remDown(key)
  else
    tl.Press(key, delay,deviation,fam,num)
    if delay ~=0 then tl.wait(delay,deviation) end
    tl.Release(key, delay,deviation)
  end
end

---Delegates Logitech key releases.
---@param k string
---@param delay number
---@param deviation number
function tl._ReleaseKey(k, delay,deviation)
  if tl.docMode and tl.docModeButtonLock then return end
  ReleaseKey(k.key)
  if k.modifier then
    if type(k.modifier) == "table" then
      for i=1,#k.modifier do local v = k.modifier[i]
        tl.wait(delay or tl.keyDelay,deviation)
        ReleaseKey(v)
      end
    else
      tl.wait(delay or tl.keyDelay,deviation)
      ReleaseKey(k.modifier)
    end
  end
end

---Delegates Logitech key presses.
---@param k string
---@param delay number
---@param deviation number
function tl._PressKey(k, delay,deviation)
  if tl.docMode and tl.docModeButtonLock then return end
  if k.modifier then
    if type(k.modifier) == "table" then
      for i=1,#k.modifier do local v = k.modifier[i]
        PressKey(v)
      end
    else
      PressKey(k.modifier)
    end
      tl.wait(delay or tl.keyDelay,deviation)
  end
  PressKey(k.key)
end

---Main function for typing strings of keys.
---@param s string
---@param delay number
---@param kelay number
---@param actionDeviator number
---@param keyDeviator number
---@param fam string
---@param num number
function tl.TypeString(s, delay,kelay,actionDeviator,keyDeviator,fam,num)
  local i, n, c, a
  n = # s
  i = 1
  while i <= n do
    a = 1
    c = sub(s, i, i)				-- get each character from s
    while find(sub(c,a,a),"[/%#~%*|]") do					-- / signals special character, which is 2 characters wide
      if i < n then
        local add = 2
        if sub(c,a,a) == "/"then
          if  find(sub(s, i+1, i+2),"[012]%d") then
            c = c..sub(s, i+1, i+2)
          else
            c = c..sub(s, i+1, i+1)
            add = 1
          end
          i = i + add
          a = a + 2
        else
          c = c..sub(s, i+1, i+1)
          i = i + 1
          a = a + 1
        end
      else
        error("tl.TypeString(s, delay) - found a single   at end of string.  For a single /, put two in a row. i.e. //", 2)
      end
    end
    tl.PressAndRelease(c,kelay,actionDeviator,keyDeviator,fam,num)
    if delay and i < n then
      tl.wait(delay,actionDeviator)
    end
    i = i + 1
  end
end