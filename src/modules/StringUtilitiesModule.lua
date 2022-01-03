local rv = ...---@type MainLibObject
local lower, match, sub, type, concat, find, ceil, tonumber, error, pairs, gsub = rv.utf8.lower, rv.utf8.match, rv.utf8.sub, type, table.concat, rv.utf8.find, math.ceil, tonumber, error, pairs, string.gsub

--=============================================================
local StringUtilitiesModule = rv.baseClass:new()---@class StringUtilitiesModule:BaseClass Functions that process or type strings 

---Main function for typing strings of keys.
---@param s string
---@param press KeyPress
local function _typeString(s, press)
    local i, n, a ---@type number
    local c ---@type string
    n = #s
    i = 1
    while i <= n do
        a = 1
        c = sub(s, i, i)
        while find(sub(c, a, a), "[/%#~%*|]") do
            if i < n then
                local add = 2
                if sub(c, a, a) == "/" then
                    if find(sub(s, i + 1, i + 2), "[012]%d") then
                        c = c .. sub(s, i + 1, i + 2)
                    else
                        c = c .. sub(s, i + 1, i + 1)
                        add = 1
                    end
                    i = i + add
                    a = a + 2
                else
                    c = c .. sub(s, i + 1, i + 1)
                    i = i + 1
                    a = a + 1
                end
            else error("found a single escape sequence at end of string.  For a single /, put two in a row. i.e. //") end
        end
        rv.keys:pressAndRelease(c, press)
        if i < n then rv.coroutines:wait(press.actionDelay, press.actionVariance, press.forceSleep) end
        i = i + 1
    end
end

---@param str string
---@return string
function StringUtilitiesModule:unbreak(str) return gsub(str, '\n', '\\n') end

---@param str string
---@return string[]
function StringUtilitiesModule:separate(str)
    local singles = {}
    for i = 1, #str do singles[#singles + 1] = sub(str, i, i) end
    return singles
end

---Releases all keys currently locked/held down, called at the end of the script.
---@param key string
function StringUtilitiesModule:releaseAll(key)
    local metaPress = { keyDelay = rv.profile.config.keyDelay, keyVariance = rv.profile.config.keyVariance }---@type KeyPress
    for k in pairs(rv.keyStates.roDown[key]) do
        local va = rv.keyStates.roDown[key][k] ---@type string
        if va ~= nil then
            rv.logitech:putNoLCD("auto-released " .. va)
            rv.keys:release(va, metaPress, true)
        end
    end
    rv.helperUtils.wipe(rv.keyStates.roDown[key])
end

---press an array of keys, then release it.
---@param seq string[]
---@param press KeyPress
---@param del number
function StringUtilitiesModule:pressAndReleaseSequence(seq, press, del)
    self:pressSequence(seq, press)
    if del then rv.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep) end
    self:releaseSequence(seq, press)
end

---pressing down an array of buttons in order
---@param seq string[]
---@param press KeyPress
function StringUtilitiesModule:pressSequence(seq, press)
    for i = 1, #seq do local obj = seq[i]
        if type(obj) == "string" then
            rv.keys:press(obj, press)
            rv.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep)
        end
    end
end

---@param str string
function StringUtilitiesModule:valid(str)
    return type(str) == "string" and #str ~= 0
end

---Releasing an array of buttons in order
---@param seq string[]
---@param press KeyPress
function StringUtilitiesModule:releaseSequence(seq, press)
    rv.helperUtils.reverseTable(seq)
    for i = 1, #seq do local obj = seq[i]
        if type(obj) == "string" then
            rv.keys:release(obj, press)
            rv.coroutines:wait(press.keyDelay, press.keyVariance, press.forceSleep)
        end
    end
    rv.helperUtils.reverseTable(seq)
end

---Outputs the first character of a string in lowercase.
---@param f string
---@return string
function StringUtilitiesModule:token(f)
    if type(f) ~= "string" then return false end
    return lower(sub(f, 1, 1))
end

---function for deciding how to type different strings and arrays
---@param tstring string
---@param press KeyPress
---@param id string
function StringUtilitiesModule:typingDelegator(tstring, press, id)
    tstring = rv.str:applyStringBuffer(tstring, press, 1)
    if id and rv.scriptStates.docMode then return rv.lcd:displayOnLCD(id) end
    if (#tstring == 1 or (sub(tstring, 1, 1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring, 2, 3)) < 25)))) then
        rv.keys:pressAndRelease(tstring, press)
    else
        _typeString(tstring, press)
    end
    rv.keys:autoRelease(press)
end

---@param string string
---@param press KeyPress
---@param clear boolean
function StringUtilitiesModule:applyStringBuffer(string, press, clear)
    if not press.family then return string end
    local fam, num = press.family, press.keyNum
    local bufferLocations = {
        rv.profile.deviceState[fam]["_b" .. num],
        rv.profile.deviceState[fam],
        rv.profile.deviceState
    }
    local buffString = string
    for i = 1, #bufferLocations do local obj = bufferLocations[i]
        if obj then
            if obj.bufferContent then buffString = obj.bufferContent .. buffString end
            if clear then obj.bufferContent = nil end
        end
    end
    return buffString
end

---@param string string
---@param fam string
---@param num number
---@param mode number
function StringUtilitiesModule:addStringBuffer(string, fam, num, mode, scope)
    local bufferTarget
    local state = rv.profile.deviceState
    if scope == "family" then bufferTarget = state[fam]
    elseif scope == "global" then bufferTarget = state
    else
        if (not state[fam]["_b" .. num]) then state[fam]["_b" .. num] = {} end
        bufferTarget = state[fam]["_b" .. num]
    end
    bufferTarget.bufferContent = ((mode ~= nil and bufferTarget.bufferContent ~= nil) and bufferTarget.bufferContent .. string) or string
end

---@param str string
function StringUtilitiesModule:firstLower(str)
    return lower(sub(str, 1, 1)) .. sub(str, 2, #str)
end

return StringUtilitiesModule