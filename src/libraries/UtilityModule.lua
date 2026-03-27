local rv = ... ---@type Revenant
local gmatch, setmetatable, type, pairs, getmetatable, sort, tostring, gsub, cached_G, setfenv, GetMousePosition, floor, ceil = string.gmatch, setmetatable, type, pairs, getmetatable, table.sort, tostring, string.gsub, _G, setfenv, GetMousePosition, math.floor, math.ceil

--[[=============================================================]] --
---Helper functions, some tricks from StackOverflow
---@class UtilityModule:BaseClass
---@field pprint fun(arg:table):string
local UtilityModule = rv.baseClass:new()

---creates a lua environment in which undefined variables are equal to their names as strings and no other globals
function UtilityModule.simplifiedLua()
   local new_global_env = setmetatable({}, {__index = function(_, k) return k end})
   return setfenv((0) --[[ @as any ]], new_global_env)
end

---restores global lua to its default environment
---@param stack? integer #function scope
function UtilityModule.developerMode(stack) setfenv(stack or 2, cached_G) end

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
---@param tab table<string,any> #table to wipe
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
---@generic S table<any,any>
---@param obj S #the table to copy
---@param seen? table #keeps track of already encountered values
---@return S #deep copy of `table`
local function deepCopy(obj, seen)
   if type(obj) ~= "table" then return obj end ---@cast obj table<any,any>
   if seen and seen[obj] then return seen[obj] end
   local s = seen or {} ---@type table<any,any>
   local res = setmetatable({}, getmetatable(obj)) ---@type table<any,any>
   s[obj] = res
   for k, v in pairs(obj) do res[deepCopy(k, s)] = deepCopy(v, s) end
   return res
end

UtilityModule.deepCopy = deepCopy

function UtilityModule.dummy() end

---Setup Wizard to guide the user through the multi monitor definition process.
---@param profile ProfileTemplate
function UtilityModule.monitorWizard(profile)
   local NUMBER_OF_MONITORS = #profile.config.monitors
   local limit = (2 ^ 16) - 1 -- 65535
   local monStep = 0
   ---@type table<string,number>
   local results = {}
   local order = {
      {"Welcome to the Multi-Monitor Setup!\nWe will now establish the virtual desktop boundaries as well individual monitor boundaries using your mouse position.\nMake sure that you don't change mouse profiles during this process and that the number and resolutions of your monitors is set correctly in the profile.config.monitors table.\n\nStart by pressing this button again with your cursor positioned at the top edge of your highest monitor.", "x", "_init"},
      {"Minimum Y coordinate saved.\nNext, press this button at the bottom edge of your lowest monitor.",
         "y", "yMin"},
      {"Maximum Y coordinate saved.\nNext, press this button at the left edge of your leftmost monitor.",
         "y", "yMax"},
      {"Minimum X coordinate saved.\nNext, press this button at the right edge of your rightmost monitor.",
         "x", "xMin"},
      {"Maximum X coordinate saved.\n\nWe can now begin configuring coordinates of the " .. NUMBER_OF_MONITORS .. " individual monitors.\n" .. (NUMBER_OF_MONITORS * 2) .. " more steps and we're done!\nPress this button in the top left corner of your 1st monitor.",
         "x", "xMax"}
   }

   local function exec(m, c, k)
      local x, y = GetMousePosition()
      results[k] = c == "x" and x or y
      rv:put(m .. "\n")
   end

   ---@type {bottomRight:number[],topLeft:number[]}[]
   local monList = profile.config.monitors
   local first = true
   local finMes = "This is the finalized monitor table for your profile configuration:"

   return function()
      if first then
         for i = 1, #order do
            local o = order[i]
            if results[o[3]] == nil then
               exec(o[1], o[2], o[3])
               if i == #order then first = false end
               break
            end
         end
      else
         if monStep ~= NUMBER_OF_MONITORS * 2 then
            local firstStep = monStep % 2 == 0
            local moNum = floor(monStep / 2) + 1
            local x, y = GetMousePosition()
            if firstStep then
               monList[moNum].topLeft = {floor(UtilityModule.linearTransform(x, results.xMin, results.xMax, 0, limit)), floor(UtilityModule.linearTransform(y, results.yMin, results.yMax, 0, limit)), x, y}
               rv:put("Top left coordinates saved for monitor " .. moNum .. "!\nNow press this button in the bottom right corner of this monitor!\n")
            else
               monList[moNum].bottomRight = {floor(UtilityModule.linearTransform(x, results.xMin, results.xMax, 0, limit)), floor(UtilityModule.linearTransform(y, results.yMin, results.yMax, 0, limit)), x, y}
               rv:put("Bottom right coordinates saved for monitor " .. moNum .. "!\n" .. (moNum == NUMBER_OF_MONITORS and "we're done!\n" .. rv.tbl:prettyTab(monList, finMes, true) or "Now press this button in the top left corner of monitor " .. (moNum + 1) .. ".\n"))
            end
            monStep = monStep + 1
         else
            rv.tbl:prettyTab(monList, finMes)
         end
      end
   end
end

function UtilityModule.logPos()
   local x, y = GetMousePosition()
   local restricted = rv.profile.config.restrictToMainScreen
   rv:put("Normalized coordinates: " .. x .. " / " .. y)
   local moni = rv.mouseMonitorUtils:getCurrentMonitor(x, y)
   if moni and (not restricted or moni.main) then
      local pv = moni:normalToVirtual({x, y}, true)
      if not restricted then rv:put("Normalized Virtual coordinates: " .. ceil(pv[1]) .. " / " .. ceil(pv[2]) .. "\n") end
      rv:put("On monitor " .. moni.index .. (moni.main and " (main monitor)" or ""))
      if moni.main then
         local pcx = moni:normalToPerc({x, y}, true)
         local px = moni:normalToPx({x, y}, true)
         rv:put(ceil(px[1]) .. "px / " .. ceil(px[2]) .. "px")
         rv:put(ceil(pcx[1]) .. " percent (width) / " .. ceil(pcx[2]) .. " percent (height)")
      else
         local pcx, pcy = moni:currentPosition()
         local cd = {pcx, pcy}
         local pc = moni:virtualToPerc(cd, true)
         local px = moni:virtualToPx(cd, true)
         rv:put(ceil(px[1]) .. "px / " .. ceil(px[2]) .. "px")
         rv:put(ceil(pc[1]) .. " percent (width) / " .. ceil(pc[2]) .. " percent (height)")
      end
   else
      rv:put("The mouse is not on any configured monitor.")
   end
   rv:put("===============")

   return x, y
end

return UtilityModule