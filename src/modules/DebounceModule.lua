local tl = ...---@type MainLibObject
local Sleep, GetRunningTime, type, pairs, remove ,concat = 
Sleep,GetRunningTime,type,pairs,table.remove,table.concat
--=============================================================
local DebounceModule = tl.baseClass:new()---@class DebounceModule:BaseClass Debouncing keys
DebounceModule.bounceTable = {}

local eventCategory = {mouse={
  up="MOUSE_BUTTON_RELEASED",
  down="MOUSE_BUTTON_PRESSED"
}}

local tracker = {mouse={},keyboard={},lhc={}}

function DebounceModule:setupDebouncer()
  local config = tl.activeProfile.config.debouncerSettings;
  for k, v in pairs(config) do
    self.bounceTable[k] = {}
    for i = 1, #v do local el = v[i]
      self.bounceTable[k][remove(el,1)] = el
    end
  end
end

---debounces an event
function DebounceModule:debounceEvent(family,argument,event)-->>> Polling related vars nabbed form g-max====================================================================================
  local bounce = self.bounceTable[family] and self.bounceTable[family][argument]
  if not bounce then return false end
  local now = GetRunningTime();
  if (bounce[2] == nil or eventCategory[family][bounce[2]] == event) and tracker[family][argument] and now - tracker[family][argument]  <  bounce[1] then 
    local bounceValue =  now - tracker[family][argument]
    if bounceValue  <  bounce[1] then 
      if tl.activeProfile.config.logBounce then tl:put(concat({'debounced',family,argument,'at',bounceValue..'ms'},' ')) end 
      return true
    end
  end 
  tracker[family][argument] = now
  return false
end

return DebounceModule