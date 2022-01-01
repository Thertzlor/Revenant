local rv = ...---@type MainLibObject
local Sleep, GetRunningTime, type, pairs, remove, concat = Sleep, GetRunningTime, type, pairs, table.remove, table.concat
--=============================================================
local DebounceModule = rv.baseClass:new()---@class DebounceModule:BaseClass Debouncing keys
local bounceTable = {}
local tracker = {}
local bounced = {}

local eventCategory = { mouse = { up = "MOUSE_BUTTON_RELEASED", down = "MOUSE_BUTTON_PRESSED" } }

---@param family string
---@param arg number
---@param time number
local function gracePeriod(family, arg, time)
    rv.coroutines:taskRun(nil, nil, nil, function()
        rv.coroutines:wait(bounceTable[family][arg][1], 0, false)
        local lastBounce = tracker[family].bounced[arg]
        if not lastBounce then return end
        if lastBounce[1] == time then
            rv:put('unrebouncing')
            rv.eventHandler:EventReceiver(lastBounce[2], arg, family)
        end
    end)
end

function DebounceModule:setupDebouncer()
    local config = rv.profile.config.debouncerSettings;
    for g = 1, #rv.stringPresets.families do tracker[rv.stringPresets.families[g]] = { bounced = {} } end
    for k, v in pairs(config) do
        bounceTable[k] = {}
        for i = 1, #v do local el = v[i]
            bounceTable[k][remove(el, 1)] = el
        end
    end
end

---debounces an event
---@param family string
---@param argument number
---@param event Event
function DebounceModule:debounceEvent(family, argument, event)-->>> Polling related vars nabbed form g-max====================================================================================
    local bounce = bounceTable[family] and bounceTable[family][argument]
    if not bounce then return false end
    local now ---@type number
    if (bounce[2] == nil or eventCategory[family][bounce[2]] == event) and tracker[family][argument] then
        now = GetRunningTime();
        local bounceValue = now - (tracker[family][argument] or 0)
        if bounceValue < bounce[1] then
            if rv.profile.config.logBounce then rv:put(concat({ 'debounced', family, argument, 'at', bounceValue .. 'ms' }, ' ')) end
            tracker[family].bounced[argument] = { now, event }
            gracePeriod(family, argument, now)
            return true
        end
    end
    tracker[family][argument] = now or GetRunningTime()
    return false
end

return DebounceModule