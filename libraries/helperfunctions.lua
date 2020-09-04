---@type MainLibObject
local tl, Base = ...
local gmatch, setmetatable, type, pairs = string.gmatch, setmetatable, type, pairs
--Library Functions from around the net... =======================================================================================
---@class UtilityModule
local UtilityModule = Base:new()
---Reverse an ordered table
---@param arr table
function UtilityModule.reverseTable(arr)
    local i, j = 1, #arr
    while i < j do
        arr[i], arr[j] = arr[j], arr[i]
        i = i + 1
        j = j - 1
    end
end
---Generate a Table with a generic return table for out-of-bounds indices.
---@return table
function UtilityModule.newIndexTable()
    return setmetatable(
        {},
        {
            __index = function()
                return {_dummy = true, _meta = {conditions = {}}}
            end
        }
    )
end

---Wipe a table completely
---@param tab table
function UtilityModule.wipe(tab)
    for k in pairs(tab) do
        tab[k] = nil
    end
end

---Splits a string with a separator
---@param str string
---@param sep string
function UtilityModule.splitter(str, sep)
    local ret = {}
    local n = 1
    for w in gmatch(str, "([^" .. sep .. "]*)") do
        ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
        if w == "" then
            n = n + 1
        end -- step forwards on a blank but not a string
    end
    return ret
end

---Make a deep copy of a table
---@param orig table | GenericMacro
---@param copies table
function UtilityModule.deepCopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[tl.helperUtils.deepCopy(orig_key, copies)] = tl.helperUtils.deepCopy(orig_value, copies)
            end
            copies[orig] = copy
            setmetatable(copy, tl.helperUtils.deepCopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    if type(copy) == "table" then
        tl.tbl:indexTables(nil, copy, nil, nil)
    end
    return copy
end

function UtilityModule.dummy()
end

return UtilityModule
