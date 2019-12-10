---@type MainLibObject
local tl = ...
local lower, match, sub, rep, type,concat, pairs, gsub,find =
tl.utf8.lower, tl.utf8.match, tl.utf8.sub, tl.utf8.rep, type,table.concat,pairs, tl.utf8.gsub,tl.utf8.find
local cachedString, paginatorState
-->>>>  Functions that process or type strings ==================================================================


---Main function for typing strings of keys.
---@param s string
---@param delay number
---@param kelay number
---@param actionDeviator number
---@param keyDeviator number
---@param fam string
---@param num number
local function _typeString(s, delay,kelay,actionDeviator,keyDeviator,fam,num)
  local i,n,c,a
  n = #s
  i = 1
  while i <= n do
    a = 1
    c = sub(s,i,i)				-- get each character from s
    while find(sub(c,a,a),"[/%#~%*|]") do					-- / signals special character, which is 2 characters wide
      if i < n then
        local add = 2
        if sub(c,a,a) == "/"then
          if  find(sub(s,i+1,i+2),"[012]%d") then
            c = c..sub(s,i+1,i+2)
          else
            c = c..sub(s,i+1,i+1)
            add = 1
          end
          i = i+add
          a = a+2
        else
          c = c..sub(s,i+1,i+1)
          i = i+1
          a = a+1
        end
      else
        error("found a single escape sequence at end of tl.utf8.  For a single /, put two in a row. i.e. //")
      end
    end
    tl.pressAndRelease(c,kelay,actionDeviator,keyDeviator,fam,num)
    if delay and i < n then
      tl.wait(delay,actionDeviator)
    end
    i = i+1
  end
end

---intelligently divide text into multiple pages for display on LCD screen
---@param str string
local function _paginator(str)
  if str ~= cachedString then
    paginatorState = 0
    cachedString = str
  end
  local sep = tl.splitter(str,"\n");
  if tl.config.displayLines == 0 or #sep <= tl.config.displayLines then
    return concat(sep,'\n')
  else
    local pageMax = math.ceil(#sep/(tl.config.displayLines-1))
    if paginatorState == pageMax then paginatorState = 0 end
    local outTable = {}
    for k = tl.config.displayLines*(paginatorState), (tl.config.displayLines*(paginatorState))+tl.config.displayLines-1 do
     if k~=0 then outTable[#outTable+1] = sep[k] or "" end
    end
    local pageNums = "["..(paginatorState+1).."/"..(pageMax).."]"
    outTable[tl.config.displayLines] = pageNums
    paginatorState = paginatorState+1
    return concat(outTable, "\n")
  end
end

---Releases all keys currently locked/held down, called at the end of the script.
---@param there string
function tl.allUp(there)
  for _, va in pairs(tl.roDown[there]) do
    if va ~= nil then
      tl.putNoLCD("auto-released "..va)
      tl.release(va,0,nil,1)
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
      tl.press(obj,del,dev,fam,num)
      tl.wait(del or tl.config.keyDelay,dev)
    end
  end
end

---Releasing an array of buttons in order
---@param rayz string[]
---@param del number
---@param dev number
function tl.relRay(rayz,del,dev)
  tl.reverseTable(rayz)
  for i=1,#rayz do local obj = rayz[i]
    if type(obj) == "string" then
      tl.release(obj,nil,dev)
      tl.wait(del or tl.config.keyDelay,dev)
    end
  end
  tl.reverseTable(rayz)
end

---Outputs the first character of a string in lowercase.
---@param f string
function tl.token(f)
  if type(f)  ~= "string" then return false end
  return lower(sub(f,1,1))
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
  local kwt = kdel or tl.config.keyDelay
  if (#tstring == 1 or (sub(tstring,1,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(sub(tstring,2,3)) < 25)))) then
    tl.pressAndRelease(tstring,kwt,actionDeviator,keyDeviator,fam,num)
  else
    _typeString(tstring,del or tl.config.actionDelay,kwt,actionDeviator,keyDeviator,fam,num)
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
    tl.state[fam]["_b"..num] = (mode ~= nil and tl.state[fam]["_b"..num] ~=nil) and tl.state[fam]["_b"..num]..string or string
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
    local brokeRay = {}
    repeat
      needRepeat  = false
      for i = 1, #seppedRay do local obj = seppedRay[i]
        if #obj > num then
          local dex = 0
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[^%s]") do
            dex = dex+1
          end
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[%s]") do
            dex = dex+1
          end
          local sep = ""
          if (num-dex) == 1 then
            dex = 0
            if(not match(sub(obj,num,num),"[%s]"))then sep = "-" end
          end
          brokeRay[#brokeRay+1] = sub(obj,1,#obj-(num - dex - #sep))..sep
          brokeRay[#brokeRay+1] = sub(obj,#brokeRay[#brokeRay]- #sep)
        end
        if #brokeRay ~= 0 and #(brokeRay[#brokeRay]) > num then needRepeat = true end
      end
      seppedRay = #brokeRay ~= 0 and brokeRay or seppedRay
    until needRepeat == false
    str = concat(seppedRay,'\n')
    if #tl.splitter(str,"\n") > tl.config.displayLines then str = _paginator(str) end
    return str
  end
end