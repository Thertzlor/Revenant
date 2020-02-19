---@type MainLibObject
local tl = ...
local gmatch, setmetatable, type,pairs =
string.gmatch, setmetatable, type,pairs
--Library Functions from around the net... =======================================================================================

---Reverse an ordered table
---@param arr table
function tl.reverseTable(arr)
  local i, j = 1, #arr
  while i < j do
    arr[i], arr[j] = arr[j], arr[i]
    i = i + 1
    j = j - 1
  end
end

---Wipe a table completely
---@param tab table
function tl.wipe(tab)
  for k in pairs(tab) do
    tab[k] = nil
  end
end

---Splits a string with a separator
---@param str string
---@param sep string
function tl.splitter(str,sep)
  local ret={}
  local n=1
  for w in gmatch(str,"([^"..sep.."]*)") do
     ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
     if w=="" then
        n = n + 1
     end -- step forwards on a blank but not a string
  end
  return ret
end

---Make a deep copy of a table
---@param orig table | GenericMacro
---@param copies table
function tl.deepCopy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[tl.deepCopy(orig_key, copies)] = tl.deepCopy(orig_value, copies)
          end
          copies[orig] = copy
          setmetatable(copy, tl.deepCopy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  if type(copy) == "table" then tl.indexTables(nil,copy,nil,nil) end
  return copy
end