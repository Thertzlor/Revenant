local type, pairs, setmetatable, OutputLogMessage, create, resume, rawset, random, floor, tostring, status = type, pairs, setmetatable, OutputLogMessage, coroutine.create, coroutine.resume, rawset, math.random, math.floor, tostring, coroutine.status
local totalMacros = 0
---generate a "seed" for all other IDs starting with "m_" followed by a string of numbers
---@param length integer #length of the preceeding random number
---@return string
local function idSeed(length)
   local id = "m"
   for _ = 1, length do id = id .. tostring(floor(random() * 10)) end
   return id .. "_"
end

local idBase = idSeed(0)

---The basic class encapsulating all core
---functionality inherited by all other classes
---@class BaseClass
---@field protected stack (string|{[1]:string,[2]:string})[]
---@field protected name string #The name of the object
---@field protected autoKeys boolean
---@field protected pID string #Unique ID of an object
local BaseClass = {}

---@private
---@param baseObj table<any,any>
function BaseClass:constructor(baseObj)
   if type(baseObj) ~= "table" then return end
   for k, v in pairs(baseObj) do
      self[k] = v ---@type any
   end
end

---@protected
---Generate an ID based on the id seed and number of other tables.
function BaseClass:genId()
   self.pID = idBase .. totalMacros
   totalMacros = totalMacros + 1
   if self.stack then self.stack[#self.stack + 1] = {self.pID, self.name} end
   return self.pID
end

---Construct a new Instance of a class, inheriting the metatable
function BaseClass:new(...)
   local o = {}
   self.__index = self ---@private
   self.__eq = function(a, b) return a.pID == b.pID end ---@private
   setmetatable(o, self)
   o:constructor(...)
   return o
end

---@protected
---Define a consistent way to handle errors for the class
---@param msg string
function BaseClass:errorHandler(msg) OutputLogMessage(msg) end

---@protected
---@async
---execute a function in an asynchronous thread.
---@param thread async fun()|thread
function BaseClass:async(thread, ...)
   local thr = thread
   if type(thr) ~= "thread" then thr = create(thr) end
   if status(thr) ~= "suspended" then return end
   local b, e = resume(thr, ...)
   if not b then self:errorHandler(e) end
end

---@protected
---Create a table that automatically fills non-defined keys with new empty tables.
---@generic Source
---@param tab? Source
---@return Source
function BaseClass:autoTable(tab)
   tab = tab or {}
   local autofill = { -- here the autofilling magic happens
      __index = function(tabs, key)
         if not self.autoKeys then
            return nil -- autofilling tables will only be created during compilation phase
         elseif key == "_meta" then
            return true
         end
         local newAuto = self:autoTable() ---@type table
         rawset(tabs, key, newAuto)
         return newAuto
      end,
      __call = function(tabs, arg) -- If the table is called, the argument will simply be appended if it is also a table
         if type(arg) == "table" then arg = self:autoTable(arg) end
         rawset(tabs, (#tabs + 1), arg)
      end,
      __newindex = function(tabs, key, value) -- any new table will be made into a refilling table
         if not self.autoKeys then return rawset(tabs, key, value) end
         if type(value) == "table" and not value._meta then value = self:recursiveTable(value) --[[@as table]] end
         rawset(tabs, key, value)
      end
   }
   setmetatable(tab, autofill)
   return tab
end

---@private
---Recursively turn all tables within an object into autoTables
---@generic Source table
---@param table `Source`
---@return Source
function BaseClass:recursiveTable(table)
   for k, v in pairs(table --[[@as table<string,any>]] ) do
      if type(v) == "table" then
         table[k] = self:recursiveTable(v) ---@type table
      end
   end
   return self:autoTable(table)
end

return BaseClass
