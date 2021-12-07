local tl = ...---@type MainLibObject
local MonitorDefinition = tl.baseClass:new()---@class MonitorDefinition:BaseClass

local logiLimit = (2^16)-1 --65535

--TODO: Somehow offset and coordinates no longer work. 
---@protected
function MonitorDefinition:constructor(option,offsets,logiPix,scale)
  self.w = option[1]
  self.h = option[2]
  self.scale = scale or 1
  self.ratio = (option[1] / option[2])
  self.offsetX = offsets[1]
  self.offsetY = offsets[2]
  self.pScaleX = (self.w*self.scale)/logiPix[1]
  self.pScaleY = (self.h*self.scale)/logiPix[2]
end

function MonitorDefinition:getNormalized(x,y)
  return (self.offsetX + (x/self.pScaleX)),
  (self.offsetY + (y/self.pScaleY))
end


return MonitorDefinition