local rv = ... ---@type Revenant
local type, concat, rep = type, table.concat, string.rep

--[[=============================================================]] --
---@class _KeyOptions:MacroOptions
---@field scope "key"|"family"|"global"
---@field unreverse boolean
--[[=============================================================]] --
---@class __KeyShorthands
---@field ad number Shorthand for "actionDelay"
---@field kd number Shorthand for "keyDelay"
---@field av number Shorthand for "actionVariance"
---@field kv number Shorthand for "keyVariance"
--[[=============================================================]] --
---@alias KeyMacroDefinition _KeyOptions | MacroInitDefinition | __KeyShorthands
--[[=============================================================]] --
---@class KeyMacro:MacroDefinition Handles the default key functions, called by key name or as simple sequence.
---@field command string|string[]
---@field keys KeyDefinition|KeyDefinition[]
---@field firstModifiers string[]
---@field options _KeyOptions
---@field naturalKey boolean
local KeyMacro = rv:classImport('MacroDefinition'):new()
KeyMacro.lintProperties = {
    scope = { type = "string", values = { "key", "global", "family" } },
    actionDelay = { type = "number", range = { 0 } },
    actionVariance = { type = "number", range = { 0 } },
    keyVariance = { type = "number", range = { 0 } },
    keyDelay = { type = "number", range = { 0 } }
}
KeyMacro.shorthands = {
    av = "actionVariance",
    ad = "actionDelay",
    kv = "keyVariance",
    kd = "keyDelay"
}
KeyMacro.lintCommand = { type = "string" }

function KeyMacro:parseInstructions()
    local triggerModes = { keydown = 1, keyup = 2, keytoggle = 3, wrapkey = 4 }
    self.triggerMode = triggerModes[self.type] or 0
    self.singleTrigger = self.triggerMode ~= 0
    local cmd = self.command
    assert(cmd and #cmd ~= 0, "Key macro cannot be empty!")
    if #cmd == 1 then cmd = cmd[1] end
    self.command = cmd
    if type(cmd) == "string" then self.keys = rv.keys:parseKeyName(cmd) or rv.keys:keyParser(cmd)
    else
        local keyCollection = {} ---@type KeyDefinition[]
        self.naturalKey = true
        for i = 1, #cmd do
            local k = assert(rv.keys:parseKeyName(cmd[i]), "In A key macro with multiple entries each entry needs to be a valid key name, not a combined string.")
            keyCollection[#keyCollection + 1] = k
        end
        self.keys = keyCollection
    end
    self.naturalKey = self.naturalKey or rv.keys:parseKeyName(cmd) ~= nil
    if self.keys.key or self.keys.mb then self.firstModifiers = self.keys.modifier or false
    else self.firstModifiers = self.keys[1].modifier or false end
    self:finishInit()
end

---@param depth integer
function KeyMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    return indent .. self.titleExport .. '"' .. (type(self.command) == "table" and rv.str:unbreak(concat(self.command, '+')) or rv.str:unbreak(self.command)) .. '"'
end

function KeyMacro:unBuffer()
    if self.firstModifiers and not self.keys[1] then
        self.keys.modifier = self.firstModifiers
        self.keys.buffer = nil
    elseif self.firstModifiers then
        self.keys[1].modifier = self.firstModifiers
        self.keys[1].buffer = nil
    end
end

---@param event Event
function KeyMacro:execute(event)
    local unrev = self.options.unreverse
    local press = self:keyPress(event)
    local vir = event.virtualType
    local keys = rv.keys:applyStringBuffer(self.keys, press)
    press.forceSleep = true
    if self.triggerMode == 0 then
        if event.direction == "down" or (vir and vir ~= 3) then
            if self.naturalKey then
                if vir and vir ~= 3 then
                    rv.keys:pressAndRelease(keys, press)
                else rv.keys:press(keys, press) end
            else
                rv.keys:typingDelegator(keys, press, self.pID, true)
                rv.keys:unwrap(press, unrev)
                self:unBuffer()
            end
        elseif self.naturalKey then
            rv.keys:release(keys, press, unrev)
            rv.keys:unwrap(press, unrev)
            self:unBuffer()
        end
    elseif self.triggerMode == 1 then
        rv.keys:press(keys, press)
        self:unBuffer()
    elseif self.triggerMode == 2 then
        rv.keys:release(keys, press, unrev)
        rv.keys:unwrap(press, unrev)
        self:unBuffer()
    elseif self.triggerMode == 3 then
        local keyName = self.pID
        local toggled = rv.profile.toggledMacroKeys
        if not toggled[keyName] then
            toggled[keyName] = 1
            rv.keys:press(keys, press)
        else
            rv.keys:release(keys, press, unrev)
            toggled[keyName] = nil
            rv.keys:unwrap(press, unrev)
            self:unBuffer()
        end
    elseif self.triggerMode == 4 then
        local fam = event.family
        local num = event.keyNum
        local wrapScope = self.options.scope or "global"
        local state = rv.profile.deviceState
        local wrapperTargets = { key = state[fam]["_b" .. num], family = state[fam], ["global"] = rv.profile.globalState }
        local wrapTarget = wrapperTargets[wrapScope]
        if not wrapTarget and wrapScope == "key" then
            state[fam]["_b" .. num] = {}
            wrapTarget = state[fam]["_b" .. num]
        end
        if not wrapTarget.wrapperContent then wrapTarget.wrapperContent = {} end
        if keys[1] then
            for i = 1, #keys do wrapTarget.wrapperContent[#wrapTarget.wrapperContent + 1] = keys[i] end
        else wrapTarget.wrapperContent[#wrapTarget.wrapperContent + 1] = keys end
        rv.keys:press(keys, press)
    end
end

return KeyMacro
