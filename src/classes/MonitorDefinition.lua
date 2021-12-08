local tl = ...---@type MainLibObject
local MonitorDefinition = tl.baseClass:new()---@class MonitorDefinition:BaseClass

local type,tonumber,error,sub = type,tonumber,error,string.sub

---@protected
function MonitorDefinition:constructor(option)
  self.w = option[1]
  self.h = option[2]
  self.win = option.win
  self.ratio = (option[1] / option[2])
  self.offsetX =  (option.topLeft and option.topLeft[1]) or 0
  self.offsetY = (option.topLeft and option.topLeft[2]) or 0
end

---Receives an absolute virtual **windows** units and outputs whether they are sloacted within the monitor's boundaries
---@param x number
---@param y number
function MonitorDefinition:contains(x,y)
  return (x >= self.offsetX) and (x <= self.offsetX + self.win.w)
  and (y >= self.offsetY) and (y <= self.offsetY + self.win.h)
end

function MonitorDefinition:getRect(def)
  local offset = def.offset or {0,0}
  local size = def.size or {"100%","100%"}
  if size[2] == nil then size[2] = size[1] end
  if offset[2] == nil then offset[2] = offset[1] end
  local oX,oY = self:convertToPixel(offset[1],offset[2])
  local sX,sY = self:convertToPixel(size[1],size[2])
  local absetX,absetY = self:getWinPixel(oX,oY)
  local absizeX,absizeY = self:getWinPixel(oX+sX,oY+sY)
  return {cl={absetX,absetY},cr={absizeX,absizeY}}
end

---Converts non-standard sizes like negative pixels and percentages to absolute normal pixels
---@param x number|string
---@param y number|string
---@return number,number
function MonitorDefinition:convertToPixel(x,y)
  local result = {0,0}
  for i = 1, 2 do local target = ({{x,self.w},{y,self.h}})[i]
    if type(target[1]) == "string" then
      local coNum = sub(target[1],-1) == "%" and tonumber(sub(target[1],1,-2),10)
      if not coNum then error('"'..target[1]..'" is not a valid coordinate value') end
      target[1] = target[2]*(coNum/100)
    end
    if target[1] < 0 then target[1] = target[2]+target[1] end
    result[i] = target[1]
  end
  return result[1],result[2]
end

---Converts actual pixels or percentage values into *absolute* virtual **windows** units
---@param x number|string
---@param y number|string
function MonitorDefinition:getWinPixel(x,y)
  x,y = self:convertToPixel(x,y)
  local newX = tl.helperUtils.linearTransform(x,0,self.w,0,self.win.w)
  local newY = tl.helperUtils.linearTransform(y,0,self.h,0,self.win.h)
  return self.offsetX+newX, self.offsetY+newY
end

return MonitorDefinition