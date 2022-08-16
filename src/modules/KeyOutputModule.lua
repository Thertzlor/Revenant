local rv = ... ---@type Revenant
local ReleaseKey, PressKey, sub, gsub, type, PressMouseButton, ReleaseMouseButton, pairs, find, concat = ReleaseKey, PressKey, string.sub, string.gsub, type, PressMouseButton, ReleaseMouseButton, pairs, string.find, table.concat

--[[=============================================================]] --
---@class KeyObject Everything Revenant needs to know about a Key in order to press it.
---@field mb? integer numeric designation of a normal windows mouse button
---@field key string|integer Key ID as string or number
---@field modifier l<string> One or more modifier keys (alt/shift...) as strings.
---@field buffer KeyObject[] Buffered keys that should be pressed before the current one
---@field designation string Combined designation for key and modifiers. Used to release already held keys
--[[=============================================================]] --
---@class KeyOutputModule:BaseClass Output functions nabbed from ll.project (modified)
---@field keyboardDefinition table<string, l<KeyObject>>
local KeyOutputModule = rv.baseClass:new()

local modPattern = "^[" .. rv.utils.escapeString(concat(rv.tbl:getKeys(rv.stringPresets.modKeys), '')) .. "]+" ---an escaped pattern for all modifier prefixes

---adds currently pressed down keys to a table on an per-thread basis
---@param key string|KeyObject the key to add
local function _addDown(key)
    if rv.threading.activeTask == 0 then return end --nothing to add if no task is running
    rv.keyStates.roDown[rv.threading.activeTask][#rv.keyStates.roDown[rv.threading.activeTask] + 1] = key
end

---removes keys from the held down list, when a task ends
---@param key KeyObject the key to release
---@param skip? boolean if true key won't be released after all
local function _removeDown(key, skip)
    if skip or rv.threading.activeTask == 0 then return end --nothing to do when no task is running
    for i, va in pairs(rv.keyStates.roDown[rv.threading.activeTask]) do ---@cast va KeyObject
        if va.designation == key.designation then rv.keyStates.roDown[rv.threading.activeTask][i] = nil end
    end
end

---inserts modifier into strings.
---@param keyObj KeyObject the key object to be modified
---@param mod string the modifier to add
---@return KeyObject #the key object with modifiers added
local function _insertModifiers(keyObj, mod)
    keyObj.modifier = keyObj.modifier or {}
    if type(keyObj.modifier) == "string" then
        if keyObj.modifier == mod then return keyObj end --key already has this modifier
        keyObj.modifier = { keyObj.modifier } --converting into a list to hold multiple modifiers
    elseif rv.tbl:find(keyObj.modifier, mod) == true then return keyObj end --modifier already in list
    keyObj.modifier[#keyObj.modifier + 1] = mod --adding modifier to list
    return keyObj
end

---Press a SINGLE key object
---@param k KeyObject the key to press
---@param press KeyPress The key press settings defined by the macro
local function _pressKey(k, press)
    if rv.scriptStates.docMode then return end --not pressing anything in documentation mode
    if k.modifier then --pressing modifiers
        if type(k.modifier) == "table" then
            for i = 1, #k.modifier do
                PressKey(k.modifier[i])
                rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) --delay after modifiers
            end
        else
            PressKey(k.modifier--[[@as string]] )
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) --delay after modifiers
        end
    end
    if k.key then PressKey(k.key) --press either key or mouse button
    elseif k.mb then PressMouseButton(k.mb) end
end

---Release a SINGLE key object
---@param k KeyObject the key to release
---@param press KeyPress The key press settings defined by the macro
local function _releaseKey(k, press)
    if rv.scriptStates.docMode then return end --not releasing anything in documentation mode
    if k.key then ReleaseKey(k.key) --releasing key or mouse button
    elseif k.mb then ReleaseMouseButton(k.mb) end
    if k.modifier then --now releasing modifiers
        if type(k.modifier) == "table" then
            for i = 1, #k.modifier do
                rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) --delay after modifiers
                ReleaseKey(k.modifier[i])
            end
        else
            rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) --delay after modifiers
            ReleaseKey(k.modifier--[[@as string]] )
        end
    end
end

---Load a Keyboard file for a specified locale.
---@param locale string The locale to use
function KeyOutputModule:loadKeyboard(locale)
    self.keyboardDefinition = rv:import(rv.paths.configPath .. '/keyboard_' .. locale) --getting the keyboard file
    for k in pairs(self.keyboardDefinition) do self.keyboardDefinition[k].designation = k end
end

---Converts the logitech key name table into an more easily indexed format.
function KeyOutputModule:constructKeyTable()
    for i = 1, #rv.stringPresets.logitechKeyNames do --iterate over all logitech keys
        rv.keyStates.logiKeys[rv.stringPresets.logitechKeyNames[i]] = true
    end
end

---Wrapper parses a single key name
---@param keyString string string or name of a key
---@param noLogi? boolean if true do not try to parse the string as the name of a key
---@return KeyObject? #The found or constructed key object
function KeyOutputModule:parseKeyName(keyString, noLogi)
    if self.keyboardDefinition[keyString] then return rv.utils.deepCopy(self.keyboardDefinition[keyString]) end --deep copy, so modifiers don't carry over
    if (not noLogi) and rv.keyStates.logiKeys[keyString] then return { designation = keyString, key = keyString } end --output as logitech key
    local mods = rv.stringPresets.modKeys
    if not mods[sub(keyString, 1, 1)] then return nil end --if it's not a normal key, not a logitech key and does not begin with a modifier, we abort.
    local rawKey = self:parseKeyName(gsub(keyString, modPattern, ""), true) ---key name without modifier strings
    if not rawKey then return nil end -- if we can't parse the raw key we abort
    local newKey = rv.utils.deepCopy(rawKey) --deep copy, so modifiers don't carry over
    newKey.designation = keyString
    for i = 1, #keyString do
        local mod = mods[sub(keyString, i, i)] --start could be a modifier
        if not mod then break end
        if newKey.key or newKey.mb then newKey = _insertModifiers(newKey, mod) --converting modifier prefix into actual modifier on the object
        else for n = 1, #newKey do newKey[n] = _insertModifiers(newKey[n], mod) end end --handle each entry separately
    end
    return newKey
end

---parse a string consisting of one or more keystrokes into an array of key objects
---@param str string The string to parse
---@return KeyObject[] #The array of keys representing the string
function KeyOutputModule:keyParser(str)
    local arr = {} ---@type KeyObject[]
    local current ---@type string
    local len = #str --length of our string
    local pos = 1 ---current position in the string
    local mods = rv.stringPresets.modKeys
    while pos <= len do
        local modOffset = 0 ---positions skipped because of modifiers
        current = sub(str, pos, pos)
        while mods[sub(str, pos + modOffset, pos + modOffset)] do modOffset = modOffset + 1 end --finding modifiers
        if sub(str, pos + modOffset, pos + modOffset) == "/" then --Here we handle the special case of F-Key shorthands
            modOffset = modOffset + (find(sub(str, pos + modOffset + 1, pos + modOffset + 2), "[012]%d") and 2 or 1)
        end
        if modOffset ~= 0 then current = sub(str, pos, pos + modOffset) end --parsing the extracted key
        local kn = self:parseKeyName(current, true)
        if kn then arr[#arr + 1] = kn end ---adding our object ro the array
        pos = pos + 1 + modOffset --continuing to iterate
    end
    return arr
end

---Press one or more Keys
---@param key l<KeyObject> one or more key Objects
---@param press KeyPress The key press settings defined by the macro
function KeyOutputModule:press(key, press)
    if rv.scriptStates.docMode then return end --cancelling if in documentation mode
    press.delay = press.delay or 0
    if not key[1] then --checking if there's only a single key
        if key.buffer then --applying buffer
            self:press(key.buffer, press)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
        end
        _addDown(key) --adding to pressed list
        _pressKey(key, press) -- if there is no key, there are tables of keys.
    else for i = 1, #key do --processing an array of keys
            if key[i].buffer then --applying buffer
                self:press(key[i].buffer, press)
                if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
            end
            _addDown(key[i]) --adding to pressed list
            _pressKey(key[i], press)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
        end
    end
end

---Release one or more keys
---@param key l<KeyObject> one or more key Objects
---@param press KeyPress The key press settings defined by the macro
---@param skipRemove? boolean
function KeyOutputModule:release(key, press, unreverse, skipRemove)
    if rv.scriptStates.docMode then return end
    if not key[1] then --checking if there's only a single key
        _releaseKey(key, press)
        _removeDown(key, skipRemove) --removing from pressed list
        if key.buffer then --releasing buffer
            self:release(key.buffer, press)
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
        end
    else for i = 1, #key do local k = key[(unreverse and i or (#key + 1 - i))]
            _releaseKey(k, press) --removing from pressed list
            _removeDown(k, skipRemove)
            if k.buffer then
                self:release(k.buffer, press) --releasing buffer
                if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
            end
            if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
        end
    end
end

---Presses and releases keys in order.
---@param key l<KeyObject> one or more key Objects
---@param press KeyPress The key press settings defined by the macro
function KeyOutputModule:pressAndRelease(key, press)
    if rv.scriptStates.docMode then return end
    local delay = press.keyDelay
    if key[1] then -- if a multiple key press key is found, we must handle each key separately.
        local n = #key
        for i = 1, n do --iterating the list of keys
            _addDown(key[i])
            _pressKey(key[i], press)
            if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
            _releaseKey(key[i], press)
            _removeDown(key[i])
            if i < n then rv.threading:wait(delay, press.actionVariance, press.forceSleep) end --not waiting on last key
        end
    else
        self:press(key, press)
        if delay ~= 0 then rv.threading:wait(delay, press.keyVariance, press.forceSleep) end --only waiting if there's a delay
        self:release(key, press)
    end
end

---function for deciding how to type different strings and arrays
---@param keys l<KeyObject> one or more key Objects
---@param press KeyPress The key press settings defined by the macro
---@param id? string id of the origin macro
---@param noBuffer? boolean if true buffer strings are not applied
function KeyOutputModule:typingDelegator(keys, press, id, noBuffer)
    local keyArr = keys[1]
    ---one or more modifier keys originally found on the key
    local origMods ---@type l<string>
    if not noBuffer then --applying the buffer
        local foundMods = keyArr and keys[1].modifier or keys.modifier
        if foundMods then origMods = rv.tbl:intersectSimple(foundMods, {}) end --intersect acts as copy for shallow arrays
        keys = rv.keys:applyStringBuffer(keys, press)
    end
    if id and rv.scriptStates.docMode then return rv.lcd:displayOnLCD(id) end --in documentation mode we show the macro info
    if not keys[1] or self.keyboardDefinition[keys.designation] then self:pressAndRelease(keys, press) --pressing and releasing a single key
    else for i = 1, #keys do --iterating over key array
            self:pressAndRelease(keys[i], press)
            rv.threading:wait(press.actionDelay, press.actionVariance)
        end
    end
    if not noBuffer then
        self:unwrap(press) --unwrapping buffer
        if origMods then
            if keyArr then keys[1].modifier = origMods
            else keys.modifier = origMods end --resetting modifiers to original configuration
        end
        if keyArr then keys[1].buffer = nil
        else keys.buffer = nil end --removing buffers from the key
    end
end

---Releases all keys currently locked/held down, called at the end of the script or when aborting tasks.
---@param key string the mouse button that triggered the key presses
function KeyOutputModule:releaseAll(key)
    ---press with default delay settings
    local metaPress = { keyDelay = rv.profile.config.keyDelay, keyVariance = rv.profile.config.keyVariance } ---@type KeyPress
    for k in pairs(rv.keyStates.roDown[key]) do --checking if any held down keys are associated with the button
        local va = rv.keyStates.roDown[key][k]
        if va ~= nil then self:release(va, metaPress, false, true) end -- releasing all keys
    end
    rv.utils.wipe(rv.keyStates.roDown[key]) --emptying the key's table
end

---@param keys KeyObject or KeyDefinition[]
---@param press KeyPress The key press settings defined by the macro
---@return KeyObject #the key object with buffer applied
function KeyOutputModule:applyStringBuffer(keys, press)
    if not press.family then return keys end --no buffer for keys without family
    local fam, num = press.family, press.keyNum

    local bufferLocations = { ---all possible locations for different buffers
        rv.profile.deviceState[fam]["_b" .. num],
        rv.profile.deviceState[fam],
        rv.profile.globalState
    }

    local buffString = '' ---the string buffer to be appended
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj and obj.bufferContent then --getting the content from each buffer location
            buffString = concat { obj.bufferContent, buffString }
            obj.bufferContent = nil --erasing the buffer after applying
        end
    end

    local bn = #buffString ---length of the buffer
    if bn == 0 then return keys end --nothing to do if there's no buffer
    local buffKeys = keys
    if buffKeys.key or buffKeys.mb then buffKeys = { buffKeys } end --key needs to be an array

    local mods = rv.stringPresets.modKeys
    local modKeys = {}

    local isMod = mods[sub(buffString, bn, bn)] --resolving buffers with modification prefixes
    while isMod do
        modKeys[#modKeys + 1] = isMod
        bn = bn - 1 --modifications din't count towards length
        isMod = mods[sub(buffString, bn, bn)]
    end
    local mn = #modKeys
    for i = 1, mn do local md = modKeys[mn + 1 - i] --applying all modification prefixes
        _insertModifiers(buffKeys[1], md)
    end
    buffKeys[1].buffer = self:keyParser(sub(buffString, 1, bn)) --setting the actual buffer
    return buffKeys
end

---Automatically releases "wrapped" modifier keys.
---@param press KeyPress The key press settings defined by the macro
---@param unreverse? boolean if true does not reverse the order on keyup
function KeyOutputModule:unwrap(press, unreverse)
    local bufferLocations = { --possible buffer locations
        rv.profile.deviceState[press.family]["_b" .. press.keyNum],
        rv.profile.deviceState[press.family],
        rv.profile.globalState
    }
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj and obj.wrapperContent then --checking if there's any wrapped keys
            for n = 1, #obj.wrapperContent do
                if press.keyDelay ~= 0 then rv.threading:wait(press.keyDelay, press.keyVariance, press.forceSleep) end --waiting if there's a delay
                self:release(obj.wrapperContent[n], press, unreverse) --releasing buffers
            end
            obj.wrapperContent = {} --emptying the list
        end
    end
end

return KeyOutputModule
