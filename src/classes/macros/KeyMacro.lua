local rv = ...---@type Revenant
local type, running, concat, rep = type, coroutine.running, table.concat, string.rep
--=============================================================
---@class _KeyOptions:MacroOptions
---@field scope '"key"'|'"family"'|'"global"'
---@field unreverse boolean
--=============================================================
---@class __KeyShorthands
---@field ad number Shorthand for "actionDelay"
---@field kd number Shorthand for "keyDelay"
---@field av number Shorthand for "actionVariance"
---@field kv number Shorthand for "keyVariance"
--=============================================================
---@alias KeyMacroDefinition _KeyOptions | MacroInitDefinition | __KeyShorthands
--=============================================================
---@class KeyMacro:MacroDefinition Handles the default key functions, called by key name or as simple sequence.
---@field command string|string[]
---@field keys KeyDefinition|KeyDefinition[]
---@field firstModifiers string[]
---@field options _KeyOptions
---@field naturalKey boolean
local KeyMacro = rv:classImport('MacroDefinition'):new()
KeyMacro.lintProperties = {
    scope = { type = "string",
    values = { "key", "global", "family" } },
    actionDelay = { type = "number", range = { 0 } },
    actionVariance = { type = "number", range = { 0 } },
    keyVariance = { type = "number", range = { 0 } },
    keyDelay = { type = "number", range = { 0 } }
} --TODO:key wrapping not working it seems.
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

---@param depth number
function KeyMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth)
    return indent .. self.titleExport .. '"' .. (type(self.command) == "table" and rv.str:unbreak(concat(self.command, '+')) or rv.str:unbreak(self.command)) .. '"'
end

--TODO:Clean up this mess lol
---@param event Event
function KeyMacro:executeOld(event)
    local dir, vir, keyName, fam, num, triggerMode, toggled = event.direction, event.virtualType, event.keyName, event.family, event.keyNum, self.triggerMode, rv.profile.toggledKeys
    local press = self:keyPress(event)
    press.forceSleep = true
    local state = rv.profile.deviceState
    local keyString = self.command
    local releaseToggle = false
    local runner = running()
    if (runner and triggerMode == 0) or (vir and triggerMode == 0 and (vir == 1 or dir == nil)) then
        if type(keyString) == "string" and (state[fam]["_b" .. num] or
        not (rv.keys.keyboardDefinition[keyString] or rv.keyStates.logiKeys[keyString])) then rv.keys:typingDelegator(keyString, press)
        else
            if type(keyString) ~= "table" then keyString = { keyString } end
            rv.keys:pressAndReleaseSequence(keyString, press)
            releaseToggle = true
        end
    else
        if (dir == "down" and triggerMode == 0) or triggerMode == 1 or
        (triggerMode == 4 and (dir == "down" or vir)) or (triggerMode == 3 and toggled["_" .. keyName] == nil) then
            if triggerMode == 3 then toggled["_" .. keyName] = 1
            elseif triggerMode == 4 then
                local wrapperTargets = { key = state[fam]["_b" .. num], family = state[fam], global = rv.profile.globalState }
                local releaseWrapper = wrapperTargets[(self.options.scope) or "key"]
                if not releaseWrapper then
                    state[fam]["_b" .. num] = {}
                    releaseWrapper = state[fam]["_b" .. num]
                end
                if not releaseWrapper.wrapperContent then releaseWrapper.wrapperContent = {} end
                releaseWrapper.wrapperContent[#releaseWrapper.wrapperContent + 1] = keyString
            end
            if type(keyString) == "string" then rv.keys:press(rv.str:applyStringBuffer(keyString, press), press)
            elseif type(keyString) == "table" then rv.keys:pressSequence(keyString, press) end
        elseif
        (dir == "up" and triggerMode == 0) or triggerMode == 2 or (dir == "down" and triggerMode == 3 and toggled["_" .. keyName] ~= nil)
        then
            if triggerMode ~= 4 then releaseToggle = true end
            if type(keyString) == "string" then rv.keys:release(rv.str:applyStringBuffer(keyString, press), press)
            elseif type(keyString) == "table" then
                rv.keys:releaseSequence(keyString, press, self.options.unreverse)
            end
            if triggerMode == 3 then toggled["_" .. keyName] = nil end
        end
    end
    if releaseToggle then rv.keys:autoRelease(press) end
end

---@param event Event
function KeyMacro:execute(event)
    local press = self:keyPress(event)
    local virtual = event.virtualType
    press.forceSleep = true
    local releaseToggle = false
    if self.triggerMode == 0 then
        if event.direction == "down" or virtual ~= 3 then
            if self.naturalKey then
                if virtual ~= 3 then rv.keys:pressAndRelease(self.keys, press)
                else rv.keys:press(self.keys, press) end
            else rv.keys:typingDelegator(self.keys, press, self.pID) end
        elseif self.naturalKey then rv.keys:release(self.keys, press) end
    elseif self.triggerMode == 1 then rv.keys:press(self.keys, press)
    elseif self.triggerMode == 2 then rv.keys:release(self.keys, press)
    elseif self.triggerMode == 3 then
        local keyName = '_' .. event.keyName
        local toggled = rv.profile.toggledKeys
        if not toggled[keyName] then
            toggled[keyName] = 1
            rv.keys:press(self.keys, press)
        else
            rv.keys:release(self.keys, press)
            toggled[keyName] = nil
        end
    elseif self.triggerMode == 4 then
        local fam = event.family
        local num = event.keyNum
        local state = rv.profile.deviceState
        local wrapperTargets = { key = state[fam]["_b" .. num], family = state[fam], global = rv.profile.globalState }
        local releaseWrapper = wrapperTargets[(self.options.scope) or "key"]
        if not releaseWrapper then
            state[fam]["_b" .. num] = {}
            releaseWrapper = state[fam]["_b" .. num]
        end
        if not releaseWrapper.wrapperContent then releaseWrapper.wrapperContent = {} end
        releaseWrapper.wrapperContent[#releaseWrapper.wrapperContent + 1] = keyString
    end
    if releaseToggle then rv.keys:autoRelease(press) end
    if self.firstModifiers and not self.keys[1] then
        self.keys.modifier = self.firstModifiers
        self.keys.buffer = nil
    elseif self.firstModifiers then
        self.keys[1].modifier = self.firstModifiers
        self.keys[1].buffer = nil
    end
end

return KeyMacro