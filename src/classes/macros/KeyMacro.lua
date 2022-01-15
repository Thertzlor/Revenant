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
---@field naturalKey boolean Is the key a single normal key?
---@field options _KeyOptions
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
KeyMacro.lintCommand = { type = { "string", "table" }, tableKeys = "number", tableVals = "string" }

function KeyMacro:parseInstructions()
    local raw = self.rawCommand
    local triggerModes = { keydown = 1, keyup = 2, keytoggle = 3, wrapkey = 4 }
    self.triggerMode = triggerModes[self.type] or 0
    self.singleTrigger = self.triggerMode ~= 0
    if self.type == "keytoggle" then self.singleTrigger = true end
    if type(raw) == "table" and #raw == 1 then self.command = raw[1] end
    self.naturalKey = type(self.command) == "table" or rv.stringPresets.logitechKeyNames[self.command]
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
function KeyMacro:execute(event)
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
            if type(keyString) == "string" then rv.keys:press(rv.str:applyStringBuffer(keyString, press, 1), press)
            elseif type(keyString) == "table" then rv.keys:pressSequence(keyString, press) end
        elseif
        (dir == "up" and triggerMode == 0) or triggerMode == 2 or (dir == "down" and triggerMode == 3 and toggled["_" .. keyName] ~= nil)
        then
            if triggerMode ~= 4 then releaseToggle = true end
            if type(keyString) == "string" then rv.keys:release(rv.str:applyStringBuffer(keyString, press, 1), press)
            elseif type(keyString) == "table" then
                rv.keys:releaseSequence(keyString, press, self.options.unreverse)
            end
            if triggerMode == 3 then toggled["_" .. keyName] = nil end
        end
    end
    if releaseToggle then rv.keys:autoRelease(press) end
end

function KeyMacro:nextGenExecute(event)
    local press = self:keyPress(event)
    press.forceSleep = true
    local state = rv.profile.deviceState
    local keyString = self.command
    local releaseToggle = false
    if self.triggerMode == 0 then
        if type(keyString) == "string" then rv.keys:press(rv.str:applyStringBuffer(keyString, press, 1), press)
        elseif type(keyString) == "table" then rv.keys:pressSequence(keyString, press) end
    elseif self.triggerMode == 1 then
    elseif self.triggerMode == 2 then
    elseif self.triggerMode == 3 then
    elseif self.triggerMode == 4 then
    end
    if releaseToggle then rv.keys:autoRelease(press) end
end

return KeyMacro