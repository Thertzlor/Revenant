local tl = ...
local abs,sub,gsub,type,insert,remove, pairs, match =
math.abs, string.sub, string.gsub,type,table.insert,table.remove,pairs,string.match
---->>> 4.Functions for dealing with tables =================================================================================

function tl.full(tab) --does the table have any contents besides empty tables
  if type(tab) ~= "table" then
    return  true
  end
    for i=1, #tab do
      if tl.full(tab[i]) then return true end
  end
  return false
end

function tl.allType(ta,ty) -- Is there only a single data type stored in a table?
  if type(ta) ~= "table" then return false end
  for i=1,#ta do
    if type(ta[i]) ~= ty then return false end
  end
  return true
end

function tl.isContainer(pMac,anonymous)
  local exclude = tl.internalPropsName
  if anonymous then exclude = tl.internalProps end
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

function tl.props(tb) --does the table contain non-numeric keys?
  for i,_ in pairs(tb) do
    if type(i) == "string" and not tl.find(tl.internalProps,i) then return true end
  end
  return false
end

function tl.multiTab(acc) --is a table a button definition or another type of table?
  if type(acc) == "table" then
    for k, _ in pairs(acc) do
      if type(k) ~= "number" and k ~= "pID" and k ~= "_isCont" then
        return false
      end
    end
    return true
  end
   return false
end

function tl.find(t,s) -- Find a number or string in a table.
  if type(t) ~="table" then return t==s end
  for i=1,#t do
    if t[i] == s then
      return true
    end
  end
  return false
end

function tl.mergeUpdate(u1,u2,button)
  if u1 == nil and u2 ==nil then return false end
  u1 = u1 or {}
  u1 = tl.deepcopy(u1,nil,button)
  if tl.allType(u1,"table") == false then u1={u1} end
  if tl.allType(u2,"table") == false then u2={u2} end
  for i=1, #u2 do
    insert(u1,1,u2[i])
  end
  return u1
end

function tl.targetUpdate(reptables,tartable,parent) -- Property override for linked macros
  if type(reptables) ~= "table" or type(tartable) ~="table" then return end
  local function tabulate(tbl,startTable,noOff)
    local minus = noOff or 1
    local position = startTable or tartable or {}
    local finalValue = tbl[#tbl]
    for p=1, #tbl-minus do
      if type(tbl[p]) == "number" and tbl[p] < 1 then tbl[p] = #position+tbl[p] end
      position = position[tbl[p]]
    end
    return position, finalValue
  end

  local function replaceCycle(reptable)
    local h = reptable[1]
    local finaltarget;
    if type(h) ~= "table" then h={h} end
    local insertVal = false
    local targTab,valName = tabulate(h)
    local endInsert = reptable[2]
    if type(reptable[4]) == "string" then
      if type(reptable[2]) ~="table" then reptable[2] = {reptable[2]} end
      local importer = tl.resolveLink(tl.macroStats[reptable[4] or "null"].macro,parent)
      endInsert,_ = tabulate(reptable[2],importer,0)
    end

    if reptable[3] == nil or reptable[3] == "replace"  then
      targTab[valName] = endInsert
    elseif reptable[3] == "insert" then
      insert(targTab,valName,endInsert)
    elseif reptable[3] == "remove" then
      local g = reptable[2]
      if type(g) == "string" then
        targTab[valName][g] = nil
      elseif g > 1 then
        local posi = valName-1
        for i=1, abs(g) do
          remove(targTab,posi)
          posi = posi -1
        end
      else
        local posi = valName
        for i=1, g do
        remove(targTab,posi)
      end
    end
    end
  end

  if tl.allType(reptables,"table")== false then
    replaceCycle(reptables)
  else
    for i=1, #reptables do
      replaceCycle(reptables[i])
    end
  end
  return tartable
end

function tl.noType(table,typus) -- does a table NOT contain values of a certain type?
  for _, v in pairs(table) do
    if type(v) == typus then
      return false
    end
  end
  return true
end

function tl.intersect(tBase,tAdd,override,exRay) --Merge two tables in different ways
  local tRes = {}
  local tOver ={}
  local rider = override or 1
  local ignoray={
    {"pID","name"},
    {"singleType","pID","name"},
    {1,"type","t","pID","name","n","newType","keepExisting","update","u"},
    {1,"type","t","pID","name","n","newType","keepExisting","update","u"}
  }
  for k,v in pairs(tBase) do
    tRes[k] = v
  end

  for k,v in pairs(tAdd) do
    tOver[k] = v
  end

  if override == 3 and type(exRay) == "table" then
    for m=1,#exRay do
      ignoray[rider][#ignoray[rider]+1] = exRay[m]
    end

  elseif type(exRay) == "string" then
    ignoray[rider][#ignoray[rider]+1] = exRay
  end

  for k,v in pairs(tOver) do
    local ig = true
    for i=1, #ignoray[rider] do
      if k == ignoray[rider][i] then
        ig = false
      end
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

function tl.tablecrawl(tar,scope,key,parent) --Defines IDs of all macro tables (recursively)
  local doLint = false
  if parent or tl.find({"start","key","exit"},key) then doLint = true end
  local stats = tl.macroStats
  local topLevel = tar._fileOrigin
  if scope then
    tar._scope = scope
    tl.macroStats[scope] = tl.macroStats[scope] or {}
    stats = tl.macroStats[scope]
  end
  for  o = 1, #tl.shortHands do local short = tl.shortHands[o]
    if tar[short[1]] then
      local shorty = tar[short[2]] or tar[short[1]]
      if tl.preferShorthand then shorty = tar[short[1]] or shorty  end
      tar[short[2]] =  shorty
      tar[short[1]] = nil
    end
  end

  if tar.name and tar.name =="" then -- names that are empty strings are not accepted
    tar.name = nil
  end
  if tl.keyNamesAreMacroNames and tar.name == nil and  (tl.rename[key] or tl.unname[key]) then
    tar.name = key
  end

  if tar.pID == nil
  then
    tar.pID = "c"..tl.tabNum --otherwise a unique ID will be generated based on execution order.
    tl.tabNum = tl.tabNum +1
    local macro = tar
    if key == nil or topLevel  then macro ={} end
    stats[tar.pID] = stats[tar.pID] or {macro=macro,check={}}
  end

  if tl.modeUsed == 0 and tar.mode and tar.mode ~=0 then
  tl.modeUsed = 1
  end
  for k,n in pairs(tar) do
    if type(n) == "table" then
      if tl.find({"start","key","exit"},key) then parent = k end
      tl.tablecrawl(n,scope,k,parent)
    end
  end
  if tl.enableLinting and doLint then tl.linter(tar,parent) end
end

function tl.scopeNames(tar,scope,startType,final) --resolves the names of tables into table IDs based on their profile's scope
  local function getID(name)
    if tl.globalScopeKeys and (not final) and tl.unname(name) then return name end
    for i=scope,#tl.macroStats do local stat = tl.macroStats[i]
      for k, _ in pairs(stat) do
        if stat[k].macro and stat[k].macro.name == name then
          stat[k].referenced=true
          return k 
        end
      end
    end
    for k, _ in pairs(tl.macroStats) do
      if tl.macroStats[k].macro and tl.macroStats[k].macro.name == name then
        tl.macroStats[k].hasReference=true
      return k end
    end
    return name
  end
  local currentType = tar.type or startType
  if currentType == "l" then
    tar[1] = getID(tar[1])
  elseif currentType == "s" or currentType == "c" or currentType == "h"
  then
    for i = 1, #tar do local obj = tar[i]
      if type(obj) == "table" and #obj == 1 and tl.props(obj) == false and type(obj[1]) == "string" then
        obj[1] = getID(obj[i])
      end
    end
  elseif
  currentType == "sa" or
  currentType == "sp" or
  currentType == "sr" or
  currentType == "cr" or
  currentType == "hc"
  then
    if tar[1] and type(tar[1]) == "string" then
    tar[1] = getID(tar[1])
    end
  end

  local function scopeTests(tesTable)
    for k,v in ipairs(tesTable) do
      if type(v) == "table" then
        scopeTests(tesTable[k])
      elseif type(v) == "string" and match(v,"^[:~]") then
        tesTable[k] = sub(v,1,1)..getID(sub(v,2))
      end
    end
  end

  local function scopeUpdates(updateProp)
    if updateProp[4] and type(updateProp[4]) == "string" then
      updateProp[4] = getID(updateProp[4])
    end
  end

  if tar.test then
    local cTest = tar.test
    if type(cTest) == "string" and match(cTest,"^[:~]") then
      tar.test = sub(cTest,1,1)..getID(sub(cTest,2))
    elseif type(cTest) == "table" then
      scopeTests(tar.test)
    end
  end

  if tar.update and type(tar.update) == "table" then
    if tl.allType(tar.update,"table") == false then
      scopeUpdates(tar.update)
    else
      for i=1, #tar.update do
        scopeUpdates(tar.update[i])
      end
    end
  end

  for _,n in pairs(tar) do
    if type(n) == "table" then
      tl.scopeNames(n,scope,tar.cast)
    end
  end
end

function tl.elimiNames() --eliminate names from tables and count them.
  local stats 
  for i = 0,#tl.macroStats do stats = tl.macroStats[i]
    if i == 0 then stats =tl.macroStats end
    for k,_ in pairs(stats) do
      if stats[k].macro and stats[k].macro.name then
        stats[k].macro.name = nil
        tl.namedTables = tl.namedTables+1
      end
    end
  end
end

function tl.inherit(taba,origTable,globalis) --pass parent properties to child tables
  for k,d in pairs(taba) do
    local rideray = {}
    local gloverbal = {}
    if globalis == 1 then
    rideray = origTable.scopeDefaults or {}
    gloverbal = origTable.scopeOverride or {}
    end

    if type(k) == "string" and tl.unname[k] ~= nil then
      if type(d) == "table" and tl.props(d) == false then
        local m = 1
        while d[m] ~= nil do local v = d[m]
          if type(v) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
            v = {v}
          end
          if type(v) == "table" then
            if #v == 0 then --Arrays without any non-string keys are local override arrays.
              rideray = tl.intersect(rideray,v,1) -- properties are added to the override array
              remove(d,m)
              m=m-1
            elseif tl.props(tl.intersect(rideray,gloverbal,1)) then
              taba[k][m] = tl.intersect(tl.intersect(v,rideray),gloverbal,1)
            end
          end
          m=m+1
        end
      elseif type(d) == "table" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      elseif type(d) == "string" and tl.props(tl.intersect(rideray,gloverbal,1)) then
        d = {d}
        taba[k]= tl.intersect(tl.intersect(d,rideray),gloverbal,1)
      elseif type(d) == "string" then
        taba[k] = {taba[k]}
      end
    end
  end
  if globalis == 1 then
    tl.assign.scopeDefaults = nil
    tl.assign.scopeOverride = nil
  end
end

function tl.prettyTab(tabu,specmes,LCD) -- Pretty prints a table
  specmes=specmes or ""
  if specmes ~= "" then specmes = "\n"..specmes.."\n" end
  local putFunc = tl.putNoLCD
  if LCD then putFunc = tl.put end
  local processed = tl.pprint(tabu)
   processed = gsub(processed,"[\n]","")
   processed = gsub(processed," +"," ")
   processed = gsub(processed,"^{ *","")
   processed = gsub(processed,"}$","")
--   processed = gsub(processed,', pID = "[^"]+"',"")
   processed = gsub(processed,", ([gmkal][0-9])",",\n%1")
  putFunc(specmes..processed)
end