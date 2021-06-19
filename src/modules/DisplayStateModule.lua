local tl = ...---@type MainLibObject
local lower, match, sub, type,concat, pairs,find,ceil,tonumber,OutputLCDMessage,ClearLCD =
tl.utf8.lower, tl.utf8.match, tl.utf8.sub, type,table.concat,pairs,tl.utf8.find,math.ceil,tonumber,OutputLCDMessage,ClearLCD
local cachedString, paginatorState

local stringRay = {
  ["-"]=1.7,--57
  ["("]=1.7,--57
  [")"]=1.7,--57
  ["{"]=1.7,--57
  ["?"]=3.1,
  ["}"]=1.7,--57
  ["."]=1.4,--71
  ["!"]=1.4,--71
  ["["]=1.4,--71
  ["]"]=1.4,--71
  [","]=1.4,
  [":"]=1.4,
  [";"]=1.4,
  ["'"]=1,
  ['"']=2,
  ["*"]=2,
  ["#"]=3.1,
  ["+"]=3.1,
  ["_"]=3.1,
  ["0"] = 3.1,--31
  ["1"] = 3.1,--31
  ["2"] = 3.1,--31
  ["3"] = 3.1,--31
  ["4"] = 3.1,--31
  ["5"] = 3.1,--31
  ["6"] = 3.1,--31
  ["7"] = 3.1,--31
  ["8"] = 3.1,--31
  ["9"] = 3.1,--31
  a=3.1, --31
  b=3.1, --31
  c=2.8, --35
  d=3.1, --31
  e=3.1, --31
  f=1.7,--57
  g=3.1, --31
  h=3.1, --31
  i=1, --95
  j=1, --95
  k=2,8,--35
  l=1, --95
  m=4.4,--22
  n=3.1, --31
  o=3.1, --31
  p=3.1, --31
  q=3.1, --31
  r=1.7,--57
  t=1.7,--57
  s=2,8,--35
  w=3.7,--26
  u=3.1, --31
  v=2,4, --40
  x=2,4, --40
  y=2.4, --31
  z=2.8, --35
  A=3.7, --26
  B=3.7, --26
  C=3.7, --26
  D=4.2, --23
  E=3.7, --26
  F=3.4, --28
  G=4.3, --22
  H=4.2,
  I=1.7,--57
  J=2.8, --35
  K=3.4, --28
  L=3.1, --31
  M=4.4, --22
  N=3.7, --26
  O=4.2, --28
  P=3.4, --28
  Q=4.2, --28
  R=4.2, --28
  S=3.7,
  T=3.1,
  U=4.2, --23,
  V=3.7,
  W=5,--19
  X=3.7,
  Y=3.7,
  Z=3.4,
}


local DisplayStateModule = tl.baseClass:new()---@class DisplayStateModule:BaseClass Manages the state of the LCD display

---intelligently divide text into multiple pages for display on LCD screen
---@param str string
local function _paginator(str)
  local config = tl.activeProfile.config
  if str ~= cachedString then
    paginatorState = 0
    cachedString = str
  end
  local sep = tl.helperUtils.splitter(str,"\n");
  if tl.activeProfile.config.displayLines == 0 or #sep <= config.displayLines then
    return concat(sep,'\n')
  else
    local pageMax = ceil(#sep/(config.displayLines-1))
    if paginatorState == pageMax then paginatorState = 0 end
    local outTable = {}
    for k = config.displayLines*(paginatorState), (config.displayLines*(paginatorState))+config.displayLines-1 do
     if k~=0 then outTable[#outTable+1] = sep[k] or "" end
    end
    local pageNums = "["..(paginatorState+1).."/"..(pageMax).."]"
    outTable[config.displayLines] = pageNums
    paginatorState = paginatorState+1
    return concat(outTable, "\n")
  end
end

---intelligently breaks tring for display on LCD screen.
---@param str string
---@param num number
---@return string
local function _stringBreaker(str,num)
  if num == 0 or #str < num then return str else
    local needRepeat  = false
    local seppedRay = tl.helperUtils.splitter(str,"\n")
    local brokeRay = {}
    repeat
      needRepeat  = false
      for i = 1, #seppedRay do local obj = seppedRay[i]
        if #obj > num then
          local dex = 0
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[^%s]") do dex = dex+1 end
          while (num-dex) > 1 and match(sub(obj,(num-dex),(num-dex)),"[%s]") do dex = dex+1 end
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
    if #tl.helperUtils.splitter(str,"\n") > tl.activeProfile.config.displayLines then str = _paginator(str) end
    return str
  end
end

---@param str string
local function _stringbreakerNew(str)
  str = tl.str:separate(str)
  local lineMax =47
  local currentLine = 0
  local cursor = 1
  local lastLineStart = 1
  local lineRay = {}
  for i = 1, #str do local s = str[i]
    local addition = (stringRay[s] or 3)
    currentLine = currentLine + (addition)
    if i == #str then lineRay[#lineRay+1] = concat(str,"",lastLineStart,i)
    elseif match(s,"\n") or match(s,"\r") then
      currentLine = 0
      lineRay[#lineRay+1] = concat(str,"",lastLineStart,i-1)
      while match(str[i+1],"%s") do i = i+1 end
      lastLineStart = i+1
    elseif currentLine < lineMax then 
      cursor = i
    else
      currentLine = 0
      cursor = i
      lineRay[#lineRay+1] = concat(str,"",lastLineStart,cursor)
      while match(str[i+1],"%s") do i = i+1 end
      lastLineStart = i+1
    end
  end
  return lineRay
end

---Outputs messages to the Logitech LCD display
---Includes formatters for paginating and splitting.
---@private
---@param msg string
---@param dur number
function DisplayStateModule:putLCD(msg, dur) --Outputs messages to lua log
  local deviceState,config = tl.activeProfile.deviceState,tl.activeProfile.config
  -- if not config.outputLCD then return false end
  local duration = dur or config.persistLCD
  -- if not config.outputLCD then return end
  -- if config.clearLCD then ClearLCD()
  --   if config.keepNameOnLCD then
  --     local modeState = ""
  --     if tl.scriptStates.modeUsed == 1 then
  --       if config.defaultModeTarget == "join" then modeState = " Mode " .. deviceState.m.modus else
  --         for g = 1, #tl.stringPresets.families do local l = tl.stringPresets.families[g]
  --           local tok = tl.str:token(l)
  --           if deviceState[tok].buttonCount ~= 0 and deviceState[tok].modeCount > 1 then
  --             modeState = modeState.."," .. self.unToken[tok] .. " Mode: "
  --             if deviceState[tok].modeConfig[deviceState[tok].modus] then 
  --               modeState = modeState..deviceState[tok].modeConfig[deviceState[tok].modus][1]
  --             else modeState = modeState .. deviceState[tok].modus
  --             end
  --           end
  --         end
  --       end
  --     end
  --     OutputLCDMessage(_stringBreaker(tl.activeProfile.name .. modeState, config.charsPerLine))
  --   end
  -- end
  local broken = _stringbreakerNew(msg)
  for i = 1, #broken do 
    OutputLCDMessage(broken[i], duration)
  end
  for _ = 1, config.appendNewLines do OutputLCDMessage("", duration) end
end

return DisplayStateModule