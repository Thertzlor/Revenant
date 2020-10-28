local BaseClass = {}---@class BaseClass
local type,pairs,setmetatable,OutputLogMessage,create,resume,rawset = type,pairs,setmetatable,OutputLogMessage,coroutine.create,coroutine.resume,rawset
local totalMacros = 0

---@protected
function BaseClass:constructor(baseObj)
  if type(baseObj) ~= "table" then return end
  for k, v in pairs(baseObj) do self[k]=v end
end

function BaseClass:genId()
  self.pID = 'c'..totalMacros
  totalMacros = totalMacros+1
  return self.pID
end
function BaseClass:countMacros() return totalMacros end

function BaseClass:new(...)
    local o = {}
    self.__index = self---@private
    self.__eq = function(a,b)return a.pID == b.pID end---@private
    setmetatable(o, self)
    o:constructor(...)
    return o
end

---@protected
---@param fn function Function
---@param strTab string|table Argument
---@vararg any
function BaseClass:multiArg(fn,strTab,...)
  local tab = type(strTab) == 'table'
  if tab then for i = 1, #strTab do  fn(strTab[i],...) end end
  return tab
end

function BaseClass:async(thread,...) 
  local thr = thread
  if type(thr) ~="thread" then thr = create(thr) end
  local b,e = resume(thr,...)
  if not b then OutputLogMessage(e..'\n') end
end

---@generic Source
---@param table Source
---@return Source
function BaseClass:autoTable(table)
  table = table or {}
  local autofill = {
    __index = function(table, key)
      if not self.autoKeys then return nil elseif key == "_meta" then return true end
      local newInf = self:autoTable()
      rawset(table, key, newInf)
      return newInf 
    end,
    __newindex = function(table, key, value)
      if not self.autoKeys then return rawset(table, key, value) end
      if type(value) == "table" and not value._meta then value = self:recursiveTable(value) end
      rawset(table, key, value)
    end,
  }
  setmetatable(table, autofill)
  return table
end

function BaseClass:recursiveTable(table)
  for k, v in pairs(table) do if type(v) == "table" then table[k] = self:recursiveTable(v) end end
  return self:autoTable(table)
end

return BaseClass