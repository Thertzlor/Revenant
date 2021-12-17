local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local GetRunningTime, type = GetRunningTime, type

---@class MultiClickOptions:MacroOptions
---@field timer number
--=============================================================
---@class MultiClickMacro:MacroDefinition
---@field options MultiClickOptions
local MultiClickMacro = MacroDefinition:new()
MultiClickMacro.lintProperties = {
    timer = { type = "number", range = { 0 } }
}
MultiClickMacro.singleTrigger = true
---@protected
function MultiClickMacro:parseInstructions()
    self.options.timer = self.options.timer or self.profile.config.multiClickTime
    local processed = 0
    local offset = 0
    local command = {}
    local function finalIteration()
        if self.init then return end
        self.command = command
        for i = 1, #self.command do local finCm = self.command[i]
            if finCm._ref then
                local ref = finCm._ref
                self.command[i] = { ref }
                self:async(self.replaceWithReferenceId, self, ref, i, self.command, true)
            end
        end
        self:finishInit()
    end

    local function fetcher(tNum, class)
        local initId = class:awaitOwnId()
        if initId then self.subMacros[#self.subMacros + 1] = initId end
        command[tNum] = { initId }
        processed = processed + 1
        if processed == #self.rawCommand then finalIteration() end
    end

    for i = 1, #self.rawCommand do local cmd = self.rawCommand[i]
        local cType = type(cmd)
        if cType == "table" and (not tl.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
            command[i - offset] = { _ref = cmd[1] }
            processed = processed + 1
        elseif cType == "table" then
            local elClass---@type MacroDefinition
            if tl.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = self.profile:identifyTableType(cmd)
            if tableType == "group" then elClass = tl:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = self.profile:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, self.profile, nil, self.overrides, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), el)
        elseif cType == "string" then
            command[i - offset] = cmd
            processed = processed + 1
        else
            offset = offset + 1
            processed = processed + 1
        end
        if processed == #self.rawCommand then finalIteration() end
    end
end

---Alternate waiting function for multi click keys
---@private
---@param key string
---@param endMoment number
---@param id string
---@param event Event
function MultiClickMacro:altTimer(endMoment, _, __, event)
    local state, config = self.state, self.profile.config
    state.multiTimer = endMoment
    while GetRunningTime() < endMoment do tl.coroutines:wait(config.pollInterval) end
    state.multiTimer = nil
    if state.multiClick ~= nil and (self.options.mode ~= "stack" or not self.options.mode) then
        self:subRun(self.command[state.multiClick], event)
    end
    state.multiClick = nil
    return -1
end

---@private
---@param event Event
function MultiClickMacro:timer(endMoment, interval, curNum, event)
    local cmd, state, options = self.command, self.state, self.options
    state.multiTimer = endMoment
    while GetRunningTime() < endMoment and state.multiClick == curNum do
        tl.coroutines:wait(self.profile.config.pollInterval)
    end
    if state.multiClick == curNum or curNum == #cmd then
        if options.mode ~= "stack" then
            for i = 1, curNum do self:subRun(cmd[i], event) end
        else self:subRun(cmd[curNum], event) end
        state.multiTimer = nil
        state.multiClick = nil
    else self:timer((GetRunningTime() + interval), curNum, event) end
    return -1
end

---timing function for multi-click keys
---@param event Event
function MultiClickMacro:execute(event)
    local pID, options, cmd, fam, num = self.pID, self.options, self.command, event.family, event.keyNum
    local time = self.options.timer
    local meta = self.state
    local virtualEvent = self:virtualize(event, 5)
    if not meta.multiTimer and not meta.multiClick then
        meta.multiClick = 1
        tl.coroutines:taskRun(pID, fam, num, ((options.timeMode == "absolute" and self.altTimer) or self.timer), self, (GetRunningTime() + time), time, 1, virtualEvent)
    elseif meta.multiTimer ~= nil then meta.multiClick = meta.multiClick + 1 end
    if options.timeMode ~= "absolute" then return -1 end
    local timeActive = meta.multiTimer
    local clickNum = meta.multiClick

    if options.mode == nil or options.mode ~= "stack" then
        if timeActive == nil and cmd[clickNum] ~= nil then
            self:subRun(cmd[clickNum], virtualEvent)
            meta.multiClick = nil
        end
    else for i = 1, clickNum do if cmd[i] ~= nil then self:subRun(cmd[i], virtualEvent) end end end
    if timeActive == nil then meta.multiClick = nil end
    return -1
end

---@private
---@param evStr string[]|string
---@param event Event
function MultiClickMacro:subRun(evStr, event)
    if type(evStr) == "table" then self.profile.macroIndex[evStr[1]]:run(event)
    else tl.str:typingDelegator(evStr, self:keyPress(event)) end
end

return MultiClickMacro