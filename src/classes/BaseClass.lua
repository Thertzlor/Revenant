local type, pairs, setmetatable, OutputLogMessage, create, resume, rawset, random, floor, tostring, status = type, pairs, setmetatable, OutputLogMessage, coroutine.create, coroutine.resume, rawset, math.random, math.floor, tostring, coroutine.status
local totalMacros = 0
---@alias T table
---@param length number
local function idSeed(length)
    local id = "m"
    for _ = 1, length do id = id .. tostring(floor(random() * 10)) end
    return id .. "_"
end

local idBase = idSeed(5)

---@class BaseClass
---@field stack string[]
---@field name string
---@field autoKeys boolean
local BaseClass = {}

---@private
function BaseClass:constructor(baseObj)
    if type(baseObj) ~= "table" then return end
    for k, v in pairs(baseObj) do self[k] = v end
end

---@private
function BaseClass:genId()
    self.pID = idBase .. totalMacros
    totalMacros = totalMacros + 1
    if self.stack then self.stack[#self.stack + 1] = { self.pID, self.name } end
    return self.pID
end

---@private
function BaseClass:new(...)
    local o = {}
    self.__index = self---@private
    self.__eq = function(a, b) return a.pID == b.pID end---@private
    setmetatable(o, self)
    o:constructor(...)
    return o
end

---@protected
---@param fn function Function
---@param strTab string|table Argument
---@vararg any
function BaseClass:multiArg(fn, strTab, ...)
    local tab = type(strTab) == 'table'
    if tab then for i = 1, #strTab do fn(strTab[i], ...) end
    else fn(strTab, ...) end
    return tab
end

---@protected
function BaseClass:errorHandler(msg) OutputLogMessage(msg) end

---@protected
---@param thread thread|function
function BaseClass:async(thread, ...)
    local thr = thread
    if type(thr) ~= "thread" then thr = create(thr) end
    if status(thr) ~= "suspended" then return end
    local b, e = resume(thr, ...)
    if not b then self:errorHandler(e) end
end

---@private
---@generic Source
---@param tab? Source
---@return Source
function BaseClass:autoTable(tab)
    tab = tab or {}
    local autofill = {
        __index = function(tabs, key)
            if not self.autoKeys then return nil
            elseif key == "_meta" then return true end
            local newInf = self:autoTable()
            rawset(tabs, key, newInf)
            return newInf
        end,
        __call = function(tabs, arg)
            if type(arg) == "table" then arg = self:autoTable(arg) end
            rawset(tabs, (#tabs + 1), arg)
        end,
        __newindex = function(tabs, key, value)
            if not self.autoKeys then return rawset(tabs, key, value) end
            if type(value) == "table" and not value._meta then value = self:recursiveTable(value) end
            rawset(tabs, key, value)
        end,
    }
    setmetatable(tab, autofill)
    return tab
end

---@private
---@param table table
function BaseClass:recursiveTable(table)
    for k, v in pairs(table) do if type(v) == "table" then table[k] = self:recursiveTable(v) end end
    return self:autoTable(table)
end

return BaseClass