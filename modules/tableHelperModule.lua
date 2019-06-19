local tl = ...

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
  
  function tl.props(tb) --does the table contain non-numeric keys?
    for i,_ in pairs(tb) do
      if type(i) == "string" and i ~= "pID" then return true end
    end
    return false
  end
  
  function tl.multiTab(acc) --is a table a button definition or another type of table?
    if type(acc) == "table" then
      for k, _ in pairs(acc) do
        if type(k) ~= "number" and k ~= "pID" then
          return false
        end
      end
      return true
    end
    return false
  end
  ---[[
  function tl.find(t,s)
  if type(t) ~="table" then return t==s end
  for i=1,#t do
    if t[i] == s then 
      return true 
    end
  end
  return false
  end

  function tl.mergeUpdate(u1,u2)
    if u1 == nil and u2 ==nil then return false end
    u1 = u1 or {}
    u1 = tl.deepcopy(u1)
    if tl.allType(u1,"table") == false then u1={u1} end
    if tl.allType(u2,"table") == false then u2={u2} end
    for i=1, #u2 do
      table.insert(u1,1,u2[i]) 
    end
    return u1
  end
  
  function tl.targetUpdate(reptables,tartable)
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
        local importer = tl.resolveLink(tl.macroStats[reptable[4] or "null"].macro)
        endInsert,_ = tabulate(reptable[2],importer,0)
      end
      
      if reptable[3] == nil or reptable[3] == "replace"  then
        targTab[valName] = endInsert
      elseif reptable[3] == "insert" then
  
        table.insert(targTab,valName,endInsert)
  
      elseif reptable[3] == "remove" then
        local g = reptable[2]
        if type(g) == "string" then
          targTab[valName][g] = nil
        elseif g < 1 then
          local posi = valName-1
          for i=1, math.abs(g) do 
            table.remove(targTab[valName],posi)
            posi = posi -1
          end
        else
         local posi = valName
         for i=1, g do 
          table.remove(targTab[valName],posi)
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
      if (tRes[k] == nil or override == 1 or override == 3) and string.match(k,"^_c") == nil and ig then
        tRes[k] = v
      end
    end
    return tRes
  end
  
  function tl.tablecrawl(tar) --Defines IDs of all sequence tables (recursively)
    for  o = 1, #tl.shortHands do local short = tl.shortHands[o]
      if tar[short[1]] then
        local shorty = tar[short[2]] or tar[short[1]]
        if tl.preferShorthand == 1 then shorty = tar[short[1]]  end
        tar[short[2]] =  shorty
        tar[short[1]] = nil
      end
    end
    if tar.pID == nil and tar.name and tar.name ~="" then -- If the sequences is named, the name will be used as its ID and a reference is put into a special array.
      tar.pID = tar.name
    elseif tar.pID == nil then 
      tar.pID = "c"..tl.tabNum --otherwise a unique ID will be generated based on execution order.
      tl.tabNum = tl.tabNum +1 
    end
    tl.macroStats[tar.pID] = tl.macroStats[tar.pID] or {macro=tar,check={}}
    if tl.modeUsed == 0 and tar.mode and tar.mode ~=0 then
    tl.modeUsed = 1
    end
    for _,n in pairs(tar) do
      if type(n) == "table" then
        tl.tablecrawl(n)
      end
    end
  end

  function tl.inherit(taba,globalis) --pass parent properties to child tables
    for k,d in pairs(taba) do
      local rideray = {}
      local gloverbal = {}
      if globalis == 1 then
      rideray = tl.assign.global
      gloverbal = tl.assign.globalOverride
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
                table.remove(d,m)
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
      tl.assign.global = nil
      tl.assign.globalOverride = nil
    end
  end
  
  function tl.heir(c,p)
    if type(c) ~= "table" then c = {c} tl.tablecrawl(c) end
    c.type = c.type or p.cast
    for m=1, #tl.sequenceInheritor do local attr = tl.sequenceInheritor[m]
      c[attr] =  c[attr] or p[attr]
    end
    return c
  end
  
  function tl.prettyTab(tabu,specmes) --pretty prints a table
    specmes=specmes or ""
    local processed = tl.pprint(tabu)
    processed = string.gsub(processed,"[\n]","")
    processed = string.gsub(processed," +"," ")
    processed = string.gsub(processed,"^{ *","")
    processed = string.gsub(processed,"}$","")
    processed = string.gsub(processed,", ([gm][0-9])",",\n%1")
   tl.putNoLCD("\n"..specmes.."\n"..processed)
  end