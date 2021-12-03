---@type MainLibObject
local tl = ...
local gmatch, setmetatable, type, pairs,getmetatable,sort,tostring = string.gmatch, setmetatable, type, pairs,getmetatable,table.sort,tostring
--Library Functions from around the net... =======================================================================================
---@class UtilityModule
local UtilityModule = tl.baseClass:new()
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
    if w == "" then
      n = n + 1
    end -- step forwards on a blank but not a string
  end
  return ret
end

function UtilityModule.simpleSort(o)
  local function padnum(d) return ("%03d%s"):format(#d, d) end
  sort(o, function(a,b)
    return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum) end)
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

-- local function deepCopy(orig, copies)
--   copies = copies or {}
--   local orig_type = type(orig)
--   local copy
--   if orig_type == 'table' then
--       if copies[orig] then
--           copy = copies[orig]
--       else
--           copy = {}
--           copies[orig] = copy
--           for orig_key, orig_value in next, orig, nil do
--               copy[deepCopy(orig_key, copies)] = deepCopy(orig_value, copies)
--           end
--           setmetatable(copy, deepCopy(getmetatable(orig), copies))
--       end
--   else -- number, string, boolean, etc
--       copy = orig
--   end
--   return copy
-- end

UtilityModule.deepCopy = deepCopy

function UtilityModule.dummy()end

return UtilityModule