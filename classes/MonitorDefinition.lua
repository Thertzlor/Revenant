---@type MainLibObject
local tl,Base = ...

---@class MonitorDefinition
local MonitorDefinition = Base:new()
function MonitorDefinition:constructor(option,num)
   self.w = option[1]
   self.h = option[2]
   self.ratio = (option[1] / option[2])
   self.scale = (option.scale or 100) / 100
   self.xPixel = (65535 / option[1]) * ((option.scale or 100) / 100)
   self.yPixel = (65535 / option[2]) * ((option.scale or 100) / 100)
   self.scaleOffsetX = 0
   self.scaleOffsetY = 0
   self.logiScaleOffsetX = 0
   self.logiScaleOffsetY = 0
   self.main = 1
   self.pos = num or 1
   self.manualTop = nil
   self.manualRight = nil
   self.locatorW = 65535
   self.locatorH = 65535
   self.topEdge = 0
   self.rightEdge = 65535
   self.leftEdge = 0
   self.bottomEdge = 65535
   self.noOffsetLocatorW = 65535
   self.noOffsetLocatorH = 65535
   self.noOffsetTopEdge = 0
   self.noOffsetRightEdge = 65535
   self.noOffsetLeftEdge = 0
   self.noOffsetBottomEdge = 65535
   self.virtualW = 65535
   self.virtualH = 65535
   self.virtualTopEdge = 0
   self.virtualRightEdge = 65535
   self.virtualLeftEdge = 0
   self.virtualBottomEdge = 65535

   self.xPixel = self.xPixel * self.scale
   self.yPixel = self.yPixel * self.scale
   self.scaleOffsetX = self.w - (self.w / self.scale)
   self.scaleOffsetY = self.h - (self.h / self.scale)
   self.logiScaleOffsetX = self.xPixel * self.scaleOffsetX
   self.logiScaleOffsetY = self.yPixel * self.scaleOffsetY
end


return MonitorDefinition