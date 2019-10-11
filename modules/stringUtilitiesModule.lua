local lower, match, sub, rep, type,concat, pairs, gsub =
string.lower, string.match, string.sub, string.rep, type,table.concat,pairs, string.gsub
---@type MainLibObject
local tl = ...
-->>>>  Functions that process or type strings ==================================================================

---adds currently pressed down keys to a table
---@param key string
function tl.addDown (key)
  if tl.cutine ~=0 then
    tl.roDown[tl.cutine][#tl.roDown[tl.cutine]+1] = key
  end
end

---Releases all keys currently locked/held down, called at the end of the script.
---@param there string
function tl.allUp(there)
  for _, va in pairs(tl.roDown[there]) do
    if va ~= nil then
      tl.putNoLCD("auto-released "..va)
      tl.Release(va,0,nil,1)
    end
  end
  tl.wipe(tl.roDown[there])
end

---press an array of keys, then release it.
---@param blu string[]
---@param del number
---@param dev number
---@param fam string
---@param num number
function tl.bothRay(blu,del,dev,fam,num)
  tl.preRay(blu,del,dev,fam,num)
  if del then tl.wait(del,dev) end
  tl.relRay(blu,del,dev)
end

---pressing down an array of buttons in order
---@param rayz string[]
---@param del number
---@param dev number
---@param fam string
---@param num number
function tl.preRay(rayz,del,dev,fam,num)
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.Press(obj,del,dev,fam,num)
      local dela =del or tl.keyDelay
      tl.wait(dela,dev)
    end
  end
end

---Releasing an array of buttons in order
---@param rayz string[]
---@param del number
---@param dev number
function tl.relRay(rayz,del,dev)
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

---removes keys from the held down list, when they are released again
---@param key string
---@param sil boolean
function tl.remDown(key,sil)
  if sil then
    return
  end
  if tl.cutine ~=0 then
    for i, va in pairs(tl.roDown[tl.cutine]) do
      if va == key then
        tl.roDown[tl.cutine][i]= nil
      end
    end
  end
end

---Outputs the first character of a string in lowercase.
---@param f string
function tl.token(f)
  if type(f)  ~= "string" then return false end
  return lower(sub(f, 1,1))
end

---function for deciding how to type different strings and arrays
---@param tstring string
---@param del number
---@param kdel number
---@param actionDeviator number
---@param keyDeviator number
---@param fam string
---@param num number
function tl.typer(tstring,del,kdel,actionDeviator,keyDeviator,fam,num)
  local wt = del or tl.actionDelay
  local kwt = kdel or tl.keyDelay
  if (#tstring == 1 or (sub(tstring,1,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring,2,3)) < 25)))) then
    tl.PressAndRelease(tstring,kwt,actionDeviator,keyDeviator,fam,num)
  else
    tl.TypeString(tstring,wt,kwt,actionDeviator,keyDeviator,fam,num)
  end
  tl.autoRelease(fam,num,kdel,keyDeviator)
end

function tl.applyBuffer(string,fam,num,clear) 
  if not fam or tl.state[fam]["_b"..num] == nil then return string end
  local buffString = tl.state[fam]["_b"..num]..string
  if clear then tl.state[fam]["_b"..num] = nil end
  
  return buffString
end


---@param string string
---@param fam string
---@param num number
---@param mode number
function tl.addBuffer(string,fam,num,mode)
  if mode ~= nil and tl.state[fam]["_b"..num] ~=nil then
    tl.state[fam]["_b"..num] = tl.state[fam]["_b"..num]..string
  else
    tl.state[fam]["_b"..num] = string
  end
end

---intelligently breaks tring for display on LCD screen.
---@param str string
---@param num number
---@return string
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

---intelligently divide text into multiple pages for display on LCD screen
---@param str string
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