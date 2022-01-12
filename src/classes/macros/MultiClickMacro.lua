local rv = ...---@type Revenant
local GetRunningTime, type, rep, concat = GetRunningTime, type, string.rep, table.concat
---@class _MultiClickOptions:MacroOptions
---@field timer number
---@field timeMode '"relative"'|'"absolute"'
---@field triggerMode '"normal"'|'"stack"'
--=============================================================
---@alias MultiClickDefinition _MultiClickOptions | MacroInitDefinition
--=============================================================
---@class MultiClickMacro:MacroDefinition
---@field options _MultiClickOptions
---@field waiting boolean
local MultiClickMacro = rv:classImport('MacroDefinition'):new()
MultiClickMacro.lintProperties = { timer = { type = "number", range = { 0 } }, triggerMode = { type = "string", values = { "normal", "stack" } }, timeMode = { type = "string", values = { "relative", "absolute" } } }
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
        self.terminus = self.options.triggerMode == 'stack'
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
        if cType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
            command[i - offset] = { _ref = cmd[1] }
            processed = processed + 1
        elseif cType == "table" then
            local elClass---@type MacroDefinition
            if rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = rv.tbl:identifyTableType(cmd)
            if tableType == "group" then elClass = rv:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = rv.tbl:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, self.profile, nil, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), elInstance)
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
---@param endMoment number
---@param event Event
function MultiClickMacro:altTimer(endMoment, _, _, event)
    local state, config = self.state, self.profile.config
    state.multiTimer = endMoment
    while GetRunningTime() < endMoment do rv.threading:wait(config.pollInterval) end
    state.multiTimer = nil
    if state.multiClick ~= nil and (self.options.triggerMode ~= "stack" or not self.options.triggerMode) then
        self:subRun(self.command[state.multiClick], event, state.multiClick)
    end
    state.multiClick = nil
    return -1
end
--FIXME:Completely rework this
---@private
---@param event Event
---@param curNum number
function MultiClickMacro:timer(endMoment, interval, curNum, event)
    local cmd, state, options = self.command, self.state, self.options
    self.waiting = true
    state.multiTimer = endMoment
    while GetRunningTime() < endMoment and state.multiClick == curNum do
        rv.threading:wait(self.profile.config.pollInterval)
        self.waiting = false
    end
    if state.multiClick == curNum or curNum == #cmd then
        if options.triggerMode ~= "stack" then for i = 1, curNum do self:subRun(cmd[i], event, i) end
        else self:subRun(cmd[curNum], event, 0) end
        state.multiTimer = nil
        state.multiClick = nil
    elseif not self.waiting then rv:put(curNum) self:timer((GetRunningTime() + interval), interval, curNum + 1, event) end
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
        rv.threading:taskRun(pID, fam, num, ((options.timeMode == "absolute" and self.altTimer) or self.timer), self, (GetRunningTime() + time), time, 1, virtualEvent)
    elseif meta.multiTimer ~= nil then meta.multiClick = meta.multiClick + 1 end
    if options.timeMode ~= "absolute" then return -1 end
    local timeActive = meta.multiTimer
    local clickNum = meta.multiClick
    if options.triggerMode == nil or options.triggerMode ~= "stack" then
        if timeActive == nil and cmd[clickNum] ~= nil then
            self:subRun(cmd[clickNum], virtualEvent, 0)
            meta.multiClick = nil
        end
    else for i = 1, clickNum do if cmd[i] ~= nil then self:subRun(cmd[i], virtualEvent, i) end end end
    if timeActive == nil then meta.multiClick = nil end
    return -1
end

---@private
---@param evStr string[]|string
---@param event Event
---@param index number
function MultiClickMacro:subRun(evStr, event, index)
    if type(evStr) == "table" then self.profile.macroIndex[evStr[1]]:run(event)
    else rv.str:typingDelegator(evStr, self:keyPress(event), self.pID .. '_' .. index) end
    return -1
end

function MultiClickMacro:parseDocs()
    if self.manualDocumentation then
        rv.lcd:parseToDisplayDefinition(self.manualDocumentation, self.pID)
    else
        for i = 1, #self.command do local cmd = self.command[i] ---@type string
            if type(cmd) == "string" then rv.lcd:parseToDisplayDefinition(cmd, self.pID .. '_' .. i) end
        end
    end
end

---@param depth number
function MultiClickMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    local subTable = {}
    for i = 1, #self.command do local cmd = self.command[i]
        subTable[#subTable + 1] = type(cmd) == "string" and ('"' .. rv.str:unbreak(cmd) .. '"') or self.profile.macroIndex[cmd[1]]:export(depth + 1)
    end
    local content = #subTable == 0 and false or "\n" .. indent .. concat(subTable, ",\n" .. indent)
    return indent .. self.titleExport .. 'MultiClick: (' .. (content or "") .. "\n" .. indent .. ")"
end

return MultiClickMacro