local rv = ... ---@type Revenant
local GetRunningTime, pairs, remove, concat = GetRunningTime, pairs, table.remove, table.concat

--[[=============================================================]] --
---@alias TimePair {[1]:integer, [2]?:string} #first element time elapsed, second element: event type
--[[=============================================================]] --
---Debouncing keys, still needs work
---@class DebounceModule:BaseClass
local DebounceModule = rv.baseClass:new()
---storage for all debounded events
local bounceTable = {} ---@type table<HardwareFamily,TimePair[]>
---tracking event timings per family
local tracker = {} ---@type table<HardwareFamily,{bounced:TimePair[]}>

local eventCategory = {mouse = {up = "MOUSE_BUTTON_RELEASED", down = "MOUSE_BUTTON_PRESSED"}} ---events for different devices, potentially incomplete

---defines a grace period during which debounced events can be undebounced, not currently used
---@param family HardwareFamily #target family
---@param arg integer #key number
---@param time integer #time in milliseconds
---@async
---@diagnostic disable-next-line: unused-local, unused-function
local function gracePeriod(family, arg, time)
   ---@async
   rv.threading:taskRun(nil, nil, nil, function() -- timer in separate thread
      rv.threading:wait(bounceTable[family][arg][1], 0, false)
      local lastBounce = tracker[family].bounced[arg]
      if not lastBounce then return end
      if lastBounce[1] == time then -- simulating a replay of the event
         rv:put("unrebouncing")
         -- rv.eventHandler:EventReceiver(lastBounce[2], arg, family)
      end
   end)
end

---setup debouncing data
function DebounceModule:setupDebounce()
   if not rv.profile.config.enableDebounce then return end -- not enabled, nothing happens
   local config = rv.profile.config.debounceSettings;
   for g = 1, #rv.presets.stringPresets.families do tracker[rv.presets.stringPresets.families[g]] = {bounced = {}} end
   for k, v in pairs(config) do -- putting in debounce timings for different keys
      bounceTable[k] = {}
      for i = 1, #v do
         local el = v[i]
         bounceTable[k][remove(el, 1)] = el --[[@as any]]
      end
   end
end

---debounces an event
---@param family HardwareFamily #Device Family of the Event
---@param argument integer #number of the key
---@param event EventType #LGS designation of the event
function DebounceModule:debounceEvent(family, argument, event)
   local bounce = bounceTable[family] and bounceTable[family][argument]
   if not bounce then return false end
   local now ---@type integer?
   if (bounce[2] == nil or eventCategory[family][bounce[2]] == event) and tracker[family][argument] then
      now = GetRunningTime();
      local bounceValue = now - (tracker[family][argument] or 0) -- setting time difference
      if bounceValue < bounce[1] then -- detecting if the press was too fast
         if rv.profile.config.logDebounce then rv:put(concat({"debounced", family, argument, "at", bounceValue .. "ms"}, " ")) end
         tracker[family].bounced[argument] = {now, event}
         return true
      end
   end
   tracker[family][argument] = now or GetRunningTime() ---@type integer
   return false
end

return DebounceModule
