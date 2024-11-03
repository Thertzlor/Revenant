local rv = ... ---@type Revenant
local type, tonumber, sub, assert = type, tonumber, string.sub, assert

--[[=============================================================]] --
---@alias Coordinates {[1]:number,[2]:number} #first Position: X value, second position: Y value.
--[[=============================================================]] --
---@class DeskoptDefinition #The Option for Screen construction provided in the options
---@field [1] integer #Width in normal pixels
---@field [2] integer #Height in normal pixels
---@field topLeft? Coordinates #**Logitech** coordinates for the top left corner of the screen
---@field bottomRight? Coordinates #**Logitech** coordinates for the bottom right corner of the screen
---@field main? boolean #true if main monitor
--[[=============================================================]] --
---@class RectDefinition
---@field size? integer|string|{[1]:string|integer,[2]:string|integer} #The size of the rectangle, if one number height will equal width
---@field s? integer|string|{[1]:string,[2]:string}|Coordinates #Shorthand for "size"
---@field offset? integer|string|{[1]:string,[2]:string}|Coordinates #Offset from bottom right, if one number offset height will equal offset width
---@field o? integer|string|{[1]:string,[2]:string}|Coordinates #Shorthand for "offset"
---@field screen? integer #The screen the rectangle originates on
---@field exclude? boolean #Rectangle refers to everything outside of itself
---@field private setAbsoluteSingle number
--[[=============================================================]] --
---@class Rect #a rectangle, defining its area by corner coordinates.
---@field cr Coordinates #Coordinates of the right corner
---@field cl Coordinates #Coordinates of the left corner
--[[=============================================================]] --
---Contains information about a single monitor screen
---@class MonitorDefinition:BaseClass
local MonitorDefinition = rv.baseClass:new()
---@protected
---@param option DeskoptDefinition #Definition to initialize Monitor definition with.
function MonitorDefinition:constructor(option)
   local limit = (2 ^ 16) - 1 -- 65535
   self.pixelWidth = option[1]
   self.pixelHeight = option[2]

   self.yMinVirtual = option.topLeft and option.topLeft[2] or 0
   self.yMaxVirtual = option.bottomRight and option.bottomRight[2] or limit
   self.xMinVirtual = option.topLeft and option.topLeft[1] or 0
   self.xMaxVirtual = option.bottomRight and option.bottomRight[1] or limit

   self.yMinNormalized = option.topLeft and option.topLeft[4] or 0
   self.yMaxNormalized = option.bottomRight and option.bottomRight[4] or limit
   self.xMinNormalized = option.topLeft and option.topLeft[3] or 0
   self.xMaxNormalized = option.bottomRight and option.bottomRight[3] or limit

   self.normalizedHeight = math.abs(self.yMinNormalized - self.yMaxNormalized)
   self.normalizedWidth = math.abs(self.xMinNormalized - self.xMaxNormalized)

   self.virtualHeight = math.abs(self.yMinVirtual - self.yMaxVirtual)
   self.virtualWidth = math.abs(self.xMinVirtual - self.xMaxVirtual)

   self.ratio = (option[1] / option[2])
   self.offsetX = (option.topLeft and option.topLeft[1]) or 0
   self.offsetY = (option.topLeft and option.topLeft[2]) or 0
   self.singleW = {self:getWinPixel(1, 1, true)} ---@type Coordinates
   self.singleL = {0, 0}
end

function MonitorDefinition:setAbsoluteSingle() self.singleL = {rv.mouseMonitorUtils:virtualTransform(self.singleW[1], self.singleW[2])} end

---Receives an absolute virtual **windows** units and outputs whether they are loacted within the monitor's boundaries
---@param x number #X coordinate
---@param y number #Y coordinate
---@return boolean #true if the coordinates are on this monitor
function MonitorDefinition:contains(x, y) return (x >= self.offsetX) and (x <= self.offsetX + self.pixelWidth) and (y >= self.offsetY) and (y <= self.offsetY + self.pixelHeight) end

---Check if a normalized or virtual coordinate is included in the screen space of this monitor
---@param val Coordinates
---@param virtual? boolean
---@return boolean
function MonitorDefinition:includes(val, virtual)
   local x, y = val[1], val[2]
   return x >= (virtual and self.xMinVirtual or self.xMinNormalized) and x <= (virtual and self.xMaxVirtual or self.xMaxNormalized) and y >= (virtual and self.yMinVirtual or self.yMinNormalized) and y <= (virtual and self.yMaxVirtual or self.yMinNormalized)
end

function MonitorDefinition:percToNormal() end
function MonitorDefinition:percToVirtual() end
function MonitorDefinition:percToPx() end

function MonitorDefinition:pxToNormal() end
function MonitorDefinition:pxToVirtual(val, abs)
   return {
      rv.utils.linearTransform(val[1], 0, self.pixelWidth, (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth)), --
      rv.utils.linearTransform(val[2], 0, self.pixelHeight, (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight)) --
   }
end

---Convert a pixel coordinate to a percentage coordinate.\
---There is no absolute mode for this conversion.
---@param val Coordinates
---@return Coordinates
function MonitorDefinition:pxToPerc(val)
   return {
      (val[1] / self.pixelWidth) * 100, --
      (val[2] / self.pixelHeight) * 100
   }
end

function MonitorDefinition:normalToVirtual() end
function MonitorDefinition:normalToPx() end

---Convert normalized coordinates to screen percentagses
---@param val Coordinates
---@param abs? boolean #Are we asking which  specific percentile of the screen an absolute normalized coordinate is at, or how many percentages make up a number of normalized units?
---@return Coordinates
function MonitorDefinition:normalToPerc(val, abs)
   return {
      (val[1] / (abs and self.xMaxNormalized or self.normalizedWidth)) * 100, --
      (val[2] / (abs and self.yMaxNormalized or self.normalizedHeight)) * 100
   }
end

---Virtual to normalized pixels
---@param val Coordinates #The source coordinates
---@param abs? boolean #Are we asking what virtual coordinates are at an absolute normalized coordinate how or many normalized units correspond to a number of virtual units?
---@return Coordinates
function MonitorDefinition:virtualToNormal(val, abs)
   return {
      rv.utils.linearTransform(val[1], (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth), (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth)), --
      rv.utils.linearTransform(val[2], (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight), (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight)) --
   }
end

---Virtual to real pixels
---@param val Coordinates
---@param abs? boolean # Are we asking how many pixels into the screen an absolute virtual coordinate is or to how many pixels some amount of virtual units corresponds?
---@return Coordinates
function MonitorDefinition:virtualToPx(val, abs)
   return {
      rv.utils.linearTransform(val[1], (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth), 0, self.pixelWidth), --
      rv.utils.linearTransform(val[2], (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight), 0, self.pixelHeight)
   }
end

---Convert virtual coordinates to screen percentagses
---@param val Coordinates
---@param abs? boolean #Are we asking which absolute virtual coordinates are at at a specific percentile of the screen, or how many normalized units fit into a number of percents?
---@return Coordinates
function MonitorDefinition:virtualToPerc(val, abs)
   return {
      (val[1] / (abs and self.xMaxVirtual or self.virtualWidth)) * 100, --
      (val[2] / (abs and self.yMaxVirtual or self.virtualHeight)) * 100
   }
end

---generate logitech coordinate rectangle from a Rectangle definition
---@param def RectDefinition #Definition for our rectangle
---@return Rect #new Rectangle object on this monitor space
function MonitorDefinition:getRect(def)
   local offset = def.offset or def.o or 0
   local size = def.size or def.s or "100%"
   if type(size) ~= "table" then
      size = {size, size}
   elseif size[2] == nil then
      size[2] = size[1]
   end -- if only one value is provided, both size are equal
   if type(offset) ~= "table" then
      offset = {offset, offset}
   elseif offset[2] == nil then
      offset[2] = offset[1]
   end -- same for equal offsets
   local oX, oY = self:convertToPixel(offset[1], offset[2])
   local sX, sY = self:convertToPixel(size[1], size[2])
   local absOffsetX, absOffsetY = self:getWinPixel(oX, oY)
   local absSizeX, absSizeY = self:getWinPixel(oX + sX, oY + sY)
   return {cl = {absOffsetX, absOffsetY}, cr = {absSizeX, absSizeY}}
end

---Converts non-standard sizes like negative pixels and percentages to absolute normal pixels
---@param x integer|string #X coordinate or percentage
---@param y integer|string #Y coordinate or percentage
---@param noWrap? boolean #prevent coordinates from wrapping around
---@return integer, integer #Two numbers in actual pixels
function MonitorDefinition:convertToPixel(x, y, noWrap)
   local result = {0, 0}
   for i = 1, 2 do
      local target = ({{x, self.pixelWidth}, {y, self.pixelHeight}})[i]
      local t1 = target[1]
      if type(t1) == "string" then -- checking if the strings actually make sense
         local coordinate = assert(sub(t1, -1) == "%" and tonumber(sub(t1, 1, -2), 10), "\"" .. t1 .. "\" is not a valid coordinate value") -- handling percentages
         t1 = target[2] * (coordinate / 100)
      end
      if (not noWrap) and t1 < 0 then t1 = target[2] + t1 end
      result[i] = t1
   end
   return result[1], result[2]
end

---Converts actual pixels or percentage values into *absolute* virtual **windows** units
---@param x integer #X coordinate
---@param y integer #Y coordinate
---@param relative? boolean #Relative values don't contain any offset
---@return integer,integer #windows pixel values
function MonitorDefinition:getWinPixel(x, y, relative)
   local newX = rv.utils.linearTransform(x, 0, self.pixelWidth, 0, self.pixelWidth)
   local newY = rv.utils.linearTransform(y, 0, self.pixelHeight, 0, self.pixelHeight)
   if relative then return newX, newY end
   return self.offsetX + newX, self.offsetY + newY
end

return MonitorDefinition
