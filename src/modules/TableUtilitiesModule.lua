local tl = ...---@type MainLibObject
local sub, gsub, type, pairs, abs,tonumber =
  string.sub,string.gsub,type,pairs,math.abs,tonumber
--=============================================================
local TableUtilitiesModule = tl.baseClass:new()---@class TableUtilitiesModule:BaseClass Functions for dealing with tables

TableUtilitiesModule.tabNum = 0
---Does the table have any enumerable contents besides empty tables?
---@param tab table
function TableUtilitiesModule:hasContent(tab)
  if type(tab) ~= "table" then return true end
  for i = 1, #tab do if self:hasContent(tab[i]) then return true end end
  return false
end

---Does the table only contain enumerable members of a single type?
---@param tab table
---@param ty string
function TableUtilitiesModule:isSingleTypeTable(tab, ty) -- Is there only a single data type stored in a table?
  if type(tab) ~= "table" then return false end
  for i = 1, #tab do if type(tab[i]) ~= ty then return false end end
  return true
end

---Splits a table into two tables, one containing numeric keys and on containing non numeric ones.
---@return table<number,any>,table<string,any>
function TableUtilitiesModule:splitEnumerable(tab)
  local commands = {}
  local options = {}
  if type(tab) ~= "table" then return {tab},{} end
  for k, v in pairs(tab) do ((type(k) == "string" and options) or commands)[k] = v end
  return commands, options
end

---does the table contain non-numeric keys?
---@param tb table
---@return boolean
function TableUtilitiesModule:hasProperties(tb)
  for i, _ in pairs(tb) do
    if type(i) == "string" and not self:find(tl.stringPresets.internalProps, i) then return true end
  end
  return false
end

--Checks if two tables are identical
---@param t1 table
---@param t2 table
function TableUtilitiesModule:sameContent(t1, t2)
  local t1_num = 0
  local t2_num = 0
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= "table" then return t1 == t2 end
  for k, v in pairs(t1) do
    t1_num = t1_num + 1
    if not t2[k] or type(t2[k]) ~= type(t1[k]) then return false end
    if t2[k] and not self:find(tl.stringPresets.internalPropsName, k) then
      if type(v) == "table" and not self:sameContent(t1[k], t2[k]) then return false end
    end
  end
  for _, _ in pairs(t2) do t2_num = t2_num + 1 end
  return t2_num == t1_num
end

---Find a number or string in a table.
---@param t table|any
---@param s string
---@return boolean
function TableUtilitiesModule:find(t, s)
  if type(t) ~= "table" then return t == s end
  for i = 1, #t do
    if t[i] == s then return true end
  end
  return false
end

---Merge two tables in different ways
---@param tBase GenericMacro the Base Table.
---@param tAdd GenericMacro the Added Table
---@param override number
---@param exRay table
function TableUtilitiesModule:intersect(tBase, tAdd, override, exRay)
  local tRes = {}
  local tOver = {}
  local rider = override or 1
  local ignoray = {
    {"pID", "name"},
    {1, "type", "t", "pID", "name", "n", "newType", "keepExisting", "update", "u"},
    {1, "type", "t", "pID", "name", "n", "newType", "keepExisting", "update", "u"}
  }

  for k, v in pairs(tBase) do tRes[k] = v end
  for k, v in pairs(tAdd) do tOver[k] = v end

  if override == 3 and type(exRay) == "table" then for m = 1, #exRay do ignoray[3][#ignoray[3] + 1] = exRay[m] end
  elseif  override == 3 and type(exRay) == "string" then ignoray[rider][#ignoray[rider] + 1] = exRay end

  for k, v in pairs(tOver) do
    local ig = true
    for i = 1, #ignoray[rider] do if k == ignoray[rider][i] then ig = false end end
    if (override == 3 or override == 4) and k == "newType" then  tRes.type = v end -- type override for link bindings
    if (tRes[k] == nil or override == 1 or override == 3) and sub(k, 1, 2) ~= "_c" and ig then tRes[k] = v end
  end
  return tRes
end

---@param first table First table?
---@param second table Second Table
---@param replaceExisting boolean 
function TableUtilitiesModule:intersectSimple(first,second,replaceExisting)
  local out = first
  for k, v in pairs(second) do out[k] = ((replaceExisting and v) or (out[k] ~= nil and out[k])) or v  end
  return out
end

---@param array string[]
---@return table<string,true> your face
function TableUtilitiesModule:propsFrom(array)
  local obj = {}
  for i = 1, #array do local s = array[i] obj[s]=true end
  return obj
end

---Pretty prints a Table
---@param tabu table
---@param specmes string
---@param LCD boolean
function TableUtilitiesModule:prettyTab(tabu, specmes, LCD)
  specmes = specmes and "\n" .. specmes .. "\n" or ""
  local putFunc = LCD and tl.put or tl.logitech.putNoLCD
  local processed = tl.helperUtils.pprint(tabu)
  local replacer = {
    {"[\n]", ""},
    {" +", " "},
    {"^{ *", ""},
    {"}$", ""},
    {', pID = "[^"]+"', ""},
    {", _isCont = [a-z]+", ""},
    {", ([gmkal][0-9])", ",\n%1"}
  }
  for i = 1, #replacer do
    processed = gsub(processed, replacer[i][1], replacer[i][2])
  end
  putFunc(tl.logitech, specmes .. processed)
end

---Cycle through a table's index with looping
---@param dex table|number
---@param num number
---@param current number
function TableUtilitiesModule:cycleIndex(dex, num, current)
  if not dex then return 1 end
  if type(dex) ~= "number" then dex = #dex end
  if not num or num == 0 then
    num = (current or 0) + 1
    if num > dex then num = 1 end
  elseif type(num) ~= "number" then
    if type(num) ~= "string" or not current then return 1 end
    local sign = sub(num, 1, 1)
    local parsedNum = tonumber(sub(num, 2))
    if not parsedNum or (sign ~= "+" and sign ~= "-") then return current end
    num = (current + (parsedNum * (sign == "-" and -1 or 1))) % (dex or 1)
  elseif num > dex then num = dex
  elseif num < 0 then
    if abs(num) > dex then num = 1
    else num = dex + num end
  end
  return num
end

return TableUtilitiesModule