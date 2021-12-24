local tl = ...---@type MainLibObject
local remove, type, insert, GetRunningTime = table.remove, type, table.insert, GetRunningTime
---@class HoldKeyOptions:MacroOptions
---@field init boolean
---@field release ('"auto"'|'"hold"')
---@field holdTime number
---@field stagger ('"absolute"'| '"relative"'| '"additive"')
--=============================================================
---@class HoldKeyMacro:MacroDefinition
---@field options HoldKeyOptions
local HoldKeyMacro = tl:classImport('MacroDefinition'):new()

HoldKeyMacro.lintProperties = {
    release = { type = "string", values = { "auto", "hold" } },
    init = { type = "boolean" },
    stagger = { type = "string", values = { "absolute", "relative", "additive" } },
    holdTime = { type = "number" }
}

---@protected
function HoldKeyMacro:parseInstructions()
    local options = self.options ---@type HoldKeyOptions
    options.holdTime = options.holdTime or self.profile.config.defaultHold
    options.release = options.release or "auto"
    options.holdMode = options.holdMode or "relative"
    local rawCom = tl.helperUtils.deepCopy(self.rawCommand)
    local processed = 0
    local command = {}
    local offset = 0

    local function finalIteration()
        if self.init then return end
        local stagMode = options.holdMode
        local deflay = options.holdTime
        local lastN = remove(command)
        local lastNum = -1
        local workTab = {}
        local curlay = 0
        local lastLay

        if type(lastN) == "number" then
            deflay = lastN
            lastLay = lastN
        else command[#command + 1] = lastN end

        if options.init then
            self.initMacro = remove(command, 1)---@type string[]
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

    local function fetcher(tNum, class)
        local initId = class:awaitOwnId()
        if initId then self.subMacros[#self.subMacros + 1] = initId end
        command[tNum] = { initId }
        processed = processed + 1
        if processed == #rawCom then finalIteration() end
    end

    for i = 1, #rawCom do local cmd = rawCom[i]
        local cType = type(cmd)
        if cType == "table" and (not tl.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
            command[i - offset] = { _ref = cmd[1] }
            processed = processed + 1
        elseif cType == "table" then
            local elClass---@type MacroDefinition
            if (not tl.tbl:hasProperties(cmd)) and tl.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = self.profile:identifyTableType(cmd)
            if tableType == "group" then elClass = tl:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = self.profile:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, self.profile, nil, self.overrides, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), elInstance)
        elseif cType == "string" or cType == "number" then
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
    tl.coroutines:wait(mac[1], 0)
    if self.state.stagTimer ~= nil then
        self.state.stagTimer = nil
        self:subRun(mac[2], event)
    end
    return -1
end

---Timing function for held down keys
---@param buttonDirection string
---@param fam string
---@param event Event
function HoldKeyMacro:execute(event)
    local fam, num, dir, cmd, pID = event.family, event.keyNum, event.direction, self.command, self.pID
    if #cmd == 0 then return end
    local time = GetRunningTime()
    local dirge = dir or self.profile.deviceState[fam].dir
    local virtualEvent = self:virtualize(event, 4)
    if self.initMacro then self:subRun(self.initMacro, virtualEvent) end
    if dirge == "down" then
        if self.autoTrigger then tl.coroutines:taskRun(pID, fam, num, self.finalStagger, self, virtualEvent) end
        self.state.stagTimer = time
    elseif dirge == "up" and self.state.stagTimer ~= nil then
        local timeNow = time - self.state.stagTimer
        for g = 1, #cmd do local i = #cmd - g + 1
            local tabsi = cmd[i]
            if tabsi[1] < timeNow then self:subRun(tabsi[2], virtualEvent) break end
        end
        self.state.stagTimer = nil
    end
end

---@private
---@param evStr string[]|string
---@param event Event
function HoldKeyMacro:subRun(evStr, event)
    if type(evStr) == "table" then self.profile.macroIndex[evStr[1]]:run(event)
    else tl.str:typingDelegator(evStr, self:keyPress(event)) end
end

function HoldKeyMacro:control(event)
    local dir = event.direction
    if dir and dir ~= "down" then return end
    self.state.stagTimer = nil
end

return HoldKeyMacro