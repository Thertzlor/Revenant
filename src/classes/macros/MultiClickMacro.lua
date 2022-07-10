local rv = ... ---@type Revenant
local type, rep, concat = type, string.rep, table.concat

---@class _MultiClickOptions:MacroOptions
---@field timer number
---@field timeMode "relative"|"absolute"
---@field triggerMode "normal"|"stack"
--[[=============================================================]] --
---@class MultiClickState:MacroStatContainer
---@field multiClick number
---@field multiTimer number
--[[=============================================================]] --
---Assign a macro for triggering different activities depending how many times a button has been pressed within a short timespan.
---@alias AssignMultiClick _MultiClickOptions | MacroInitDefinition | mt<"multiclick"|"t">
--[[=============================================================]] --
---A macro for triggering different activities depending how many times a button has been pressed within a short timespan.
---@class MultiClickMacro:MacroDefinition
---@field options _MultiClickOptions
---@field waiting boolean
---@field timerId string
---@field state MultiClickState
---@field keyData KeyObject[]
local MultiClickMacro = rv:classImport('MacroDefinition'):new()
MultiClickMacro.lintProperties = { timer = { type = "number", range = { 0 } }, triggerMode = { type = "string", values = { "normal", "stack" } }, timeMode = { type = "string", values = { "relative", "absolute" } } }
MultiClickMacro.singleTrigger = true
---@protected
function MultiClickMacro:parseInstructions()
    self.keyData = {}
    self.options.timer = self.options.timer or rv.profile.config.multiClickTime
    self.options.timeMode = self.options.timeMode or "relative"
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
        self.timerId = self.pID .. '_timer'
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
            local elClass ---@type MacroDefinition|false
            if rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = rv.tbl:identifyTableType(cmd)
            if tableType == "group" then elClass = rv:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = rv.tbl:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, nil, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), elInstance)
        elseif cType == "string" then
            if cType == "string" then self.keyData[i - offset] = rv.keys:keyParser(cmd) end
            command[i - offset] = cmd
            processed = processed + 1
        else
            offset = offset + 1
            processed = processed + 1
        end
        if processed == #self.rawCommand then finalIteration() end
    end
end

---@private
---@param waitTime number
---@param event Event
function MultiClickMacro:timer(waitTime, event)
    local cmd = self.command
    local state = self.state
    local stack = self.options.triggerMode == "stack"
    rv.threading:wait(waitTime);
    local click = state.multiClick
    state.multiClick = nil
    if stack then -- see timer events
        for i = 1, click do self:subRun(cmd[i], event, i) end
    else self:subRun(cmd[click], event, click) end
    return -1
end

---timing function for multi-click keys
---@param event Event
function MultiClickMacro:execute(event)
    local options, cmd, fam, num = self.options, self.command, event.family, event.keyNum
    local interval = options.timer
    local state = self.state
    local virtualEvent = self:virtualize(event, 5)
    if not state.multiClick then -- First click
        state.multiClick = 1
        rv.threading:taskRun(self.timerId, fam, num, self.timer, self, interval, virtualEvent) --Event fires after interval times out without any further click
    else
        state.multiClick = state.multiClick + 1
        if state.multiClick == #cmd then -- If we're at the last click we fire teh event immediately and cancel the timer
            local click = state.multiClick
            rv.threading:taskAbort(self.timerId)
            if options.triggerMode == "stack" then for i = 1, click do self:subRun(cmd[i], event, i) end --If the mode is set to stack all previous click events are fired as well
            else self:subRun(cmd[click], event, click) end -- ...If not we just fire the current event.
            state.multiClick = nil
        elseif options.timeMode == "relative" then -- In "relative" mode not all clicks have to within a single interval, rather each click resets the interval
            rv.threading:taskAbort(self.timerId)
            rv.threading:taskRun(self.timerId, fam, num, self.timer, self, interval, virtualEvent)
        end
    end
    return -1
end

---@private
---@param evStr string[]|string
---@param event Event
---@param index number
function MultiClickMacro:subRun(evStr, event, index)
    if type(evStr) == "table" then rv.profile.macroIndex[evStr[1]]:run(event)
    else rv.keys:typingDelegator(self.keyData[index], self:keyPress(event), self.pID .. '_' .. index) end
    return -1
end

function MultiClickMacro:parseDocs()
    if self.manualDocumentation then
        rv.lcd:parseToTextDisplay(self.manualDocumentation, self.pID)
    else
        for i = 1, #self.command do local cmd = self.command[i] ---@type string
            if type(cmd) == "string" then rv.lcd:parseToTextDisplay(cmd, self.pID .. '_' .. i) end
        end
    end
end

---@param depth? integer
function MultiClickMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    local subTable = {}
    for i = 1, #self.command do local cmd = self.command[i]
        subTable[#subTable + 1] = type(cmd) == "string" and ('"' .. rv.str:unbreak(cmd) .. '"') or rv.profile.macroIndex[cmd[1]]:export(depth + 1)
    end
    local content = #subTable == 0 and false or "\n" .. indent .. concat(subTable, ",\n" .. indent)
    return indent .. self.titleExport .. 'MultiClick: (' .. (content or "") .. "\n" .. indent .. ")"
end

return MultiClickMacro
