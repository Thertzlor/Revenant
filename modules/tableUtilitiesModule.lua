---@type MainLibObject
local tl = ...
local sub,gsub,type, pairs, abs, lower =
string.sub, string.gsub,type,pairs,math.abs,string.lower
-->>> 4.Functions for dealing with tables =================================================================================

---Does the table have any contents besides empty tables?
---@param tab table
function tl.hasContent(tab)
  if type(tab) ~= "table" then return  true end
  for i=1, #tab do
      if tl.hasContent(tab[i]) then return true end
  end
  return false
end

function tl.isSingleTypeTable(ta,ty) -- Is there only a single data type stored in a table?
  if type(ta) ~= "table" then return false end
  for i=1,#ta do
    if type(ta[i]) ~= ty then return false end
  end
  return true
end

---Checks if a table is a collection of macros or a single macro.
---@param pMac table
---@param anonymous boolean
---@return boolean
function tl.isContainer(pMac,anonymous)
  local exclude = anonymous and tl.internalProps or tl.internalPropsName
  if type(pMac) ~= "table" then return false end
  if pMac._isCont ~= nil then return pMac._isCont end
  if #pMac == 0 then 
    pMac._isCont = false
    return false
  end
    for i,_ in pairs(pMac) do
      if type(i) == "string" and not tl.find(exclude,i) then
        pMac._isCont = false
        return false
      end
    end
    pMac._isCont = true
    return true
end

---does the table contain non-numeric keys?
---@param tb table
---@return boolean
function tl.hasProperties(tb)
  for i,_ in pairs(tb) do
    if type(i) == "string" and not tl.find(tl.internalProps,i) then return true end
  end
  return false
end

function tl.sameContent(t1,t2)
  local t1_num = 0
  local t2_num = 0
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= 'table' then return t1 == t2 end
  for k,v in pairs(t1) do
      t1_num = t1_num +1
      if not t2[k] or type(t2[k]) ~= type(t1[k])then return false end
      if t2[k] and not tl.find(tl.internalPropsName,k) then
        if type(v) == "table" and not tl.sameContent(t1[k],t2[k]) then return false end
      end
  end
  for _,_ in pairs(t2) do t2_num = t2_num +1 end
  return t2_num == t1_num
end

---Find a number or string in a table.
---@param t table|any
---@param s string
---@return boolean
function tl.find(t,s)
  if type(t) ~="table" then return t==s end
  for i=1,#t do
    if t[i] == s then return true end
  end
  return false
end

---does a table NOT contain values of a certain type?
---@param table table
---@param typus string
function tl.noType(table,typus)
  for _, v in pairs(table) do
    if type(v) == typus then return false end
  end
  return true
end

---Merge two tables in different ways
---@param tBase GenericMacro
---@param tAdd GenericMacro
---@param override number
---@param exRay table
function tl.intersect(tBase,tAdd,override,exRay)
  local tRes = {}
  local tOver ={}
  local rider = override or 1
  local ignoray={
    {"pID","name"},
    {"singleType","pID","name"},
    {1,"type","t","pID","name","n","newType","keepExisting","update","u"},
    {1,"type","t","pID","name","n","newType","keepExisting","update","u"}
  }
  for k,v in pairs(tBase) do tRes[k] = v end

  for k,v in pairs(tAdd) do tOver[k] = v end

  if override == 3 and type(exRay) == "table" then
    for m=1,#exRay do ignoray[rider][#ignoray[rider]+1] = exRay[m] end

  elseif type(exRay) == "string" then ignoray[rider][#ignoray[rider]+1] = exRay end

  for k,v in pairs(tOver) do
    local ig = true
    for i=1, #ignoray[rider] do
      if k == ignoray[rider][i] then ig = false end
    end
    if (override == 3 or override == 4) and k == "newType" then -- type override for link bindings
      tRes.type= v
    end
    if (tRes[k] == nil or override == 1 or override == 3) and sub(k,1,2) ~= "_c" and ig then
      tRes[k] = v
    end
  end
  return tRes
end

---Defines IDs of all macro tables (recursively)
---@param tar ProfileDefinition|GenericMacro
---@param scope number
---@param key string
---@param parent string
---@param typeCast string
function tl.indexTables(macroTarget,tar,scope,key,parent,typeCast)
  local doLint = false
  if parent or tl.find({"start","key","exit"},key) then doLint = true end
  local stats = tl.macroIndex
  local topLevel = tar._fileOrigin
  macroTarget = macroTarget or tl
  if scope then
    tar._scope = scope
    ---@type MacroStatContainer
    macroTarget.macroIndex[scope] = macroTarget.macroIndex[scope] or tl.newIndexTable()
    stats = macroTarget.macroIndex[scope]
  end
  for  o = 1, #tl.shortHands do local short = tl.shortHands[o]
    if tar[short[1]] then
      local shorty = tar[short[2]] or tar[short[1]]
      if tl.config.preferShorthand then shorty = tar[short[1]] or shorty  end
      tar[short[2]] =  shorty
      tar[short[1]] = nil
    end
  end
  local typeProps = {"type","cast","newType"}
  for i = 1, #typeProps do local t = typeProps[i] if tar[t] then tar[t] = tl.funcMapper[lower(tar[t])] or tar[t] end end
  if tar.name and tar.name =="" then -- names that are empty strings are not accepted
    tar.name = nil
  end
  if tl.config.keyNamesAreMacroNames and tar.name == nil and  (tl.config.rename[key] or tl.unname[key]) then
    tar.name = key
  end

  local newMeta = {__index = {_meta={}}}
  setmetatable(tar,newMeta)

  if tar.pID == nil then
    tar.pID = "c"..tl.tabNum --otherwise a unique ID will be generated based on execution order.
    tl.tabNum = tl.tabNum +1
    local macro = tar
    if key == nil or topLevel  then macro ={} end
    stats[tar.pID] = stats[tar.pID] or macro
  end

  if tl.modeUsed == 0 and tar.mode and tar.mode ~=0 then
  tl.modeUsed = 1
  end
  for k,n in pairs(tar) do
    if type(n) == "table" then
      if tl.find({"start","key","exit"},key) then parent = k end
      tl.indexTables(macroTarget,n,scope,k,parent,tar.cast)
    end
  end
  if tl.config.enableLinting and doLint then tl.linter(tar,parent,typeCast) end
end

---Pretty prints a Table
---@param tabu table
---@param specmes string
---@param LCD boolean
function tl.prettyTab(tabu,specmes,LCD)
  specmes= specmes and "\n"..specmes.."\n" or ""
  local putFunc = LCD and tl.put or tl.putNoLCD
  local processed = tl.pprint(tabu)
  local replacer = {{"[\n]",""},{" +"," "},{"^{ *",""},{"}$",""},{', pID = "[^"]+"',""},{', _isCont = [a-z]+',""},{", ([gmkal][0-9])",",\n%1"}}
  for i = 1, #replacer do processed = gsub(processed,replacer[i][1],replacer[i][2]) end
  putFunc(specmes..processed)
end

function tl.cycleIndex(dex,num,current)
  if not dex then return 1 end
  if type(dex) ~= "number" then dex = #dex end
  if not num or num == 0 then
    num = (current or 0) + 1
    if num > dex then num = 1 end
  elseif type(num) ~= "number" then
    if type(num) ~= "string" or not current then return 1 end
    local sign = sub(num,1,1)
    local parsedNum = tonumber(sub(num,2))
    if not parsedNum or (sign ~= "+" and sign ~= "-") then return current end
    num = (current  + (parsedNum * (sign == "-" and -1 or 1)) ) % (dex or 1)
  elseif num > dex then num = dex
  elseif num < 0 then
    if abs(num) > dex then
      num = 1
    else
      num = dex + num
    end
  end
  return num
end