local rv = ...---@type Revenant
local ReleaseKey, PressKey, sub, gsub, type, PressMouseButton, ReleaseMouseButton, pairs, find, concat = ReleaseKey, PressKey, string.sub, string.gsub, type, PressMouseButton, ReleaseMouseButton, pairs, string.find, table.concat
--=============================================================
---@class KeyDefinition
---@field mb number
---@field key string|number
---@field modifier string|string[]
---@field buffer KeyDefinition[]
--=============================================================
---@class KeyOutputModule:BaseClass Output functions nabbed from ll.project (modified)
---@field keyboardDefinition table<string, KeyDefinition|KeyDefinition[]>
local KeyOutputModule = rv.baseClass:new()

---@param locale string
function KeyOutputModule:loadKeyboard(locale)
    self.keyboardDefinition = rv:import(rv.paths.configPath .. '/keyboard_' .. locale)
end

---adds currently pressed down keys to a table
---@param key string
local function _addDown(key)
    if rv.threading.activeTask == 0 then return end
    rv.keyStates.roDown[rv.threading.activeTask][#rv.keyStates.roDown[rv.threading.activeTask] + 1] = key
end

---removes keys from the held down list, when they are released again
---@param key string
---@param sil boolean
local function _clearPushed(key, sil)
    if sil or rv.threading.activeTask == 0 then return end
    for i, va in pairs(rv.keyStates.roDown[rv.threading.activeTask]) do
        if va == key then rv.keyStates.roDown[rv.threading.activeTask][i] = nil end
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

---Main function for typing strings of keys.
---@private
---@param str string
---@param press KeyPress
function KeyOutputModule:_typeString(str, press)
    local pos, len, offset ---@type number
    local current ---@type string
    len = #str
    pos = 1
    while pos <= len do
        offset = 1
        current = sub(str, pos, pos)
        while find(sub(current, offset, offset), "[/%#~%*|]") do
            if pos < len then
                local add = 2
                if sub(current, offset, offset) == "/" then
                    if find(sub(str, pos + 1, pos + 2), "[012]%d") then
                        current = concat { current, sub(str, pos + 1, pos + 2) }
                    else
                        current = concat { current, sub(str, pos + 1, pos + 1) }
                        add = 1
                    end
                    pos = pos + add
                    offset = offset + 2
                else
                    current = concat { current, sub(str, pos + 1, pos + 1) }
                    pos = pos + 1
                    offset = offset + 1
                end
            else error("found a single escape sequence at end of string.  For a single /, put two in a row. i.e. //") end
        end
        self:pressAndRelease(current, press)
        if pos < len then rv.threading:wait(press.actionDelay, press.actionVariance, press.forceSleep) end
        pos = pos + 1
    end
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
        local kn = self:parseKeyName(current)
        if kn then arr[#arr + 1] = kn end
        pos = pos + 1 + modOffset
    end
    return arr
end

---Releases all keys currently locked/held down, called at the end of the script.
---@param key string
function KeyOutputModule:releaseAll(key)
    local metaPress = { keyDelay = rv.profile.config.keyDelay, keyVariance = rv.profile.config.keyVariance }---@type KeyPress
    for k in pairs(rv.keyStates.roDown[key]) do
        local va = rv.keyStates.roDown[key][k] ---@type string
        if va ~= nil then
            rv:put("auto-released " .. va)
            self:release(va, metaPress, true)
        end
    end
    rv.utils.wipe(rv.keyStates.roDown[key])
end

---press an array of keys, then release it.
---@param seq string[]
---@param press KeyPress
function KeyOutputModule:pressAndReleaseSequence(seq, press)
    self:pressSequence(seq, press)
    self:releaseSequence(seq, press)
end

---pressing down an array of buttons in order
---@param seq string[]
---@param press KeyPress
function KeyOutputModule:pressSequence(seq, press)
    for i = 1, #seq do local obj = seq[i]
        if type(obj) == "string" then
            self:press(obj, press)
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
        end
    end
end

---Releasing an array of buttons in order
---@param seq string[]
---@param press KeyPress
function KeyOutputModule:releaseSequence(seq, press, unreverse)
    for i = 1, #seq do local obj = unreverse and seq[i] or seq[#seq + 1 - i]
        if type(obj) == "string" then
            self:release(obj, press)
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep)
        end
    end
end

---function for deciding how to type different strings and arrays
---@param tstring string
---@param press KeyPress
---@param id string
function KeyOutputModule:typingDelegator(tstring, press, id)
    tstring = rv.str:applyStringBuffer(tstring, press)
    if id and rv.scriptStates.docMode then return rv.lcd:displayOnLCD(id) end
    if (#tstring == 1 or (sub(tstring, 1, 1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring, 2, 3)) < 25)))) then
        self:pressAndRelease(tstring, press)
    else
        self:_typeString(tstring, press)
    end
    self:autoRelease(press)
end

---Wrapper parses a single key name
---@param keyString string
---@return KeyDefinition
function KeyOutputModule:parseKeyName(keyString)
    if self.keyboardDefinition[keyString] then return rv.utils.deepCopy(self.keyboardDefinition[keyString]) end
    if rv.keyStates.logiKeys[keyString] then return { key = keyString } end
    local mods = rv.stringPresets.modKeys
    if not mods[sub(keyString, 1, 1)] then return nil end
    local rawKey = self:parseKeyName(gsub(keyString, "^[%#~%*|]+", ""))
    if not rawKey then return nil end
    local newKey = rv.utils.deepCopy(rawKey)
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
---@param key string|KeyDefinition
---@param press KeyPress
---@param id string
function KeyOutputModule:press(key, press, id)
    if rv.scriptStates.docMode then return end
    _addDown(key)
    local k = self:parseKeyName(key)
    press.delay = press.delay or 0
    if k then
        if k.key or k.mb then _pressKey(k, press)
        elseif k[1] then -- if there is no key, there are tables of keys.
            for i = 1, #k do _pressKey(k[i], press) end
        elseif k.mb then PressMouseButton(k.mb) end
    elseif key ~= "" then
        if rv.keyStates.logiKeys[key] then
            PressKey(key)
            return true
        elseif (#key ~= 2 or sub(key, 1, 1) ~= "/") then
            _clearPushed(key)
            self:typingDelegator(key, press, id)
            return
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
            self:releaseSequence(obj.wrapperContent, press)
            obj.wrapperContent = {}
        end
    end
end

---Release one or more keys
---@param key string
---@param press KeyPress
---@param sil boolean
function KeyOutputModule:release(key, press, sil)
    if rv.scriptStates.docMode then return end
    local k = self:parseKeyName(key)
    if k then
        if k.key or k.mb then _releaseKey(k, press)
        elseif k[1] then
            for i = 1, #k do _releaseKey(k[i], press) end
        elseif k.mb then ReleaseMouseButton(k.mb) end
    elseif key ~= "" and rv.keyStates.logiKeys[key] then ReleaseKey(key) end
    _clearPushed(key, sil)
end

---Presses and releases keys in order.
---@param key string
---@param press KeyPress
function KeyOutputModule:pressAndRelease(key, press)
    if rv.scriptStates.docMode then return end
    local k = self:parseKeyName(key)
    local delay = press.keyDelay
    if k and k[1] then -- if a multiple key press key is found, we must handle key key separately.
        _addDown(key)
        local n = #k
        for i = 1, n do
            _pressKey(k[i], press)
            if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end
            _releaseKey(k[i], press)
            if i < n then rv.threading:wait(delay, press.actionVariance, press.forceSleep) end
        end
        _clearPushed(key)
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
            buffString = obj.bufferContent .. buffString
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