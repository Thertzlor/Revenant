local rv = ... ---@type Revenant
local lower, sub, type, gsub = rv.utf8.lower, rv.utf8.sub, type, string.gsub

--=============================================================
local StringUtilitiesModule = rv.baseClass:new() ---@class StringUtilitiesModule:BaseClass Functions that process or type strings

---@param str string
function StringUtilitiesModule:valid(str)
    return type(str) == "string" and #str ~= 0
end

---Outputs the first character of a string in lowercase.
---@param f string
---@return string
function StringUtilitiesModule:token(f)
    if type(f) ~= "string" then return '' end
    return lower(sub(f, 1, 1))
end

---@param string string
---@param fam string
---@param num number
---@param mode number|string
---@param scope '"family"'| '"global"'
function StringUtilitiesModule:addStringBuffer(string, fam, num, mode, scope)
    local bufferTarget
    local state = rv.profile.deviceState
    if scope == "family" then bufferTarget = state[fam]
    elseif scope == "global" then bufferTarget = rv.profile.globalState
    else
        if (not state[fam]["_b" .. num]) then state[fam]["_b" .. num] = {} end
        bufferTarget = state[fam]["_b" .. num]
    end
    bufferTarget.bufferContent = ((mode ~= nil and bufferTarget.bufferContent ~= nil) and bufferTarget.bufferContent .. string) or string
end

---@param str string
---@param rep? string
function StringUtilitiesModule:unbreak(str, rep) return gsub(str, '\n', rep or '\\n') end

---@param str string
function StringUtilitiesModule:firstLower(str)
    return lower(sub(str, 1, 1)) .. sub(str, 2, #str)
end

return StringUtilitiesModule
