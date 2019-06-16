local tl = ...
--->>> The main framework functions for the script, controls parsing and execution of user defined bindings =============================================================

function tl.prepKeys() --Prepare the key assignments array
    tl.assign.null={}
    tl.assign.start={}
    tl.assign.exit={}
    tl.assign.global={}
    tl.assign.globalOverride={}
    tl.assign.key={}
    local function resign(tagta,cdepth)
      local depth = cdepth or 0
      if tl.sKey ~= 0 then
        for p=0, 2 do
          tagta["s"..p]={}
          if depth < tl.stackDepth then resign(tagta["s"..p],depth+1) end
        end
      end
  
      for i = 0, tl.maxMode do
        tagta["mode"..i]={}
        if depth < tl.stackDepth then resign(tagta["mode"..i],depth+1) end
      end
    end
    resign(tl.assign)
   -- tl.prettyTab(tl.assign)
  end
  
  function tl.switchCustom()
    for k,v in  pairs(tl.rename) do
      tl.unname[v]=k
    end
    for g=1, tl.buttonCount.mouse do
      tl.unname["m"..g] = tl.unname["m"..g] or "m"..g
    end
    for g=1, tl.buttonCount.keyboard do
      tl.unname["k"..g] = tl.unname["k"..g] or "k"..g
    end
    for g=1, tl.buttonCount.lhc do
      tl.unname["l"..g] = tl.unname["l"..g] or "l"..g
    end
    for g=1, tl.buttonCount.audio do
      tl.unname["a"..g] = tl.unname["a"..g] or "a"..g
    end
  end

  function tl.toKey(legtab) --push legacy key bindings into the key table and apply default bindings
    for k,v in pairs(legtab) do
      if type(k) == "string" and tl.unname[k] ~= nil then
        legtab.key[k] = legtab.key[k] or v
        legtab[k] = nil
      end
    end
  end
  
  function tl.setDefaults(ktab)
    for k,v in pairs(tl.defaultKeys) do
      if ktab[k] == nil then ktab[k] = v end
    end
  end
  

  function tl.extend(parentName)
    if parentName == "" or  type(parentName) ~= "string" then return end
    for i = 0, #tl.extendList do local ex=tl.extendList[i]
      if ex == parentName then tl.findEx = tl.findEx.."\n\nWARNING: Extending cancelled due to circular reference to "..parentName.."!\n" return end
    end
    tl.extendList[#tl.extendList+1] = parentName
    local exTable = {tl.extPaths[tl.fileLocation],string.gsub(parentName,"%.lua$","")..".lua"}
    if tl.childPaths == 1 then table.insert(exTable,1,tl.path) end
    local finalExPath = table.concat(exTable,"/")
    loadfile(finalExPath)(tl.assign, tl.assign.key)
  end
  
  function tl.loadEx() -- Loads external configuration files depending on profile types
    local pathTable = {tl.extPaths[tl.fileLocation],string.gsub(tl.fileName or tl.profileName,"%.lua$","")..".lua"}
    if tl.childPaths == 1 then table.insert(pathTable,1,tl.path) end
    local finalPath = table.concat(pathTable,"/")
    if tl.fileLocation ~= 0 then
      tl.findEx="Running on external configs ["..finalPath.."]"
      tl.extend(tl.extends)
      loadfile(finalPath)(tl.assign, tl.assign.key)
    elseif tl.fileLocation ~= 0 then
      tl.findEx="Running on internal configs, external file missing or broken. ["..finalPath.."]"
    end
  end

  function tl.compileAssignments(startable) --main function for parsing the flexible syntax
    local collector = startable.key
  
    function tabExtract(state,presets,moda) --Extract button functionality and put it into the main table
      tl.inherit(state)
      local stackM = tl[moda.."Stack"]
      local secundus = {}
      local prosits = tl.intersect({},presets)
      local hastype = prosits.type
      local single = prosits.singleType or tl.singleType
  
      for k,v in pairs(state) do
        if type(k) == "string" and tl.unname[k] ~= nil then
            if type(v) ~= "table" then
                v={v}
                v = tl.intersect(v,prosits,2)
            elseif tl.props(v) or (hastype ~= nil and single == 1) then
              v = tl.intersect(v,prosits,2)
            else
              for u=1, #v do
                if type(v[u]) ~= "table"  then
                  v[u]={v[u]}
                end
                v[u] = tl.intersect(v[u],prosits,2)
              end
            end
  
            if collector[k] == nil then
              collector[k] = v
            else
                if type(collector[k]) ~= "table" or tl.props(collector[k]) == true or tl.noType(collector[k],"table") then
                  collector[k]={collector[k]}
                end
                if type(v) ~= "table" or tl.props(v) then
                  if stackM == "prepend" then
                    table.insert(collector[k],1,v)
                  else
                    collector[k][#collector[k]+1]=v
                  end
                else
                  for u=1, #v do local h = u
                    if stackM == "prepend" then
                      if tl.stackAutoReverse == 1 then h = #v-u+1 end
                      table.insert(collector[k],1,v[h])
                    else
                      collector[k][#collector[k]+1]=v[h]
                    end
                  end
                end
            end
            state[k]=nil
        elseif type(state[k]) == "table" and k ~= "key" then
            secundus[k]=v
            state[k]=nil
        end
      end
      return {secundus,prosits,moda}
    end
  
    function unhier(t,prevs) --recursively retrieve key definitions from array
      local nextWave={}
      tl.inherit(t)
      prevs = prevs or {}
      local provs = tl.intersect({},prevs)
    function setMode()
      local retVal={}
        for k=0, tl.maxMode do local j = k
          if tl.modeSort == "reverse" then
            j = tl.maxMode-k
          elseif type(tl.modeSort) == "table" and #tl.modeSort == tl.maxMode+1 then
            j = tl.modeSort[k+1]
          end
          if  t["mode"..j] ~=nil then
            local curtable = t["mode"..j]
            provs.mode = j
            retVal[#retVal+1] = tabExtract(curtable,provs,"mode")
            t["mode"..j]=nil
          end
          provs.mode=prevs.mode
        end
      return retVal
    end
  
    function setShift()
      local retVal={}
      if tl.sKey ~=0 then
        for h = 0 , 2 do local j = h
          if tl.shiftSort == "reverse" then
            j = tl.maxMode-h
          elseif type(tl.shiftSort) == "table" and #tl.shiftSort == 3 then
            j = tl.shiftSort[h+1]
          end
            if t["s"..j] ~=nil then
                local shiftable = t["s"..j]
                provs.gshift = j
                retVal[#retVal+1] = tabExtract(shiftable,provs,"shift")
                t["s"..j] = nil
            end
            provs.gshift=prevs.gshift
          end
        end
      return retVal
    end
  
    function setCustom()
      
      local retVal={}
      for r = 1, #tl.customSort do local cusn = tl.customSort[r]
        local privs = {}
        if t[cusn] and t[cusn] == "table" then
          for d,m in pairs(t[cusn]) do
            if type(d) == "string" and tl.unname[d] == nil then privs[d] = m end
          end
          
          retVal[#retVal+1] = tabExtract(t[cusn],tl.intersect(prevs,privs,1),"custom")
          t[cusn]=nil
        end
      end
      
      for h,p in pairs(t) do
        local privs = {}
          if string.match(h,"^_c") and type(p) == "table" then
            for d,m in pairs(p) do
              if type(d) == "string" and tl.unname[d] == nil then privs[d] = m end
            end
            
            retVal[#retVal+1] = tabExtract(p,tl.intersect(prevs,privs,1),"custom")
            t[h]=nil
          end
        end
      return retVal
    end
  
    local ordertable = {custom=setCustom,mode=setMode,shift=setShift}
    for g = 1, #tl.stackOrder do local l = g
      if tl.stackAutoReverse == 1 and tl.modeStack == "prepend" and tl.shiftStack == "prepend" and tl.customStack == "prepend" then
        l = #tl.stackOrder-g+1
      end
      nextWave[#nextWave+1] = ordertable[tl.stackOrder[l]]()
    end
  
      if tl.full(nextWave) then
        for u=1,#nextWave do local n= nextWave[u]
          for o=1, #n do local x=n[o]
            unhier(x[1],x[2],x[3])
          end
        end
      end
    end
  
    unhier(startable)
    unhier(startable.key)
    startable = collector
  end
  
  function tl.resolveLink(link)
    local lock = link
    local combinedID = ''
    local metaUpdate = false
    while (lock.type == "l") and tl.macroStats[lock[1]] ~=nil do -- If the binding is a link we override the original binding's properties with any new ones
    
      local lockTarget = lock[1]
      local rideNum = 3
      if lock.keepExisting == 1 then rideNum = 4 end
      local unlock = tl.macroStats[lockTarget].macro
      
      combinedID = combinedID..lock.pID..unlock.pID
      if tl.dynamicTables[combinedID] ~= nil and tl.cacheLinks == 1 then
        lock = tl.dynamicTables[combinedID]
      else
        local currentUpdate = metaUpdate or lock.update; 
        metaUpdate = tl.mergeUpdate(currentUpdate,unlock.update)
        lock = tl.intersect(unlock,lock,rideNum,lock.keepExisting)
        local lack = tl.deepcopy(lock)
        if metaUpdate ~= false and lack.type ~="l" then lock = tl.targetUpdate(metaUpdate,lack) end
        lock._tablified_c = nil
        lock._tablified_s = nil
        tl.dynamicTables[combinedID] = lock
      end
    end
    return lock
  end
 
  function tl.keyGen(keyN,lock,keyCode,virt,virtrect,virpar) --function for fetching a button's bindings and feeding it to the execution function.
    local pKey = tl.assign.key[keyCode]
    if virt then pKey = lock end
    lock = tl.resolveLink(lock)
    local cmd = lock
   
   tl.key(
    keyN,
    cmd,
    lock.type,
    lock.gshift or pKey.gshift or tl.defG,
    lock.mode or pKey.mode or tl.defMode,
    lock.mkey or pKey.mkey,
    lock.mouseLock or pKey.mouseLock,
    lock.keyLock or pKey.keyLock,
    lock.consume or pKey.consume,
    lock.test or pKey.test,
    lock.direction or pKey.direction or "normal",
    lock.pID or pKey.pID,
    virt,
    lock.simDir or virtrect,
    virpar,
    lock.area)
  end
  
  function tl.mouseMem(mNum,mDir,mVirt,mCons)
    if not mVirt then --here temporary cycling sequences are reset based on button id.
      if tl.lastKeysDown[#tl.lastKeysDown] ~= mNum then
        tl.wipe(tl.unstable)
        for m,p in pairs(tl.TaskList) do
          if p.isTemp ~= nil then tl.TaskAbort(m) end
        end
      end
  
      local lastRay = tl.lastKeysDown --Recording the buttons that have recently been pressed
      if mDir == "up" then lastRay = tl.lastKeysUp end
  
      lastRay[#lastRay+1] = mNum
      if #lastRay > tl.historyDepth +1 then table.remove(lastRay,1) end
  
      if mCons == 1  or mCons==3 then
        tl.conKey = mNum
      else
        tl.conKey = 0
      end
    end
  end
  
  function tl.quickGen(bar) --quick and dirty keyGen call
    if type(bar) ~= "table" or tl.multiTab(args) == false then
     tl.keyGen(0,bar,0,5,1,"down",4)
    elseif type(bar) == "table" then
      for g=1, #bar do local com = bar[g]
        tl.keyGen(0,com,0,5,1,"down",4)
      end
    end
  end
  
  function tl.key(mouse,cmd,def,shifted,modi,mkeys,mouseLock,keyLock,cons,tes,pDir,ident,virtu,virdir,virp,area) --the main program for parsing key commands
    local mouseDir = virdir or tl.dir
    local stat = tl.macroStats[ident or "null"]
    local okayG = false
    local okayM = false
    local okayK = false
    local lShift = tl.shiftor
    local lMod = tl.modus
    local lModif = tl.mods
    local played = 0
    tl.macroStats.null={}
    
    local function tup(domo) --If specified, do the direction instructions on the key line up with the current input direction?
      local selec = domo or 1
      local reray = {{"normal","down"},{"up","up"}}
      --tl.put(mouseDir, pDir, mouseDir == reray[selec][2],pDir == reray[selec][1] )
      if ((mouseDir == reray[selec][2] and pDir == reray[selec][1]) or (virtu and not virdir)) then return true end
      return false
    end

    local function getShift()
      if type(shifted) == "number" and (shifted == 2 or (shifted == lShift))then 
        stat.check.shiftPass = true
        return true
        end
      return false
    end

    local function getMode()
      if type(modi) == "number" then
        if modi == 0 or modi == tonumber(lMod) then
          stat.check.modePass = true
          return true
        end
      elseif type(modi) == "table" then
        for i=1,#modi do local obj = modi[i]
          if obj == lMod then
            stat.check.modePass = true
            return true
          end
        end
       elseif type(modi) == "string" then
        stat.check.modePass = true
        return true
      end
      return false
    end

    local function getKey()
      if (mkeys == "no" and (lModif == nil or lModif== 0 or #lModif ==0)) or (mkeys ~="no" and (mkeys==nil or mkeys==0 or mkeys=="" or lModif == mkeys)) then
        okayK = true
      elseif type(lModif) == "string" and type(mkeys) == "string" then
        local comTab = {}
        local recTab = {}
  
        for i in string.gmatch(mkeys, "%a%a") do
          comTab[#comTab+1] = i
        end
  
        for i in string.gmatch(lModif, "%a%a") do
          recTab[#recTab+1] = i
        end
  
        local typeComb = false
  
        for i=1,#recTab do local obj = recTab[i]
          typeComb = false
          for d=1,#comTab do local abj = comTab[d]
            if string.match(obj,"%a$") == string.match(abj,"%a$") then
              typeComb = true
            end
            if typeComb == false then
              break
            end
          end
        end
  
        local keyComb = false
  
        for i=1,#comTab do local obj = comTab[i]
          keyComb = false
  
          for d=1,#recTab do local abj = recTab[d]
            if abj == obj or (string.match(obj,"%a") == "g" and string.match(obj,"%a$") == string.match(abj,"%a$")) then
              keyComb = true
            end
            if keyComb == false then
              break
            end
          end
        end
        if keyComb == true and typeComb == true then
          
          okayK = true
        end
      end
      stat.check.keyPass = okayK
      return okayK
    end

    local function getTest()
      local function tessa(ind) --evaluating the "test" conditions of a key.(recursive)
        local tes = ind or tes
    
        if type(ind) == "boolean" then
          return ind
        end
    
        local res = true
        local tas = tes
    
        if type(tes) == "number" then --testing for keys being currently held down.
          if 0 > tes then
            res = false
            tas = math.abs(tes)
          end
    
          if mouseDir == "down" and tNum(tas) == true then
            return res
          elseif mouseDir == "down" and tNum(tas) == false then
            if not virtu then tl.cList["_"..mouse.."t"..tes] = 1 end
            return not res
          end
    
          if pDir ~= "up" then
            if tl.cList["_"..mouse.."t"..tes] == nil then
              return res
            else
              return not res
            end
          else
            return tNum(tas,res)
          end
        elseif type(tes) == "string" and (tl.unname[tl.splitter(tes,",")[1] ] ~=nil or tonumber(tl.splitter(tes,",")[1]) ) then --testing for keys previously pushed.
  
          local wordMode = tl.unname[tl.splitter(tes,",")[1] ] ~=nil
  
          local virtoff = 0
          local thisRay = tl.lastKeysDown
          if virtu and tl.lastKeysDown[#tl.lastKeysDown] == mouse then virtoff = 1 end
          if mouseDir == "up" then thisRay = tl.lastKeysUp end
          local testRay = tl.splitter(tes,",")
          if #testRay > #thisRay then return false end
          local truthRay = {}
    
          for g = 1, #testRay do local i = #testRay-g+1 local unit = tonumber(testRay[i])
            if wordMode then unit = tonumber(string.sub(tl.unname[testRay[i] ],2))  end
            local negat = 0 > unit
            if (math.abs(unit) == tl.lastKeysDown[#tl.lastKeysDown-g+virtoff+1] and negat == false)
            or (math.abs(unit) ~= tl.lastKeysDown[#tl.lastKeysDown-g+virtoff+1] and negat == true)
            or (mouseDir == "up" and tl.lastKeysDown[#tl.lastKeysDown-virtoff] == mouse and tl.lastKeysUp[#tl.lastKeysUp-virtoff] ~= mouse)
            then
              truthRay[#truthRay+1]=1
            end
          end
    
          return #truthRay == #testRay
    
        elseif type(tes) == "string" then
          if string.match(tes,"^!?/") and string.sub(tes,-1) == "/" then
            if string.sub(tes,1,1) == "!" and tl.props(tl.TaskList) == false then
              return res
            elseif tl.props(tl.TaskList) == false then
              return not res
            end
            for r,_ in pairs(tl.TaskList) do
              if string.sub(tes,1,1) == "!" then
                local tos = string.sub(tes,2)
                if tl.querylize(tos,r) then return not res end
              else
    
                if tl.querylize(tes,r) then return res end
              end
            end
          else
            if string.sub(tes,1,1) == "!" then
              local tos = string.sub(tes,2)
              if tl.TaskList[tos] ~= nil then return not res end
            else
              if tl.TaskList[tes] ~= nil then return res end
            end
          end
    
        elseif type(tes) == "table" then --recursively testing arrays
          local m = tes.mode or "or"
          if mouseDir =="down" or (mouseDir == "up" and tup()) then
            if mouseDir == "down" then
             if not virtu then tl.cList["_"..mouse.."t"] = 1 end
            end
    
            local sucs = {}
    
            for i=1,#tes do local obj = tes[i]
              local subtest = tessa(obj)
              if m == "and" and subtest == false then return false end
              if m == "or" and subtest == true then return true
              elseif subtest == true then sucs[#sucs+1] = 1 end
            end
    
            if #sucs == 0 and (m=="nor" or m=="nand" or m=="xnor") then return true end
            if #sucs == #tes and (m=="and" or m=="xnor") then return true end
            if #sucs > 0 and #sucs ~= #tes and (m=="nand" or m == "xor") then return true end
    
            return false
    
          elseif mouseDir == "up" then
            if tl.cList["_"..mouse.."t"] == nil then
              return res
            else
              return not res
            end
          end
        else
          return res
        end
      end
      if tessa(tes) then stat.check.testPass = true return true end
      return false
    end

    local function getArea()
      if area ~= nil and not tl.areaCheck(area) then return false end
      stat.check.areaPass = true
      return true
    end



    if tup() or virtu then stat.check={} end
    
    if 
      ((stat.check.shiftPass or (tup() and getShift()) )
      and(stat.check.modePass or (tup() and getMode()) )
      and(stat.check.keyPass or (tup() and getKey()) )
      and(stat.check.areaPass or (tup() and getArea()) )
      and (stat.check.testPass or (tup() and getTest()) )) == false
    then
     -- tl.put(getShift(),getMode(),getKey(),getArea(),getTest())
      return played 
    end
   
    local function tNum(n,rev)
      local putout = rev or false
      local downT = table.concat(tl.downs,",")
      if (string.match(downT,"^"..n.."%a%d%a*") ~= nil) or (string.match(downT,","..n.."%a%d%a*") ~= nil) then
        return not putout
      else
        return putout
      end
    end
  
    if (tl.but == mouse or virtu) and (virtu or tl.conKey ~= mouse) then --starting the process to test if the right modifiers are down.

        if tl.logEmpty == 0 then
          tl.mouseMem(mouse,mouseDir,virtu,cons)
        end
  
          local tabs = tl.defaultFuncs
          if virtu and virtu ~= 2 and virdir == nil then
          mouseDir = nil
          tabs = tl.funcRayM
          elseif tup() then
          tabs = tl.funcRayU
          elseif tup(2) then
          tabs = tl.funcRayD
          end
        if def then
          if tabs[def] then
            tabs[def](cmd,mouseDir,pDir,mouse,virtu,virp)
          end
          played = 2
        else
          tabs.n(cmd,mouseDir,pDir,mouse,virtu,virp)
          played = 1
        end
      
    end
    return played
  end
  