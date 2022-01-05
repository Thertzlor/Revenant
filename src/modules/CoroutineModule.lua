local rv = ...---@type Revenant
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack, resume, create, GetRunningTime, setmetatable, sub = math.abs, math.floor, math.random, Sleep, type, table.insert, table.remove, pairs, coroutine.running, coroutine.yield, unpack, coroutine.resume, coroutine.create, GetRunningTime, setmetatable, string.sub
--=============================================================
---@class TaskData
---@field time number
---@field task thread
---@field paused boolean Is the task currently paused?
---@field fam string
---@field num number
---@field pauseDur number
--=============================================================
---@class CoroutineModule:BaseClass Functions that control coroutines
---@field taskList table<string,TaskData>
local CoroutineModule = rv.baseClass:new()
local taskRedirect = {}---@type table<string,string>
CoroutineModule.taskQueue = {} ---@type table<number,V>
CoroutineModule.taskList = {}

local anotasks = 0

--TODO:Testing and custom random provider
---Generate random delays for events and keys
---@param num number
---@param var number
local function _variance(num, var)
    if var == 0 or not var then return num end
    local result = num
    if var < 1 then
        if var < 0 then var = abs(var) end
        var = floor(num * var)
    end
    if var then result = result + random((var * -1), var) end
    return result
end

---Pause function for all coroutines.
---@param dur number
---@param var number
function CoroutineModule:wait(dur, var, forceSleep)
    local finalDur = var and _variance(dur, var) or dur
    return ((not forceSleep) and running() and yield(finalDur)) or Sleep(finalDur)
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:multiAbort(taskey)
    if taskey and type(taskey) == "string" and taskey ~= "" then self:taskAbort(taskey)
    elseif type(taskey) == "table" then for num = 1, #taskey do self:taskAbort(k[num]) end
    elseif taskey == 0 then if rv.polling.pollControls.activeTask ~= 0 then self:taskAbort(rv.polling.pollControls.activeTask) end
    else for k in pairs(self.taskList) do self:taskAbort(k) end end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:multiPause(taskey)
    if type(taskey) == "string" and taskey ~= "" then
        local k = taskRedirect[taskey] or taskey
        local ts = self.taskList[k]
        if ts ~= nil then
            ts.paused = true
            rv.str:releaseAll(k)
            rv.polling.pollControls.activeTask = 0
        end
    elseif type(taskey) == "table" then for num = 1, #taskey do self:multiPause(taskey[num]) end
    elseif taskey == 0 then if rv.polling.pollControls.activeTask ~= 0 then self:multiPause(rv.polling.pollControls.activeTask) end
    else for _, v in pairs(self.taskList) do v.paused = true end end
end

---Resumes one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:taskResume(taskey)
    if type(taskey) == "string" and taskey ~= "" then
        local k = taskRedirect[taskey] or taskey
        local ts = self.taskList[k]
        if ts ~= nil then ts.paused = false end
    elseif type(taskey) == "table" then
        for num = 1, #taskey do self:taskResume(taskey[num]) end
    elseif taskey == 0 then if rv.polling.pollControls.activeTask ~= 0 then self:taskResume(rv.polling.pollControls.activeTask) end
    else for _, v in pairs(self.taskList) do v.paused = false end end
end

---Keeps track of what coroutines are currently running
---@param nam string
---@param fam string
---@param num number
---@param inst string
function CoroutineModule:sequenceQueue(nam, fam, num, inst, ...)
    if nam and inst then insert(self.taskQueue, { nam, fam, num, inst })
    else
        for i = #self.taskQueue, 1, -1 do local val = self.taskQueue[i]
            if self.taskList[val[1]] == nil then
                local macro = rv.profile.macroIndex[val[i]]
                self:taskRun(val[1], val[2], val[3], macro.execute, macro, val[4], unpack(arg))
                remove(self.taskQueue, i)
            end
        end
    end
end

---Executes a function as a coroutine.
---@param key string
---@param fam string
---@param num number
---@param func function
function CoroutineModule:taskRun(key, fam, num, func, ...)
    if key then self:taskAbort(key) end
    local task = {} ---@type TaskData
    if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~= nil then task.isTemp = 1 end
    task.time = GetRunningTime()
    task.task = create(func)
    task.pauseDur = 0
    task.run = true
    task.paused = false
    task.fam = fam
    task.num = num
    local taskName = key
    if key then
        rv.polling.pollControls.activeTask = key
        if rv.keyStates.roDown[key] then rv.helperUtils.wipe(rv.keyStates.roDown[key])
        else rv.keyStates.roDown[key] = {} end
    else
        taskName = 'anon_' .. anotasks
        anotasks = anotasks + 1
    end
    local s, d = resume(task.task, unpack(arg))
    if (s) and ((d or -1) >= 0) then
        task.pauseDur = d
        task.time = task.time + d
        self.taskList[taskName] = task
    end
end

---Aborts a task.
---@param key string
function CoroutineModule:taskAbort(key)
    local k = taskRedirect[key] or key
    local task = self.taskList[k]
    if task ~= nil then
        if task.fam and task.num then rv.profile.deviceState[task.fam]["_b" .. task.num] = nil end
        task.run = false
        if rv.profile.macroIndex[k].state then rv.profile.macroIndex[k].state.seqPosition = nil end
        self.taskList[k] = nil
        for i = #self.taskQueue, 1, -1 do if self.taskQueue[i][1] == k then remove(self.taskQueue, i) end end
        if sub(k, 1, 5) ~= "anon_" then rv.str:releaseAll(k) end
        rv.polling.pollControls.activeTask = 0
    end
end

---Adds a subtask
---@param key string
function CoroutineModule:addSubtask(key)
    local act = rv.polling.pollControls.activeTask
    if act == 0 or act == key or not act then return end
    taskRedirect[key] = act
end

---Removes a subtask
---@param key string
function CoroutineModule:removeSubtask(key)
    taskRedirect[key] = nil
end

return CoroutineModule