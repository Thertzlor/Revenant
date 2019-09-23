local tl = ...
local gmatch, setmetatable, type,pairs = 
string.gmatch, setmetatable, type,pairs
--Library Functions from around the net... =======================================================================================
function tl.Reverse(arr)
  local i, j = 1, #arr
  while i < j do
    arr[i], arr[j] = arr[j], arr[i]
    i = i + 1
    j = j - 1
  end
end

function tl.wipe(tab)
  for k in pairs(tab) do
    tab[k] = nil
  end
end

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

function tl.deepcopy(orig, copies, parent)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[tl.deepcopy(orig_key, copies,parent)] = tl.deepcopy(orig_value, copies,parent)
          end
          copies[orig] = copy
          setmetatable(copy, tl.deepcopy(getmetatable(orig), copies,parent))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  if type(copy) == "table" then tl.tablecrawl(copy,nil,nil,parent) end
  return copy
end