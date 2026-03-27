local profile, rv = ... ---@type ProfileTemplate, Revenant
local k = profile.key
--[[=============================================================

This is the Revenant Debug and Setup profile. It includes several helpful macros meant to optimize your Revenant experience.


=============================================================]] --
profile.config = {
   devices = "G600", --change to your Mouse model
   monitors = { -- Define Monitor definitions here

   },
   defaultLagFactor = 10,

   --- Do not modify these settings!
   offsetWaitLag = true,
   restrictToMainScreen = false,
   offsetMovementLag = true,
   pollInterval = 1,
   showCompiled = false,
   clearLog = true,
   fragileThreads = false
}

rv.utils.developerMode()
local savedTime, GetRunningTime = 0, GetRunningTime

local function logTimeA()
   savedTime = GetRunningTime()
   rv:put("Current Running Time:" .. savedTime .. "\n")
end

local function logTimeB()
   local currentTime = GetRunningTime()
   rv:put("Current Running Time:" .. currentTime)
   rv:put("Milliseconds since last run:" .. currentTime - savedTime .. "\n")
   savedTime = currentTime
end

local function _resetLagA()
   rv.profile.config.offsetWaitLag = not rv.profile.config.offsetWaitLag
   rv.threading:initLagSettings()
   rv:put("timing lag offset turned " .. rv.profile.config.offsetWaitLag and "on" or "off")
end

local function logMoveLag() rv:put(rv.mouseMonitorUtils:outputLag()) end



--- Press the middle mouse button to log your mouse position and monitor information
k.m3 = {type = "func", rv.utils.logPos}

--- Press mouse button 4 to start monitor setup
k.m4 = {type = "func", function() rv.utils.monitorWizard(profile) end}

--- You can use this macro check if your leg offset needs to be adjusted.
--- It is set to first log the number of milliseconds since the profile was activated.
--- Then, after a 500ms delay it will log again, this time both the running time and the number of milliseconds since the last logging function was executed.
--- After another 250ms this process repeats.
--- If the logged values differ significantly from 500 and 250 respectively, you might want to change your lag settings in the configuration.
k.m5 = {{logTimeA, type = "func"}, 500, {logTimeB, type = "func"}, 250, {logTimeB, type = "func"}, 500, t = "s", loop = 5, actionDelay = 0, keyDelay = 0} --[[@as AssignSequence]]


-- Use this macro to check for movement lag.
-- The movement is meant to last 1 second, and after each iteration the macro will output the automatically calculated lag offset value.
-- This value is meant to be used as your `defaultLagFactor` setting, to ensure consistent movement.
k.m6 = {{t = "fn", logMoveLag}, {{250, 500}, {250, -500}, {-500}, relative = true, duration = 1000, type = "mouseposition"}, {t = "fn", logMoveLag}, loop = 5, type = "sequence", actionDelay = 0}