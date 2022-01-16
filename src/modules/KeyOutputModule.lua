local rv = ...---@type Revenant
local ReleaseKey, PressKey, sub, gsub, type, PressMouseButton, ReleaseMouseButton, pairs, find, concat = ReleaseKey, PressKey, string.sub, string.gsub, type, PressMouseButton, ReleaseMouseButton, pairs, string.find, table.concat
--=============================================================
---@class KeyDefinition
---@field mb number
---@field key string|number
---@field modifier string|string[]
---@field buffer KeyDefinition[]
---@field designation string
--=============================================================
---@class KeyOutputModule:BaseClass Output functions nabbed from ll.project (modified)
---@field keyboardDefinition table<string, KeyDefinition|KeyDefinition[]>
local KeyOutputModule = rv.baseClass:new()

---@param locale string
function KeyOutputModule:loadKeyboard(locale)
    self.keyboardDefinition = rv:import(rv.paths.configPath .. '/keyboard_' .. locale)
    for k in pairs(self.keyboardDefinition) do self.keyboardDefinition[k].designation = k end
end

---adds currently pressed down keys to a table
---@param key string
local function _addDown(key)
    if rv.threading.activeTask == 0 then return end
    rv.keyStates.roDown[rv.threading.activeTask][#rv.keyStates.roDown[rv.threading.activeTask] + 1] = key
end

---removes keys from the held down list, when they are released again
---@param key KeyDefinition
---@param skip boolean
local function _removeDown(key, skip)
    if skip or rv.threading.activeTask == 0 then return end
    for i, va in pairs(rv.keyStates.roDown[rv.threading.activeTask]) do
        if va.designation == key.designation then rv.keyStates.roDown[rv.threading.activeTask][i] = nil end
    end
end

---inserts modifier into strings.
---@param keyObj KeyDefinition
---@param mod string
---@return KeyDefinition
local function _insertModifiers(keyObj, mod)
    keyObj.modifier = keyObj.modifier or {}
    if type(keyObj.modifier) == "string" then
        if keyObj.modifier == mod then return keyObj end
        keyObj.modifier = { keyObj.modifier }
    elseif rv.tbl:find(keyObj.modifier, mod) == nil then return keyObj end
    keyObj.modifier[#keyObj.modifier + 1] = mod
    return keyObj
end

---@param str string
function KeyOutputModule:keyParser(str)
    local arr = {} ---@type KeyDefinition[]
    local current ---@type string
    local len = #str
    local pos = 1
    local mods = rv.stringPresets.modKeys
    while pos <= len do
        local modOffset = 0
        current = sub(str, pos, pos)
        while mods[sub(str, pos + modOffset, pos + modOffset)] do modOffset = modOffset + 1 end
        if sub(str, pos + modOffset, pos + modOffset) == "/" then
            modOffset = modOffset + (find(sub(str, pos + modOffset + 1, pos + modOffset + 2), "[012]%d") and 2 or 1)
        end
        if modOffset ~= 0 then current = sub(str, pos, pos + modOffset) end
        local kn = self:parseKeyName(current, true)
        if kn then arr[#arr + 1] = kn end
        pos = pos + 1 + modOffset
    end
    return arr
end

---Releases all keys currently locked/held down, called at the end of the script or when aborting tasks.
---@param key string
function KeyOutputModule:releaseAll(key)
    local metaPress = { keyDelay = rv.profile.config.keyDelay, keyVariance = rv.profile.config.keyVariance }---@type KeyPress
    for k in pairs(rv.keyStates.roDown[key]) do
        local va = rv.keyStates.roDown[key][k] ---@type string
        if va ~= nil then self:release(va, metaPress, true) end
    end
    rv.utils.wipe(rv.keyStates.roDown[key])
end

---press an array of keys, then release it.
---@param seq KeyDefinition[]
---@param press KeyPress
function KeyOutputModule:pressAndReleaseSequence(seq, press)
    self:pressSequence(seq, press)
    self:releaseSequence(seq, press)
end

---pressing down an array of buttons in order
---@param seq KeyDefinition[]
---@param press KeyPress
function KeyOutputModule:pressSequence(seq, press)
    for i = 1, #seq do local obj = seq[i]
        self:press(obj, press)
        rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
    end
end

---Releasing an array of buttons in order
---@param seq KeyDefinition[]
---@param press KeyPress
function KeyOutputModule:releaseSequence(seq, press, unreverse)
    for i = 1, #seq do local obj = unreverse and seq[i] or seq[#seq + 1 - i]
        self:release(obj, press)
        rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
    end
end

---function for deciding how to type different strings and arrays
---@param keys KeyDefinition[]|KeyDefinition
---@param press KeyPress
---@param id string
function KeyOutputModule:typingDelegator(keys, press, id, noBuffer)
    local keyArr = keys[1]
    local origMods
    if not noBuffer then
        local foundMods = keyArr and keys[1].modifier or keys.modifier
        if foundMods then origMods = rv.tbl:intersectSimple(foundMods, {}) end
        keys = rv.keys:applyStringBuffer(keys, press)
    end
    if id and rv.scriptStates.docMode then return rv.lcd:displayOnLCD(id) end
    if not keys[1] or self.keyboardDefinition[keys.designation] then self:pressAndRelease(keys, press)
    else for i = 1, #keys do
            self:pressAndRelease(keys[i], press)
            rv.threading:wait(press.actionDelay, press.actionVariance)
        end end
    self:autoRelease(press)
    if not noBuffer then
        if origMods then
            if keyArr then keys[1].modifier = origMods
            else keys.modifier = origMods end
        end
        if keyArr then keys[1].buffer = nil
        else keys.buffer = nil end
    end
end

---Wrapper parses a single key name
---@param keyString string
---@return KeyDefinition
function KeyOutputModule:parseKeyName(keyString, noLogi)
    if self.keyboardDefinition[keyString] then return rv.utils.deepCopy(self.keyboardDefinition[keyString]) end
    if (not noLogi) and rv.keyStates.logiKeys[keyString] then return { designation = keyString, key = keyString } end
    local mods = rv.stringPresets.modKeys
    if not mods[sub(keyString, 1, 1)] then return nil end
    local rawKey = self:parseKeyName(gsub(keyString, "^[%#~%*|]+", ""), true)
    if not rawKey then return nil end
    local newKey = rv.utils.deepCopy(rawKey)
    newKey.designation = keyString
    for i = 1, #keyString do
        local mod = mods[sub(keyString, i, i)]
        if not mod then break end
        if newKey.key or newKey.mb then newKey = _insertModifiers(newKey, mod)
        else for n = 1, #newKey do newKey[n] = _insertModifiers(newKey[n], mod) end end
    end
    return newKey
end

---Press a SINGLE key
---@param k KeyDefinition
---@param press KeyPress
local function _pressKey(k, press)
    if rv.scriptStates.docMode then return end
    if k.modifier then
        if type(k.modifier) == "table" then for i = 1, #k.modifier do PressKey(k.modifier[i]) end
        else PressKey(k.modifier) end
        rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
    end
    if k.key then PressKey(k.key)
    else PressMouseButton(k.mb) end
end

---Release a SINGLE key
---@param k KeyDefinition
---@param press KeyPress
local function _releaseKey(k, press)
    if rv.scriptStates.docMode then return end
    if k.key then ReleaseKey(k.key)
    else ReleaseMouseButton(k.mb) end
    if k.modifier then
        if type(k.modifier) == "table" then
            for i = 1, #k.modifier do
                rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
                ReleaseKey(k.modifier[i])
            end
        else
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
            ReleaseKey(k.modifier)
        end
    end
end

---Press one or more Keys
---@param key KeyDefinition|KeyDefinition[]
---@param press KeyPress
function KeyOutputModule:press(key, press)
    if rv.scriptStates.docMode then return end
    press.delay = press.delay or 0
    if not key[1] then
        _addDown(key)
        _pressKey(key, press) -- if there is no key, there are tables of keys.
    else for i = 1, #key do
            _addDown(key[i])
            _pressKey(key[i], press)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
        end
    end
end

---Converts the logitech key name table into an more easily indexed format.
function KeyOutputModule:constructKeyTable()
    for i = 1, #rv.stringPresets.logitechKeyNames do
        rv.keyStates.logiKeys[rv.stringPresets.logitechKeyNames[i]] = true
    end
end

---Automatically releases "wrapped" modifier keys.
---@param press KeyPress
function KeyOutputModule:autoRelease(press)
    local bufferLocations = {
        rv.profile.deviceState[press.family]["_b" .. press.keyNum],
        rv.profile.deviceState[press.family],
        rv.profile.deviceState
    }
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj and obj.wrapperContent then
            --TODO:Not neccesarily a sequence...
            self:releaseSequence(obj.wrapperContent, press)
            obj.wrapperContent = {}
        end
    end
end

---Release one or more keys
---@param key KeyDefinition|KeyDefinition[]
---@param press KeyPress
---@param sil boolean
function KeyOutputModule:release(key, press, sil)
    if rv.scriptStates.docMode then return end
    if not key[1] then
        _removeDown(key, sil)
        _releaseKey(key, press)
    else for i = 1, #key do
            _releaseKey(key[i], press)
            _removeDown(key[i], sil)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
        end
    end
end

---Presses and releases keys in order.
---@param key KeyDefinition|KeyMacroDefinition[]
---@param press KeyPress
function KeyOutputModule:pressAndRelease(key, press)
    if rv.scriptStates.docMode then return end
    local delay = press.keyDelay
    if key[1] then -- if a multiple key press key is found, we must handle key key separately.
        local n = #key
        for i = 1, n do
            _addDown(key[i])
            _pressKey(key[i], press)
            if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end
            _releaseKey(key[i], press)
            _removeDown(key[i])
            if i < n then rv.threading:wait(delay, press.actionVariance, press.forceSleep) end
        end
    else
        self:press(key, press)
        if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end
        self:release(key, press)
    end
end

---@param keys KeyDefinition or KeyDefinition[]
---@param press KeyPress
function KeyOutputModule:applyStringBuffer(keys, press)
    if not press.family then return keys end
    local fam, num = press.family, press.keyNum

    local bufferLocations = {
        rv.profile.deviceState[fam]["_b" .. num],
        rv.profile.deviceState[fam],
        rv.profile.globalState
    }

    local buffString = ''
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj and obj.bufferContent then
            buffString = concat { obj.bufferContent, buffString }
            obj.bufferContent = nil
        end
    end

    local bn = #buffString
    if bn == 0 then return keys end
    local buffKeys = keys
    if buffKeys.key or buffKeys.mb then buffKeys = { buffKeys } end

    local mods = rv.stringPresets.modKeys
    local modKeys = {}

    local isMod = mods[sub(buffString, bn, bn)]
    while isMod do
        modKeys[#modKeys + 1] = isMod
        bn = bn - 1
        isMod = mods[sub(buffString, bn, bn)]
    end

    local mn = #modKeys
    for i = 1, mn do local md = modKeys[mn + 1 - i]
        _insertModifiers(buffKeys[1], md)
    end
    buffKeys[1].buffer = self:keyParser(sub(buffString, 1, bn - mn))
    return buffKeys
end

return KeyOutputModule