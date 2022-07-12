local rv = ... ---@type Revenant
local remove, type, insert, GetRunningTime = table.remove, type, table.insert, GetRunningTime

---@class _HoldKeyOptions:MacroOptions
---@field init boolean
---@field release "auto"|"hold"
---@field holdTime number
---@field stagger "absolute"| "relative"| "additive"
--[[=============================================================]] --
---Assign a macro that triggers different actions depending on how long a key is pressed.
---@alias AssignHoldKey _HoldKeyOptions | MacroInitDefinition | mt<"holdkey"|"h">
--[[=============================================================]] --
---@class HoldStats:MacroStatContainer
---@field stagTimer number
--[[=============================================================]] --
---A macro that triggers different actions depending on how long a key is pressed.
---@class HoldKeyMacro:MacroDefinition
---@field options _HoldKeyOptions
---@field state HoldStats
---@field keyData KeyObject[]
local HoldKeyMacro = rv:classImport('MacroDefinition'):new()
HoldKeyMacro.terminus = false
HoldKeyMacro.continuous = true

HoldKeyMacro.lintProperties = {
    release = { type = "string", values = { "auto", "hold" } },
    init = { type = "boolean" },
    stagger = { type = "string", values = { "absolute", "relative", "additive" } },
    holdTime = { type = "number" }
}

---@protected
function HoldKeyMacro:parseInstructions()
    local options = self.options
    self.keyData = {}
    options.holdTime = options.holdTime or rv.profile.config.defaultHold
    options.release = options.release or "auto"
    options.holdMode = options.holdMode or "relative"
    local rawCom = rv.utils.deepCopy(self.rawCommand)
    local processed = 0
    local command = {} ---@type (string|number|{_ref:string})[]
    local offset = 0

    local function finalIteration()
        if self.init then return end
        local stagMode = options.holdMode
        local deflay = options.holdTime
        local lastN = remove(command) ---@type string|number|{_ref:string}
        local lastNum = -1
        local workTab = {} ---@type table<number,string|number|{_ref:string}>
        local curlay = 0
        local lastLay

        if type(lastN) == "number" then
            deflay = lastN
            lastLay = lastN
        else command[#command + 1] = lastN end

        if options.init then
            self.terminus = true
            self.initMacro = remove(command, 1)
            if type(self.initMacro) == "table" and self.initMacro._ref then local ref = self.initMacro._ref
                self.initMacro = { ref }
                self:async(function()
                    local fetched = self:awaitId(ref, true)
                    self.references[#self.references + 1] = fetched
                    self.initMacro = { fetched }
                end)
            end
        end

        for i = 1, #command do local cmd = command[i]
            if type(cmd) == "number" then
                deflay = cmd
                lastNum = i
            else
                if #workTab ~= 0 then
                    if stagMode == "absolute" then curlay = deflay
                    else
                        if stagMode ~= "additive" and i ~= lastNum + 1 then deflay = lastLay or options.holdTime end
                        curlay = curlay + deflay
                    end
                end
                insert(workTab, { curlay, cmd })
            end
        end
        if self.options.release == "auto" then self.autoTrigger = remove(workTab) end
        self.command = workTab
        for i = 1, #self.command do local finCm = self.command[i][2]
            if type(finCm) == "table" and finCm._ref then local ref = finCm._ref
                self.command[i] = { ref }
                self:async(self.replaceWithReferenceId, self, ref, 2, self.command[i], true)
            end
        end
        self:finishInit()
    end

    ---@param tNum integer
    ---@param class MacroDefinition
    local function fetcher(tNum, class)
        local initId = class:awaitOwnId()
        if initId then self.subMacros[#self.subMacros + 1] = initId end
        command[tNum] = { initId }
        processed = processed + 1
        if processed == #rawCom then finalIteration() end
    end

    for i = 1, #rawCom do local cmd = rawCom[i]
        local cType = type(cmd)
        if cType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
            command[i - offset] = { _ref = cmd[1] }
            processed = processed + 1
        elseif cType == "table" then
            local elClass ---@type MacroDefinition|false
            if (not rv.tbl:hasProperties(cmd)) and rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = rv.tbl:identifyTableType(cmd)
            if tableType == "group" then elClass = rv:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = rv.tbl:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, nil, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), elInstance)
        elseif cType == "string" or cType == "number" then
            if cType == "string" then self.keyData[i - offset] = rv.keys:keyParser(cmd) end
            command[i - offset] = cmd
            processed = processed + 1
        else
            offset = offset + 1
            processed = processed + 1
        end
        if processed == #rawCom then finalIteration() end
    end
end

---Auto execute function for staggered keys after timer runs out
---@private
---@param event Event
function HoldKeyMacro:finalStagger(event)
    local mac = self.autoTrigger
    rv.threading:wait(mac[1], 0)
    if self.state.stagTimer ~= nil then
        self.state.stagTimer = nil
        self:subRun(mac[2], event, 0)
    end
    return -1
end

---Timing function for held down keys
---@param event Event
function HoldKeyMacro:execute(event)
    local fam, num, dir, cmd, pID = event.family, event.keyNum, event.direction, self.command, self.pID
    if #cmd == 0 then return end
    local time = GetRunningTime()
    local dirge = dir or rv.profile.deviceState[fam].dir
    local virtualEvent = self:virtualize(event, 4)
    if self.initMacro then self:subRun(self.initMacro, virtualEvent, 0) end
    if dirge == "down" then
        if self.autoTrigger then rv.threading:taskRun(pID, fam, num, self.finalStagger, self, virtualEvent) end
        self.state.stagTimer = time
    elseif dirge == "up" and self.state.stagTimer ~= nil then
        local timeNow = time - self.state.stagTimer
        for g = 1, #cmd do local i = #cmd - g + 1
            local tabsi = cmd[i]
            if tabsi[1] < timeNow then self:subRun(tabsi[2], virtualEvent, i) break end
        end
        self.state.stagTimer = nil
    end
end

function HoldKeyMacro:parseDocs()
    if self.manualDocumentation then
        rv.lcd:parseToTextDisplay(self.manualDocumentation, self.pID)
    else
        for i = 1, #self.command do local cmd = self.command[i][2] ---@type string
            if type(cmd) == "string" then rv.lcd:parseToTextDisplay(cmd, self.pID .. '_' .. i) end
        end
    end
end

---@private
---@param evStr l<string>
---@param event Event
---@param index number
function HoldKeyMacro:subRun(evStr, event, index)
    if type(evStr) == "table" then rv.profile.macroIndex[evStr[1]]:run(event)
    else rv.keys:typingDelegator(self.keyData[index], self:keyPress(event), self.pID .. '_' .. index) end
end

---@param event  Event
function HoldKeyMacro:control(event)
    local dir = event.direction
    if dir and dir ~= "down" then return end
    self.state.stagTimer = nil
end

return HoldKeyMacro
