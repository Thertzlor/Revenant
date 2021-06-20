local tl = ...---@type MainLibObject
local Sleep, GetRunningTime, type, pairs, remove ,concat = 
Sleep,GetRunningTime,type,pairs,table.remove,table.concat
--=============================================================
local DebounceModule = tl.baseClass:new()---@class DebounceModule:BaseClass Debouncing keys
local bounceTable = {}
local tracker = {}
local bounced = {}

local eventCategory = {mouse={
  up="MOUSE_BUTTON_RELEASED",
  down="MOUSE_BUTTON_PRESSED"
}}
local function gracePeriod(family,arg,time)
  tl.coroutines:taskRun("graceBounce_"..arg,"",0,function()
    tl.coroutines:wait(bounceTable[family][arg][1],0,false)
    local lastBounce = tracker[family].bounced[arg]
    if not lastBounce then return end
    if lastBounce[1] == time then
      tl:put('unrebouncing')
      tl.eventHandler:EventReceiver(lastBounce[2],arg,family)
    end
  end)
end

function DebounceModule:setupDebouncer()
  local config = tl.activeProfile.config.debouncerSettings;
  for g = 1, #tl.stringPresets.families do tracker[tl.stringPresets.families[g]] = {bounced={}} end
  for k, v in pairs(config) do
    bounceTable[k] = {}
    for i = 1, #v do local el = v[i]
      bounceTable[k][remove(el,1)] = el
    end
  end
end

---debounces an event
function DebounceModule:debounceEvent(family,argument,event)-->>> Polling related vars nabbed form g-max====================================================================================
  local bounce = bounceTable[family] and bounceTable[family][argument]
  if not bounce then return false end
  local now 
  if (bounce[2] == nil or eventCategory[family][bounce[2]] == event) and tracker[family][argument] then 
    now = GetRunningTime();
    local bounceValue =  now - (tracker[family][argument] or 0)
    if bounceValue  <  bounce[1] then 
      if tl.activeProfile.config.logBounce then tl:put(concat({'debounced',family,argument,'at',bounceValue..'ms'},' ')) end 
      tracker[family].bounced[argument] = {now,event}
      gracePeriod(family,argument,now)
      return true
    end
  end 
  tracker[family][argument] = now or GetRunningTime()
  return false
end

return DebounceModule