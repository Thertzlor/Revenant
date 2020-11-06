local tl = ...---@type MainLibObject
local lower, match, sub, type,concat, pairs,find,ceil,tonumber,OutputLCDMessage,ClearLCD =
tl.utf8.lower, tl.utf8.match, tl.utf8.sub, type,table.concat,pairs,tl.utf8.find,math.ceil,tonumber,OutputLCDMessage,ClearLCD
local cachedString, paginatorState
--================================================================
local DisplayStateModule = tl.baseClass:new()---@class DisplayStateModule:BaseClass Functions that control coroutines

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
  if num == 0 or #str < num then
    return str
  else
    local needRepeat  = false
    local seppedRay = tl.helperUtils.splitter(str,"\n")
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
    if #tl.helperUtils.splitter(str,"\n") > tl.activeProfile.config.displayLines then str = _paginator(str) end
    return str
  end
end

---Outputs messages to the Logitech LCD display
---Includes formatters for paginating and splitting.
---@private
---@param msg string
---@param dur number
function DisplayStateModule:putLCD(msg, dur) --Outputs messages to lua log
  local deviceState,config = tl.activeProfile.deviceState,tl.activeProfile.config
  if not config.outputLCD then return false end
  local duration = dur or config.persistLCD
  if not config.outputLCD then return end
  if config.clearLCD then ClearLCD()
    if config.keepNameOnLCD then
      local modeState = ""
      if tl.scriptStates.modeUsed == 1 then
        if config.defaultModeTarget == "join" then
          modeState = " Mode " .. deviceState.m.modus
        else
          for g = 1, #tl.stringPresets.families do local l = tl.stringPresets.families[g]
            local tok = tl.str:token(l)
            if deviceState[tok].buttonCount ~= 0 and deviceState[tok].modeCount > 1 then
              modeState = modeState.."," .. self.unToken[tok] .. " Mode: "
              if deviceState[tok].modeConfig[deviceState[tok].modus] then modeState = modeState..deviceState[tok].modeConfig[deviceState[tok].modus][1]
              else modeState = modeState .. deviceState[tok].modus
              end
            end
          end
        end
      end
      OutputLCDMessage(_stringBreaker(tl.activeProfile.name .. modeState, config.charsPerLine))
    end
  end
  OutputLCDMessage(_stringBreaker(msg, config.charsPerLine), duration)
  for _ = 1, config.appendNewLines do OutputLCDMessage("", duration) end
end


return DisplayStateModule