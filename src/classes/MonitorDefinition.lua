local tl = ...---@type MainLibObject
local MonitorDefinition = tl.baseClass:new()---@class MonitorDefinition:BaseClass

--TODO: Somehow offset and coordinates no longer work. 
---@protected
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
  self.logiScaleOffsetX = self.xPixel * self.scaleOffsetX
  self.logiScaleOffsetY = self.yPixel * self.scaleOffsetY
  self:refreshScale()
end

---@private
function MonitorDefinition:refreshScale()
  self.xPixel = self.xPixel * self.scale
  self.yPixel = self.yPixel * self.scale
  self.scaleOffsetX = self.w - (self.w / self.scale)
  self.scaleOffsetY = self.h - (self.h / self.scale)
end

---@param target MonitorDefinition
function MonitorDefinition:setScale(target)
  self.logiScaleOffsetX = target.xPixel * self.scaleOffsetX
  self.logiScaleOffsetY = target.yPixel * self.scaleOffsetY
  self.manualTop = self.topEdge
  self.manualRight = self.rightEdge
  self.noOffsetLocatorW = ((self.w / target.w) * 65535)
  self.locatorW = ((self.w - self.scaleOffsetX) / target.w) * 65535 * target.scale
  self.noOffsetLocatorH = ((self.h / target.h) * 65535)
  self.locatorH = ((self.h - self.scaleOffsetY) / target.h) * 65535 * target.scale
  self:refreshScale()
end
---@param lastMon MonitorDefinition
---@param mainMon MonitorDefinition
function MonitorDefinition:shiftLeft(lastMon,mainMon,align)
  if  self.manualRight then -- Dealing with left and right edges
      self.noOffsetRightEdge =   self.manualRight +   self.logiScaleOffsetX
  elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
      self.rightEdge = lastMon.leftEdge -   self.logiScaleOffsetX - mainMon.xPixel
      self.noOffsetRightEdge = lastMon.noOffsetLeftEdge
  elseif align == "left" then
      self.rightEdge =   self.locatorW
      self.noOffsetRightEdge =   self.noOffsetLocatorW
  elseif align == "right" then
      self.rightEdge = mainMon.locatorW
      self.noOffsetRightEdge = mainMon.noOffsetLocatorW
  elseif align == "vertical-center" then
      self.rightEdge = ((mainMon.locatorW -   self.locatorW -   self.logiScaleOffsetX) / 2) +   self.locatorW
      self.noOffsetRightEdge = ((mainMon.noOffsetLocatorW -   self.noOffsetLocatorW) / 2) +   self.noOffsetLocatorW
  end
    self.leftEdge =   self.rightEdge -   self.locatorW
    self.noOffsetLeftEdge =   self.noOffsetRightEdge -   self.noOffsetLocatorW

  if  self.manualTop then -- Dealing with top and bottom edges
      self.noOffsetTopEdge =   self.topEdge
  elseif align == "left" or align == "right" or align == "vertical-center" then --vertical alignments
      self.topEdge = lastMon.topEdge -   self.logiScaleOffsetY -   self.locatorH - mainMon.yPixel
      self.noOffsetTopEdge = lastMon.noOffsetTopEdge -   self.noOffsetLocatorH - mainMon.yPixel
  elseif align == "top" then
      self.topEdge = 0
      self.noOffsetTopEdge = 0
  elseif align == "bottom" then
      self.topEdge = (mainMon.bottomEdge -   self.locatorH -   self.logiScaleOffsetY)
      self.noOffsetTopEdge = (mainMon.noOffsetBottomEdge -   self.noOffsetLocatorH)
  elseif align == "center" then
      self.topEdge = (mainMon.locatorH -   self.locatorH) / 2
      self.noOffsetTopEdge = (mainMon.noOffsetLocatorH -   self.noOffsetLocatorH) / 2
  end
    self.bottomEdge =   self.topEdge +   self.locatorH
    self.noOffsetBottomEdge =   self.noOffsetTopEdge +   self.noOffsetLocatorH
end

---@param lastMon MonitorDefinition
---@param mainMon MonitorDefinition
function MonitorDefinition:shiftRight(lastMon,mainMon,align)
  if self.manualRight then
    self.noOffsetRightEdge = self.manualRight - self.logiScaleOffsetX
  elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
    self.rightEdge = lastMon.rightEdge + self.locatorW + mainMon.xPixel
    self.noOffsetRightEdge = lastMon.noOffsetRightEdge + self.noOffsetLocatorW + mainMon.xPixel
  elseif align == "left" then
    self.rightEdge = self.locatorW
    self.noOffsetRightEdge = self.noOffsetLocatorW
  elseif align == "right" then
    self.rightEdge = mainMon.locatorW
    self.noOffsetRightEdge = mainMon.noOffsetLocatorW
  elseif align == "vertical-center" then
    self.rightEdge = ((mainMon.locatorW - self.locatorW - self.logiScaleOffsetX) / 2) + self.locatorW
    self.noOffsetRightEdge = ((mainMon.noOffsetLocatorW - self.noOffsetLocatorW) / 2) + self.noOffsetLocatorW
  end
  self.leftEdge = self.rightEdge - self.locatorW - self.logiScaleOffsetX
  self.noOffsetLeftEdge = self.noOffsetRightEdge - self.noOffsetLocatorW

  if self.manualTop then -- Dealing with top and bottom edges
    self.noOffsetTopEdge = self.topEdge --Need to check if this works with scales moitors under the main one
  elseif align == "left" or align == "right" or align == "vertical-center" then -- vertical alignments
    self.topEdge = lastMon.bottomEdge + mainMon.yPixel
    self.noOffsetTopEdge = lastMon.noOffsetBottomEdge + mainMon.yPixel
  elseif align == "top" then
    self.topEdge = 0
    self.noOffsetTopEdge = 0
  elseif align == "bottom" then
    self.topEdge = (mainMon.bottomEdge - self.locatorH - self.logiScaleOffsetY)
    self.noOffsetTopEdge = (mainMon.noOffsetBottomEdge - self.noOffsetLocatorH)
  elseif align == "center" then
    self.topEdge = (mainMon.locatorH - self.noOffsetLocatorH) / 2
    self.noOffsetTopEdge = (mainMon.noOffsetLocatorH - self.noOffsetLocatorH) / 2
  end
  self.bottomEdge = self.topEdge + self.locatorH + self.logiScaleOffsetY
  self.noOffsetBottomEdge = self.topEdge + self.noOffsetLocatorH
end

return MonitorDefinition