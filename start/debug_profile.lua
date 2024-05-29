local profile, rv = ... ---@type ProfileTemplate, Revenant
rv.utils.developerMode()
local savedTime, GetMousePosition, GetRunningTime = 0, GetMousePosition, GetRunningTime

-- Utility functions
local function logPos()
   local x, y = GetMousePosition()
   rv:put("X Position: " .. x)
   rv:put("Y Position: " .. y)
end

local function logTimeA()
   savedTime = GetRunningTime()
   rv:put("Current Running Time:" .. savedTime)
end
local function logTimeB()
   local currentTime = GetRunningTime()
   rv:put("Current Running Time:" .. currentTime)
   rv:put("Milliseconds since last run:" .. currentTime - savedTime)
   savedTime = currentTime
end

local function resetLagA()
   rv.profile.config.offsetWaitLag = not rv.profile.config.offsetWaitLag
   rv.threading:initLagSettings()
   rv:put("timing lag offset turned " .. rv.profile.config.offsetWaitLag and "on" or "off")
end

profile.config = {
   devices = "G600",
   monitors = {1920, 1080}, -- Put your configuration settings in here.
   offsetWaitLag = true
}

-- Assignments

local k = profile.key -- Quick access to the `key` table used for standard bindings.
---Press the ,middle mouse button to log your mouse position
k.m3 = {logPos, type = "func"} --[[@as AssignFunction]]

k.m9 = {{logTimeA, type = "func"}, 500, {logTimeB, type = "func"}, 250, {logTimeB, type = "func"}, t = "s", actionDelay = 20, keyDelay = 0}

profile.documentation = {}
