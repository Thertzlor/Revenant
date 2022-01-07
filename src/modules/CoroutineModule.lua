local rv = ... ---@type Revenant
local abs, floor, random, Sleep, type, insert, remove, pairs, running, yield, unpack, resume, create, GetRunningTime, sub, randomseed = math.abs, math.floor, math.random, Sleep, type, table.insert, table.remove, pairs, coroutine.running, coroutine.yield, unpack, coroutine.resume, coroutine.create, GetRunningTime, string.sub, math.randomseed
local arg = arg ---@type any Intellisense hack
--=============================================================
---@class TaskData
---@field time number
---@field task thread
---@field paused boolean Is the task currently paused?
---@field fam string
---@field run boolean
---@field num number
---@field isTemp boolean
---@field pauseDur number
--=============================================================
---@class CoroutineModule:BaseClass Functions that control coroutines
---@field taskList table<string,TaskData>
---@field randomizer fun():number
local CoroutineModule = rv.baseClass:new()
CoroutineModule.taskRedirect = {} ---@type table<string,string>
CoroutineModule.taskQueue = {}
CoroutineModule.taskList = {}
local anotasks = 0

--TODO:Testing and custom random provider
---Generate random delays for events and keys
---@private
---@param num number
---@param var number
function CoroutineModule:_variance(num, var)
    if var == 0 or not var then return num end
    local result = num
    if var < 1 then
        if var < 0 then var = abs(var) end
        var = floor(num * var)
    end
    if var then result = result + random((var * -1), var) end
    return result
end

---Pause initiate random number generator.
function CoroutineModule:initRandom()
    local manualRandom = (rv.profile.assign.hooks or {}).onRandom
    if not manualRandom then
        randomseed(GetRunningTime())
        random()
        random()
        random()
    end
    self.randomizer = manualRandom or random
end

---Pause function for all coroutines.
---@param dur number
---@param var number
function CoroutineModule:wait(dur, var, forceSleep)
    local finalDur = var and self:_variance(dur, var) or dur
    return ((not forceSleep) and running() and yield(finalDur)) or Sleep(finalDur)
end

---Terminates one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:multiAbort(taskey)
    if taskey and type(taskey) == "string" and taskey ~= "" then self:taskAbort(taskey)
    elseif type(taskey) == "table" then for num = 1, #taskey do self:taskAbort(taskey[num]) end
    elseif taskey == 0 then if rv.polling.pollControls.activeTask ~= 0 then self:taskAbort(rv.polling.pollControls.activeTask) end
    else for k in pairs(self.taskList) do self:taskAbort(k) end end
end

---Pauses one or multiple tasks/coroutines (recursively)
---@param taskey string|table
function CoroutineModule:multiPause(taskey)
    if type(taskey) == "string" and taskey ~= "" then
        local k = self.taskRedirect[taskey] or taskey
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
        local k = self.taskRedirect[taskey] or taskey
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
    local task = {
        time = GetRunningTime(),
        task = create(func),
        pauseDur = 0,
        run = true,
        paused = false,
        fam = fam,
        num = num
    } ---@type TaskData

    if arg[1] and type(arg[1]) == "table" and arg[1].cancel ~= nil then task.isTemp = 1 end
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
    local k = self.taskRedirect[key] or key
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
    self.taskRedirect[key] = act
end

---Removes a subtask
---@param key string
function CoroutineModule:removeSubtask(key)
    self.taskRedirect[key] = nil
end

return CoroutineModule