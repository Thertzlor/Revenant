local tl = ...---@type MainLibObject
local ReleaseKey, PressKey, sub, find, gsub, type, insert, maxn, PressMouseButton, ReleaseMouseButton, pairs = ReleaseKey, PressKey, string.sub, string.find, string.gsub, type, table.insert, table.maxn, PressMouseButton, ReleaseMouseButton, pairs
--================================================================
local KeyOutputModule = tl.baseClass:new()---@class KeyOutputModule:BaseClass Output functions nabbed from ll.project (modified)

---adds currently pressed down keys to a table
---@param key string
local function _addDown(key)
    if tl.polling.pollControls.cutine == 0 then return end
    tl.keyStates.roDown[tl.polling.pollControls.cutine][#tl.keyStates.roDown[tl.polling.pollControls.cutine] + 1] = key
end

---removes keys from the held down list, when they are released again
---@param key string
---@param optional sil boolean
local function _clearPushed(key, sil)
    if sil or tl.polling.pollControls.cutine == 0 then return end
    for i, va in pairs(tl.keyStates.roDown[tl.polling.pollControls.cutine]) do
        if va == key then tl.keyStates.roDown[tl.polling.pollControls.cutine][i] = nil end
    end
end

---inserts modifier into strings.
---@param keyObj string|table
---@param index number
---@param mod string
local function _insertModifiers(keyObj, index, mod)
    keyObj.modifier = keyObj.modifier or {}
    if type(keyObj.modifier) == "string" then
        if keyObj.modifier == mod then return keyObj end
        keyObj.modifier = { keyObj.modifier }
    elseif tl.tbl:find(keyObj.modifier, mod) == nil then return keyObj end
    insert(keyObj.modifier, index, mod)
    return keyObj
end

---Wrapper function for identifying key names
---@private
---@param keyString string
---@return string
function KeyOutputModule:_parseKeyName(keyString)
    if self.keyboardDefinition[keyString] then return self.keyboardDefinition[keyString] end
    if find(keyString, "^[%#~%*|]") == nil then return nil end
    local newKey
    local rawKey = self:_parseKeyName(gsub(keyString, "^[%#~%*|]+", ""))
    if rawKey ~= nil then
        newKey = tl.helperUtils.deepCopy(rawKey)
        for i = 1, #keyString do
            local part = sub(keyString, i, i)
            local mod
            if part == "*" then mod = "lctrl"
            elseif part == "#" then mod = "lalt"
            elseif part == "~" then mod = "lshift"
            elseif part == "|" then mod = "lgui"
            else break end
            if newKey.key then newKey = _insertModifiers(newKey, i, mod)
            else for n = 1, #newKey do newKey[n] = _insertModifiers(newKey[n], i, mod) end end
        end
    end
    return newKey
end

---Delegates Logitech key presses.
---@param k string
---@param press KeyPress
local function _pressKey(k, press)
    if tl.scriptStates.docMode and tl.profile.config.docModeButtonLock then return end
    if k.modifier then
        if type(k.modifier) == "table" then for i = 1, #k.modifier do PressKey(k.modifier[i]) end
        else PressKey(k.modifier) end
        tl.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep)
    end
    PressKey(k.key)
end

---Delegates Logitech key releases.
---@param k string
---@param press KeyPress
local function _releaseKey(k, press)
    if tl.scriptStates.docMode and tl.profile.config.docModeButtonLock then return end
    ReleaseKey(k.key)
    if k.modifier then
        if type(k.modifier) == "table" then
            for i = 1, #k.modifier do
                tl.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep)
                ReleaseKey(k.modifier[i])
            end
        else
            tl.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep)
            ReleaseKey(k.modifier)
        end
    end
end

---Press one or more Keys
---@param key string
---@param press KeyPress
function KeyOutputModule:press(key, press)
    local config = tl.profile.config
    if tl.scriptStates.docMode and tl.profile.config.docModeButtonLock then return end
    _addDown(key)
    local k = self:_parseKeyName(key)
    press.delay = press.delay or 0
    if k then
        if k.key then _pressKey(k, press)
        elseif k[1] then -- if there is no key, there are tables of keys.
            local n
            n = maxn(k)
            for i = 1, n do _pressKey(k[i], press) end
        elseif k.mb then PressMouseButton(k.mb) end
    elseif key ~= "" then
        if tl.keyStates.logiKeys[key] then
            PressKey(key)
            return true
        elseif (#key ~= 2 or sub(key, 1, 1) ~= "/") then
            _clearPushed(key)
            tl.str:typingDelegator(key, press)
            return
        end
    end
end

---Converts the logitech key name table into an more easily indexed format.
function KeyOutputModule:constructKeyTable()
    for i = 1, #tl.stringPresets.logitechKeyNames do
        tl.keyStates.logiKeys[tl.stringPresets.logitechKeyNames[i]] = true
    end
end

---Automatically releases "wrapped" modifier keys.
---@param press KeyPress
function KeyOutputModule:autoRelease(press)
    local bufferLocations = {
        tl.profile.deviceState[press.family]["_b" .. press.keyNum],
        tl.profile.deviceState[press.family],
        tl.profile.deviceState
    }
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj and obj.wrapperContent then
            tl.str:releaseSequence(obj.wrapperContent, press)
            obj.wrapperContent = {}
        end
    end
end

---Release one or more keys
---@param key string
---@param press KeyPress
function KeyOutputModule:release(key, press, sil)
    if tl.scriptStates.docMode and tl.profile.config.docModeButtonLock then return end
    local k = self:_parseKeyName(key)
    if k then
        if k.key then _releaseKey(k, press)
        elseif k[1] then local n = maxn(k)
            for i = 1, n do _releaseKey(k[i], press) end
        elseif k.mb then ReleaseMouseButton(k.mb) end
    elseif key ~= "" and tl.keyStates.logiKeys[key] then ReleaseKey(key) end
    _clearPushed(key, sil)
end

---Presses and releases keys in order.
---@param key string
---@param press KeyPress
function KeyOutputModule:pressAndRelease(key, press)
    if tl.scriptStates.docMode and tl.profile.config.docModeButtonLock then return end
    local k = self:_parseKeyName(key)
    local delay = press.keyDelay
    if k and k[1] then -- a multiple key press key is found, we must handle key key separate.
        _addDown(key)
        local n = maxn(k)
        for i = 1, n do
            _pressKey(k[i], press)
            if delay ~= 0 then tl.coroutines:wait(delay, press.keyVariance, press.forceSleep) end
            _releaseKey(k[i], press)
            if i < n then tl.coroutines:wait(delay, press.actionVariance, press.forceSleep) end
        end
        _clearPushed(key)
    else
        self:press(key, press)
        if delay ~= 0 then tl.coroutines:wait(delay, press.keyVariance, press.forceSleep) end
        self:release(key, press)
    end
end

return KeyOutputModule