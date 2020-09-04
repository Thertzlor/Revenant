---@type MainLibObject
local tl, Base = ...
local Sleep, GetRunningTime, type, remove, pairs, unpack, resume, create, GetMKeyState_Hook, SetMKeyState_Hook =
    Sleep,
    GetRunningTime,
    type,
    table.remove,
    pairs,
    unpack,
    coroutine.resume,
    coroutine.create,
    GetMKeyState,SetMKeyState
--=============================================================
---:Task and Polling functions nabbed from g-max nabbed from kgober (modified)
---@class PollingModule
local PollingModule = Base:new()
PollingModule.pollControls = {}

local GetMKeyState = function(family)
    family = family or "lhc"
    if family == tl.config.pollFamily then
        return tl.polling.pollControls.activeState
    elseif family == "lhc" then
        return 1
    else
        return GetMKeyState_Hook(family)
    end
end

local SetMKeyState = function(mkey, family)
    family = family or "lhc"
    if family == tl.config.pollFamily then
        if mkey == tl.polling.pollControls.activeState then
            return
        end
        tl.polling.pollControls.activeState = mkey
        tl.polling.pollControls.stateTimer = GetRunningTime() + tl.polling.pollControls.pollDeadTime
    end
    return SetMKeyState_Hook(mkey, family)
end

---played by Library on every poll event
local function _onPollEvent()
    if tl.mousePositionCheck then
        tl.mouseMonitorUtils:mouseCheckFunc()
    end
end

---Starts the polling task.
function PollingModule:initPolling()
    -->>> Polling related vars nabbed form g-max====================================================================================
    if tl.config.pollInterval <= 0 then
        tl:put("throttling polling")
        tl.config.pollInterval = 1
    end --Prevent low poll rate from Crashing the program.
    self.pollControls.pollDeadTime = 100 -- settling time (in milliseconds) during which old poll events are drained
    self.pollControls.pollRateC = 0
    self.pollControls.pollRateSum = 0
    self.pollControls.pollLastPoll = 0
    self.pollControls.pollRate = tl.config.pollInterval
    self.pollControls.pollRateCI = 1000 / self.pollControls.pollRate
    self.pollControls.onPoll = false
    self.pollControls.cutine = 0
    self.pollControls.activeState = GetMKeyState_Hook(tl.config.pollFamily)
    SetMKeyState_Hook(self.pollControls.activeState, tl.config.pollFamily)
end

---The main polling function
---@param event string
---@param arg number
---@param st number
function PollingModule:poll(event, arg, st)
    if st == nil and self.pollControls.stateTimer ~= nil then
        return
    end
    local t = GetRunningTime()
    if event == "M_PRESSED" and arg ~= self.pollControls.activeState then
        if self.pollControls.stateTimer ~= nil and t >= self.pollControls.stateTimer then
            self.pollControls.stateTimer = nil
        end
        if self.pollControls.stateTimer == nil then
            self.pollControls.activeState = arg
        end
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
        if self.pollControls.onPoll then
            _onPollEvent()
        end
        Sleep(tl.config.pollInterval)
        SetMKeyState_Hook(self.pollControls.activeState, tl.config.pollFamily)
    end
end

-- Task Management functions (by kgober)
---Continue running tasks.
function PollingModule:doTasks()
    local t = GetRunningTime()
    for key, task in pairs(tl.coroutines.taskList) do
        if t >= task.time and task.paused == false then
            self.pollControls.cutine = key
            local s, d = resume(task.task, task.run)
            if (not s) or ((d or -1) < 0) then
                tl.coroutines.taskList[key] = nil
                tl.coroutines:seQueue()
                self.pollControls.cutine = 0
            else
                task.time = task.time + d
            end
        elseif task.paused == true then
            task.time = t
        end
    end
end

---Checks if a  task is running.
---@param key string
function PollingModule:taskRunning(key)
    local task = tl.coroutines.taskList[key]
    if task == nil then
        return false
    end
    return task.run
end

---Sets the inPoll Value.
function PollingModule:onPollEventIni()
    if type(_onPollEvent) == "function" then
        self.pollControls.onPoll = true
    end
end

return PollingModule
