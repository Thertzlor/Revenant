local rv = ...---@type MainLibObject
local Sleep, GetRunningTime, type, pairs, resume, GetMKeyState_Hook, SetMKeyState_Hook, sub = Sleep, GetRunningTime, type, pairs, coroutine.resume, GetMKeyState, SetMKeyState, string.sub
--=============================================================
local PollingModule = rv.baseClass:new()---@class PollingModule:BaseClass Task and Polling functions nabbed from g-max nabbed from kgober (modified)
PollingModule.pollControls = {}

---@param family string
local GetMKeyState = function(family)
    family = family or "lhc"
    if rv.profile.config.pollMKeysOnly or family == rv.profile.config.pollFamily then return rv.polling.pollControls.activeState
    elseif family == "lhc" then return 1
    else return GetMKeyState_Hook(family) end
end

---@param mkey number
---@param family string
local SetMKeyState = function(mkey, family)
    family = family or "lhc"
    if rv.profile.config.pollMKeysOnly or family == rv.profile.config.pollFamily then
        if mkey == rv.polling.pollControls.activeState then return end
        rv.polling.pollControls.activeState = mkey
        rv.polling.pollControls.stateTimer = GetRunningTime() + rv.polling.pollControls.pollDeadTime
    end
    return SetMKeyState_Hook(mkey, family)
end

---played by Library on every poll event
local function _onPollEvent()
    --if rv.mousePositionCheck then rv.mouseMonitorUtils:mouseCheckFunc() end
end

---Starts the polling task.
function PollingModule:initPolling()-->>> Polling related vars nabbed form g-max====================================================================================
    local config = rv.profile.config
    if config.pollInterval <= 0 then
        rv:put("throttling polling")
        config.pollInterval = 1
    end --Prevent low poll rate from Crashing the program.
    self.pollControls.pollDeadTime = 100 -- settling time (in milliseconds) during which old poll events are drained
    self.pollControls.pollRateC = 0
    self.pollControls.pollRateSum = 0
    self.pollControls.pollLastPoll = 0
    self.pollControls.pollRate = config.pollInterval
    self.pollControls.pollRateCI = 1000 / self.pollControls.pollRate
    self.pollControls.onPoll = false
    self.pollControls.cutine = 0
    self.pollControls.activeState = GetMKeyState_Hook(config.pollFamily)
    SetMKeyState_Hook(self.pollControls.activeState, config.pollFamily)
end

---The main polling function
---@param event string
---@param arg number
---@param st number
function PollingModule:poll(event, arg, st)
    if st == nil and self.pollControls.stateTimer ~= nil then return end
    local t = GetRunningTime()
    if event == "M_PRESSED" and arg ~= self.pollControls.activeState then
        if self.pollControls.stateTimer ~= nil and t >= self.pollControls.stateTimer then
            self.pollControls.stateTimer = nil
        end
        if self.pollControls.stateTimer == nil then self.pollControls.activeState = arg end
        self.pollControls.stateTimer = t + self.pollControls.pollDeadTime
    elseif event == "M_RELEASED" and arg == self.pollControls.activeState then
        self.pollControls.pollRateSum = self.pollControls.pollRateSum + (t - self.pollControls.pollLastPoll)
        self.pollControls.pollLastPoll = t
        self.pollControls.pollRateC = self.pollControls.pollRateC + 1
        if self.pollControls.pollRateC == self.pollControls.pollRateCI then
            self.pollControls.pollRate = self.pollControls.pollRateSum / self.pollControls.pollRateCI
            self.pollControls.pollRateSum = 0
            self.pollControls.pollRateC = 0
        end
        if self.pollControls.onPoll then _onPollEvent() end
        Sleep(rv.profile.config.pollInterval)
        SetMKeyState_Hook(self.pollControls.activeState, rv.profile.config.pollFamily)
    end
end

-- Task Management functions (by kgober)
---Continue running tasks.
function PollingModule:doTasks()
    local t = GetRunningTime()
    for key, task in pairs(rv.coroutines.taskList) do
        if t >= task.time and task.paused == false then
            if sub(key, 1, 5) ~= "anon_" then self.pollControls.cutine = key end
            local s, d = resume(task.task, task.run)
            if (not s) or ((d or -1) < 0) then
                rv.coroutines.taskList[key] = nil
                rv.coroutines:sequenceQueue()
                self.pollControls.cutine = 0
                if d and type(d) ~= "number" then rv:put(d) end
            else task.time = task.time + d end
        elseif task.paused == true then task.time = t end
    end
end

---Checks if a  task is running.
---@param key string
function PollingModule:taskRunning(key, paused)
    local task = rv.coroutines.taskList[key]
    if task == nil then return false end
    if paused then return not task.paused end
    return task.run
end

---Sets the inPoll Value.
function PollingModule:onPollEventIni()
    if type(_onPollEvent) == "function" then self.pollControls.onPoll = true end
end

return PollingModule