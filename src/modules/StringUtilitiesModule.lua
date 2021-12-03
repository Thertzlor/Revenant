local tl = ...---@type MainLibObject
local lower, match, sub, type,concat, pairs,find,ceil,tonumber,error =
tl.utf8.lower, tl.utf8.match, tl.utf8.sub, type,table.concat,pairs,tl.utf8.find,math.ceil,tonumber,error

--=============================================================
local StringUtilitiesModule = tl.baseClass:new()---@class StringUtilitiesModule:BaseClass Functions that process or type strings 

---Main function for typing strings of keys.
---@param s string
---@param press KeyPress
local function _typeString(s, press)
  local i,n,c,a
  n = #s
  i = 1
  while i <= n do
    a = 1
    c = sub(s,i,i)
    while find(sub(c,a,a),"[/%#~%*|]") do
      if i < n then
        local add = 2
        if sub(c,a,a) == "/"then
          if  find(sub(s,i+1,i+2),"[012]%d") then
            c = c..sub(s,i+1,i+2)
          else
            c = c..sub(s,i+1,i+1)
            add = 1
          end
          i = i+add
          a = a+2
        else
          c = c..sub(s,i+1,i+1)
          i = i+1
          a = a+1
        end
      else error("found a single escape sequence at end of string.  For a single /, put two in a row. i.e. //") end
    end
    tl.keys:pressAndRelease(c,press)
    if i < n then tl.coroutines:wait(press.actionDelay,press.actionVariance,press.forceSleep) end
    i = i+1
  end
end

---Releases all keys currently locked/held down, called at the end of the script.
---@param key string
function StringUtilitiesModule:releaseAll(key)
  local metaPress = {keyDelay = tl.activeProfile.config.keyDelay,keyVariance = tl.activeProfile.config.keyVariance}---@type KeyPress
  for _, va in pairs(tl.keyStates.roDown[key]) do
    if va ~= nil then
      tl.logitech:putNoLCD("auto-released "..va)
      tl.keys:release(va,metaPress,1)
    end
  end
  tl.helperUtils.wipe(tl.keyStates.roDown[key])
end

---press an array of keys, then release it.
---@param seq string[]
---@param press KeyPress
function StringUtilitiesModule:pressAndReleaseSequence(seq,press)
  self:pressSequence(seq,press)
  if del then tl.coroutines:wait(press.keyDelay, press.keyVariance,press.forceSleep) end
  self:releaseSequence(seq,press)
end

---pressing down an array of buttons in order
---@param seq string[]
---@param press KeyPress
function StringUtilitiesModule:pressSequence(seq,press)
  for i=1,#seq do local obj = seq[i]
    if type(obj) == "string" then
      tl.keys:press(obj,press)
      tl.coroutines:wait(press.keyDelay, press.keyVariance,press.forceSleep)
    end
  end
end

function StringUtilitiesModule:valid(str)
  return type(str) == "string" and #str ~= 0
end

---Releasing an array of buttons in order
---@param seq string[]
---@param press KeyPress
function StringUtilitiesModule:releaseSequence(seq,press)
  tl.helperUtils.reverseTable(seq)
  for i=1,#seq do local obj = seq[i]
    if type(obj) == "string" then
      tl.keys:release(obj,press)
      tl.coroutines:wait(press.keyDelay, press.keyVariance,press.forceSleep)
    end
  end
  tl.helperUtils.reverseTable(seq)
end

---Outputs the first character of a string in lowercase.
---@param f string
function StringUtilitiesModule:token(f)
  if type(f)  ~= "string" then return false end
  return lower(sub(f,1,1))
end

---function for deciding how to type different strings and arrays
---@param tstring string
---@param press KeyPress
function StringUtilitiesModule:typingDelegator(tstring,press)
  tstring = tl.str:applyStringBuffer(tstring,press,1)
  if (#tstring == 1 or (sub(tstring,1,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring,2,3)) < 25)))) then
    tl.keys:pressAndRelease(tstring,press)
  else
    _typeString(tstring,press)
  end
  tl.keys:autoRelease(press)
end

---@param press KeyPress
function StringUtilitiesModule:applyStringBuffer(string,press,clear)
if not press.family then return string end
local fam, num = press.family,press.keyNum
  local bufferLocations = {
    tl.activeProfile.deviceState[fam]["_b"..num],
    tl.activeProfile.deviceState[fam],
    tl.activeProfile.deviceState
  }
  local buffString = string
  for i = 1, #bufferLocations do local obj = bufferLocations[i]
    if obj then
      if obj.bufferContent then buffString = obj.bufferContent..buffString end
      if clear  then obj.bufferContent = nil end
    end
  end
  return buffString
end

---@param string string
---@param fam string
---@param num number
---@param mode number
function StringUtilitiesModule:addStringBuffer(string,fam,num,mode,scope)
  local bufferTarget
  local state = tl.activeProfile.deviceState
  if scope == "family" then bufferTarget = state[fam]
  elseif scope == "global" then bufferTarget = state else
    if(not state[fam]["_b"..num]) then  state[fam]["_b"..num] ={} end
    bufferTarget= state[fam]["_b"..num]
  end
  bufferTarget.bufferContent = ((mode ~= nil and bufferTarget.bufferContent ~=nil) and bufferTarget.bufferContent..string) or string
end

return StringUtilitiesModule