---@type Revenant
local rv = ...
local gmatch, setmetatable, type, pairs, getmetatable, sort, tostring, gsub, cached_G, loadfile = string.gmatch, setmetatable, type, pairs, getmetatable, table.sort, tostring, string.gsub, _G, loadfile

--Library Functions from around the net... =======================================================================================
---@class UtilityModule
local UtilityModule = rv.baseClass:new()
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

function UtilityModule.fakeProfileImport(path)
    local base = rv.baseClass:new() ---@type BaseClass
    base.autoKeys = true
    local magTable = base:autoTable({ library = {} })
    assert(rv.utils.lenientLoad(path, true), "Error importing '" .. path .. "': File not found/syntax error")(magTable, rv)
    base.autoKeys = false
    return magTable
end

function UtilityModule.invalidLua()
    local new_global_env = setmetatable({}, {
        __index = function(_, k) return k end
    })
    return setfenv(0, new_global_env)
end

function UtilityModule.validLua(stack)
    setfenv(stack or 2, cached_G)
end

local lenientFileCache = {} ---@type table<string,any>

function UtilityModule.lenientLoad(path, noExec)
    local p = path:gsub("%.lua$", ""):gsub("$", ".lua")
    if lenientFileCache[p] then return lenientFileCache[p] end
    rv.utils.invalidLua()
    local imp = loadfile(p) or function() return nil end
    local ret = noExec and imp or imp()
    rv.utils.validLua(0)
    if ret then lenientFileCache[p] = ret end
    return ret
end

---@param val number
---@param oldMin number
---@param newMin number
---@param newMax number
---@param oldMax number
function UtilityModule.linearTransform(val, oldMin, oldMax, newMin, newMax)
    return ((val - oldMin) / (oldMax - oldMin)) * (newMax - newMin) + newMin
end

function UtilityModule.parentPath(path)
    return gsub(path, "[^\\/]+$", "")
end

---Wipe a table completely
---@param tab table
function UtilityModule.wipe(tab)
    for k in pairs(tab) do tab[k] = nil end
end

---Splits a string with a separator
---@param str string
---@param sep string
function UtilityModule.splitter(str, sep)
    local ret = {}
    local n = 1
    for w in gmatch(str, "([^" .. sep .. "]*)") do
        ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
        if w == "" then n = n + 1 end -- step forwards on a blank but not a string
    end
    return ret
end

---@param o any[]
function UtilityModule.simpleSort(o)
    local function padnum(d) return ("%03d%s"):format(#d, d) end
    sort(o, function(a, b)
        return tostring(a):gsub("%d+", padnum) < tostring(b):gsub("%d+", padnum) end)
    return o
end

local function deepCopy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[deepCopy(k, s)] = deepCopy(v, s) end
    return res
end

UtilityModule.deepCopy = deepCopy

function UtilityModule.dummy() end

return UtilityModule