local tl = ...---@type MainLibObject
local MonitorDefinition = tl.baseClass:new()---@class MonitorDefinition:BaseClass

local logiLimit = (2^16)-1 --65535

--TODO: Somehow offset and coordinates no longer work. 
---@protected
function MonitorDefinition:constructor(option)
  self.w = option[1]
  self.h = option[2]
  self.win = option.win
  self.ratio = (option[1] / option[2])
  self.offsetX =  (option.topLeft and option.topLeft[1]) or 0
  self.offsetY = (option.topLeft and option.topLeft[2]) or 0
end

function MonitorDefinition:contains(x,y)
  return (x >= self.offsetX) and (x <= self.offsetX + self.win.w)
  and (y >= self.offsetY) and (y <= self.offsetY + self.win.h)
end

function MonitorDefinition:getWinPixel(x,y)
  local newX = tl.helperUtils.linearTransform(x,0,self.w,0,self.win.w)
  local newY = tl.helperUtils.linearTransform(y,0,self.h,0,self.win.h)
  return self.offsetX+newX, self.offsetY+newY
end


return MonitorDefinition