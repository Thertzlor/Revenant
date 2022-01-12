local rv = ...---@type Revenant
local type, GetRunningTime, abs, huge, rep, concat = type, GetRunningTime, math.abs, math.huge, string.rep, table.concat
---@class _CycleOptions:MacroOptions
---@field inherit "'all'"| "'none'"| "'timing'"| "'status'"
---@field limit string|number The ultimate limit
---@field range number[]
---@field interval number
---@field finish table|'"stall"'|'"end"'|'"reset"'
---@field cancel number|string
--=============================================================
---@class __CycleShorthands
---@field i number Shorthand for "interval"
---@field cn number|string Shorthand for "cancel"
--=============================================================
---@alias Cycledefinition MacroInitDefinition|_CycleOptions|__CycleShorthands
--=============================================================
---@class CycleMacro:MacroDefinition
---@field options _CycleOptions
---@field wamma nil
---@field command table<number, string|table>
local CycleMacro = rv:classImport('MacroDefinition'):new()

CycleMacro.lintProperties = {
    limit = { type = "number", range = { 0 } },
    range = { type = "table", tableKeys = "number", tableTypes = "number" },
    inherit = { type = "string", values = { "all", "none", "timing", "status" } },
    cancel = { type = "number" },
    interval = { type = "number", range = { 1 } },
    finish = { type = { "table", "string" }, values = { "stall", "end", "reset" } }
}

CycleMacro.shorthands = { cn = "cancel", i = "interval" }

CycleMacro.singleTrigger = false
CycleMacro.terminus = false

---@protected
function CycleMacro:parseInstructions()
    if self.options.limit == 0 or not self.options.limit then self.options.limit = huge end
    self.options.inherit = self.options.inherit or "all"
    self.options.cancel = self.options.cancel or 0
    self.options.finish = self.options.finish or "stall"
    self.unstable = (self.options.cancel == 1 or self.options.cancel < 0)
    self.command = {}
    local processed = 0
    local offset = 0
    local command = {}

    local function finalIteration()
        if self.init then return end
        self.command = command
        for i = 1, #self.command do local finCm = self.command[i]
            if finCm._ref then local ref = finCm._ref
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
        if cType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
            command[i - offset] = { _ref = cmd[1] }
            processed = processed + 1
        elseif cType == "table" then
            local elClass---@type MacroDefinition
            if (not rv.tbl:hasProperties(cmd)) and rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
            local tableType = rv.tbl:identifyTableType(cmd)
            if tableType == "group" then elClass = rv:classImport('GroupMacro')
            elseif tableType == "macro" then elClass = rv.tbl:getMacroClass(cmd) end
            if not elClass then return end
            local elInstance = elClass:new(cmd, nil, self.stack, self.sourceDevice)
            self:async(fetcher, (i - offset), elInstance)
        elseif cType == "number" or cType == "string" then
            command[i - offset] = cmd
            processed = processed + 1
        else
            offset = offset + 1
            processed = processed + 1
        end
        if processed == #self.rawCommand then finalIteration() end
    end
end

function CycleMacro:parseDocs()
    if self.manualDocumentation then
        rv.lcd:parseToDisplayDefinition(self.manualDocumentation, self.pID)
    else
        for i = 1, #self.command do local cmd = self.command[i]
            if type(cmd) == "string" then rv.lcd:parseToDisplayDefinition(cmd, self.pID .. '_' .. i) end
        end
    end
end

---@param event Event
function CycleMacro:execute(event)
    local dir, vir, virtParent = event.direction, event.virtualType, event.originator
    local cycles = self.command ---@type table<number,MacroDefinition|string|number>
    local options = self.options ---@type _CycleOptions
    local meta = self.state
    if type(cycles) ~= "table" then return end
    local step = 1
    local lim = options.limit
    local inherit = options.inherit
    local rupture = options.cancel
    local parent = (virtParent and type(virtParent) ~= "number" and virtParent) or virtParent or 999
    local quitter = options.finish
    local start = 1
    local interval = options.interval or 1
    local init = start
    local finish = #cycles
    if type(options.range) == "table" and rv.tbl:isSingleTypeTable(cycles.range, "number") then
        local range = options.range
        for j = 1, range do if range[j] <= 0 then range[j] = #cycles + range[j] end end
        if range[2] and range[2] < #cycles then init = range[2] end
        if range[1] < #cycles then start = range[1] end
        finish = range[3] or finish
        if finish > #cycles then finish = #cycles end
    end
    local directed = vir and 2 or 3
    ---@type Event
    local virtualEvent = self:virtualize(event, directed)
    local press = self:keyPress(event)---@type KeyPress
    if meta.position == nil or (vir and dir == "down" and (rv.profile.macroIndex[parent].state.position == 1)
    and meta.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
        meta.position = init
        meta.cyclesComplete = 1
        meta.cycleTimer = GetRunningTime()
    elseif rupture ~= 0 and rupture ~= 1 and (dir == "down") and (GetRunningTime() - meta.cycleTimer > abs(rupture)) then
        meta.position = init
        meta.cyclesComplete = 1
    end
    if type(meta.cyclesComplete) == "number" and meta.cyclesComplete > lim then
        if quitter == "end" then return
        elseif quitter == "reset" then
            meta.position = init
            meta.cyclesComplete = 1
        elseif type(quitter) == "table" then
            rv.profile.macroIndex[quitter[1]]:run(virtualEvent)
            return
        end
    end
    if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
        meta.cycleTimer = (rv.profile.macroIndex[parent].state and rv.profile.macroIndex[parent].state.cycleTimer) or GetRunningTime()
    else meta.cycleTimer = GetRunningTime() end
    if meta.position ~= 1 or type(cycles[meta.position]) ~= "number" then
        local mac = cycles[meta.position]
        local macType = type(mac)
        if macType == "table" then rv.profile.macroIndex[mac[1]]:run(virtualEvent)
        elseif macType == "string" and (meta.matchUp or meta.matchDown) then rv.str:typingDelegator(mac, press, (self.pID .. '_' .. meta.position)) end
    end
    if dir == "up" or (vir and vir ~= 2 and vir ~= 3) then
        while type(cycles[meta.position + ((step + (interval)) - 1)]) == "number" do step = step + interval end
        meta.position = meta.position + ((step + interval) - 1)
        if meta.position > finish or meta.position > #cycles then
            if not (init > finish and meta.position <= #cycles and meta.cyclesComplete == 1) then
                if meta.cyclesComplete < lim then
                    meta.position = start + meta.position - finish - 1
                    meta.cyclesComplete = meta.cyclesComplete + 1
                else
                    meta.cyclesComplete = lim + 1
                    meta.position = #cycles
                end
            end
        end
    end
end

---Set the position in the current cycle
---@private
---@param position number
function CycleMacro:setCyclePosition(position)
    if type(position) ~= "number" then return end
    local options = self.options  ---@type _CycleOptions
    local cycleState = (options.cancel > 0) and self.state.position or false
    rv.tbl:cycleIndex(#self.command, position, cycleState)
end

---Set the numbers of cycles seen as completed
---@param number number
function CycleMacro:setCyclesCompleted(number)
    if type(number) ~= "number" then return end
    self.state.cyclesComplete = number
end

--TODO:retest control and lcd output
---@param options number|number[]
---@param output boolean|number
---@param duration number
---@param controlId string
function CycleMacro:control(options, output, duration, controlId)
    local positionOption = options
    local completedOption
    if type(options) == "table" then
        positionOption = options[1]
        completedOption = options[2]
    end
    if positionOption == 0 then self.state.position = nil
    elseif positionOption then self:setCyclePosition(positionOption) end
    if completedOption then self:setCyclesCompleted(completedOption) end
    if output then rv.lcd:displayOnLCD(self.pID .. '_' .. controlId, 1, duration) end
end

---@param depth number
function CycleMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    local nextIndent = rep("  ", depth + 1)
    local subTable = {}
    for i = 1, #self.command do local cmd = self.command[i]
        subTable[#subTable + 1] = type(cmd) == "string" and (nextIndent .. '"' .. cmd .. '"') or rv.profile.macroIndex[cmd[1]]:export(depth + 1)
    end
    local content = #subTable == 0 and false or "\n" .. concat(subTable, ",\n")
    return indent .. (self.titleExport or '') .. 'Cycle: (' .. (content or "") .. "\n" .. indent .. ")"
end

return CycleMacro