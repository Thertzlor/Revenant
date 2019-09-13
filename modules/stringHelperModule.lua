local tl = ...
local lower, match, sub, rep, type,concat, pairs = 
string.lower, string.match, string.sub, string.rep, type,table.concat,pairs
--->>>  Functions that process or type strings ==================================================================
function tl.addDown (key) --adds currently pressed down keys
  if tl.cutine ~=0 then
    tl.roDown[tl.cutine][#tl.roDown[tl.cutine]+1] = key
  end
end

function tl.allUp(there) --Releases all keys currently locked/held down, called at the end of the script.
  for _, va in pairs(tl.roDown[there]) do
    if va ~= nil then
      tl.putNoLCD("auto-released "..va)
      tl.Release(va,0,nil,1)
    end
  end
  tl.wipe(tl.roDown[there])
end

function tl.bothRay(blu,del,dev,fam,num) --press an array of keys, then release it.
  tl.preRay(blu,del,dev,fam,num)
  if del then tl.wait(del,dev) end
  tl.relRay(blu,del,dev,fam,num)
end

function tl.preRay(rayz,del,dev,fam,num) --pressing down an array of buttons in order
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Press(obj,del,dev,fam,num)
      local dela =del or tl.keyDelay
      tl.wait(dela,dev)
    end
  end
end

function tl.relRay(rayz,del,dev) --...and releasing an array of buttons in order
  tl.Reverse(rayz)
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Release(obj,nil,dev)
      if del then del=del else del=tl.keyDelay end
      tl.wait(del,dev)
    end
  end
  tl.Reverse(rayz)
end

function tl.remDown(key,sil) --removes keys from the held down list, when they are released again
  if sil then
    return
  -- else tl.put("removing "..tostring(key))
  end
  if tl.cutine ~=0 then
    for i, va in pairs(tl.roDown[tl.cutine]) do
      if va == key then
        tl.roDown[tl.cutine][i]= nil
      end
    end
  end
end

function tl.token(f)
  if type(f) ~= "string" then return false end
  return lower(sub(f, 1,1))
end

function tl.typer(tstring,del,kdel,actionDeviator,keyDeviator,fam,num) --function for deciding how to type different strings and arrays
  local wt = del or tl.actionDelay
  local kwt = kdel or tl.keyDelay
  if (#tstring == 1 or (sub(tstring,1,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring,2,3)) < 25)))) then
    tl.PressAndRelease(tstring,kwt,keyDeviator,fam,num)
  else
    tl.TypeString(tstring,wt,kwt,actionDeviator,keyDeviator,fam,num)
  end
  tl.autoRelease(fam,num,kdel,keyDeviator)
end

function tl.applyBuffer(string,fam,num,clear)
  if not fam then return string end
  local buffString = ''
  if tl.state[fam]["_b"..num] == nil then 
    buffString = string 
  else
    buffString = tl.state[fam]["_b"..num]..string
    if clear then tl.state[fam]["_b"..num] = nil end
  end
  return buffString
end

function tl.addBuffer(string,fam,num,mode)
  if mode ~= nil and tl.state[fam]["_b"..num] ~=nil then
    tl.state[fam]["_b"..num] = tl.state[fam]["_b"..num]..string
  else
    tl.state[fam]["_b"..num] = string
  end
end

function tl.stringBreaker(str,num)
  if num == 0 or #str < num then 
    return str
  else
    local needRepeat  = false
    local seppedRay = tl.splitter(str,"\n")
    repeat
      local brokeRay = {}
      needRepeat  = false
      for i = 1, #seppedRay do local obj = seppedRay[i]
        if #obj > num then
          local dex = 0
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[^%s]") do
            dex = dex + 1
          end
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[%s]") do
            dex = dex + 1
          end
          local sep = ""
          if (num-dex) == 1 then
            dex = 0
            if(match(sub(obj,num,num),"[%s]"))then 
              sep = "-"
            end
          end
          obj = gsub(obj,"^("..rep(".",(num -dex - #sep))..")[%s]*(.*)$","%1"..sep.."\n%2")
        end
        brokeRay[#brokeRay+1] = tl.splitter(obj,"\n")[1]
        brokeRay[#brokeRay+1] = tl.splitter(obj,"\n")[2]
        if #brokeRay[#brokeRay] > num then needRepeat = true end
      end
      seppedRay = brokeRay
    until needRepeat == false
    str = concat(seppedRay,'\n')
    if #tl.splitter(str,"\n") > tl.displayLines then str = tl._paginator(str) end
    return str
  end
end

function tl._paginator(str)
  if str ~= tl.cachedString then
    tl.paginatorState = 0
    tl.cachedString = str
  end
  local sep = tl.splitter(str,"\n");
  if tl.displayLines == 0 or #sep <= tl.displayLines then 
    return concat(sep,'\n')
  else
    local pageMax = math.ceil(#sep/(tl.displayLines-1))
    if tl.paginatorState == pageMax then tl.paginatorState = 0 end
    local outTable = {}
    for k = tl.displayLines*(tl.paginatorState), (tl.displayLines*(tl.paginatorState))+tl.displayLines-1 do
     if k~=0 then outTable[#outTable+1] = sep[k] or "" end
    end
    local pageNums = "["..(tl.paginatorState+1).."/"..(pageMax).."]"
    outTable[tl.displayLines] = pageNums
    tl.paginatorState = tl.paginatorState+1
    return concat(outTable, "\n")
  end
end