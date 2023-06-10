local rv = ... ---@type Revenant
local gmatch, setmetatable, type, pairs, getmetatable, sort, tostring, gsub, cached_G, loadfile, setfenv = string.gmatch, setmetatable, type, pairs, getmetatable, table.sort, tostring, string.gsub, _G, loadfile, setfenv

--[[=============================================================]] --
---Helper functions, some tricks from StackOverflow
---@class UtilityModule
---@field pprint fun(arg:table):string
local UtilityModule = rv.baseClass:new()

---Fakes a profile import
---@param path string
---@return ProfileTemplate
function UtilityModule.fakeProfileImport(path)
   local base = rv.baseClass:new()
   base.autoKeys = true
   local magTable = base:autoTable({library = {}}) ---@type ProfileTemplate
   assert(rv.utils.lenientLoad(path, true), "Error importing '" .. path .. "': File not found/syntax error")(magTable, rv)
   base.autoKeys = false
   return magTable
end

---creates a lua environment in which undefined variables are equal to their names as strings and no other globals
function UtilityModule.simplifiedLua()
   local new_global_env = setmetatable({}, {__index = function(_, k) return k end})
   return setfenv((0) --[[ @as any ]] , new_global_env)
end

---restores global lua to its default environment
---@param stack? integer #function scope
function UtilityModule.regularLua(stack) setfenv(stack or 2 --[[@as any]] , cached_G) end

local lenientFileCache = {} ---@type table<string,any>

---Load lua files in an environment with auto-filled variables
---@param path string #Path to the file
---@param noExec? boolean #true if we want a returned class to be instantiated later
---@return any #whatever was imported
function UtilityModule.lenientLoad(path, noExec)
   local p = path:gsub("%.lua$", ""):gsub("$", ".lua")
   if lenientFileCache[p] then return lenientFileCache[p] end
   rv.utils.simplifiedLua()
   local imp = loadfile(p) or function() return nil end
   local ret = noExec and imp or imp()
   rv.utils.regularLua(0)
   if ret then lenientFileCache[p] = ret end
   return ret
end

---Linear transform a value from one range into its equivalent in another range
---@param val integer #The value we want to transform
---@param oldMin integer #minimum value of range a
---@param newMin integer #minimum value of range b
---@param newMax integer #maximum value of range b
---@param oldMax integer #maximum value of range a
---@return integer #the value of `val` in range b
function UtilityModule.linearTransform(val, oldMin, oldMax, newMin, newMax) return ((val - oldMin) / (oldMax - oldMin)) * (newMax - newMin) + newMin end

---Return the parent path of a file
---@param path string #filepath to process
---@return string #parent folder of the provided path
function UtilityModule.parentPath(path)
   local r = gsub(path, "[^\\/]+$", "")
   return r
end

---Wipe a table completely
---@param tab table #table to wipe
function UtilityModule.wipe(tab) for k in pairs(tab) do tab[k] = nil end end

local matches = { ---all escapable characters
   ["^"] = "%^",
   ["$"] = "%$",
   ["("] = "%(",
   [")"] = "%)",
   ["%"] = "%%",
   ["."] = "%.",
   ["["] = "%[",
   ["]"] = "%]",
   ["*"] = "%*",
   ["+"] = "%+",
   ["-"] = "%-",
   ["?"] = "%?",
   ["\0"] = "%z"
}
---Escape special characters within a string
---@param s string #the string to escape
---@return string #The escaped string
function UtilityModule.escapeString(s)
   local esc = gsub(s, ".", matches)
   return esc
end

---Splits a string with a separator
---source: http://lua-users.org/wiki/SplitJoin
---@param str string #the string to split
---@param sep string #the separator to split at
---@return string[] #array of substrings
function UtilityModule.splitter(str, sep)
   local ret = {} ---@type string[]
   local n = 1
   for w in gmatch(str, "([^" .. sep .. "]*)") do
      ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
      if w == "" then n = n + 1 end -- step forwards on a blank but not a string
   end
   return ret
end

---sort a table alphanumerically
---source: https://stackoverflow.com/a/37043134
---@param o any[] #table to sort
---@return any[] #the sorted table
function UtilityModule.simpleSort(o)
   local function padnum(d) return ("%03d%s"):format(#d, d) end

   sort(o, function(a, b) return tostring(a):gsub("%d+", padnum) < tostring(b):gsub("%d+", padnum) end)
   return o
end

---Deep copy of an arbitrary table
---source: https://stackoverflow.com/a/26367080
---@generic S table
---@param obj S #the table to copy
---@param seen? table #keeps track of already encountered values
---@return S #deep copy of `table`
local function deepCopy(obj, seen)
   if type(obj) ~= "table" then return obj end
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
