local rv = ... ---@type Revenant
local type, tonumber, sub, assert = type, tonumber, string.sub, assert

--[[=============================================================]] --
---@alias Coordinates {[1]:integer,[2]:integer} #first Position: X value, second position: Y value.
--[[=============================================================]] --
---@class DeskoptDefinition #The Option for Screen construction provided in the options
---@field win {h:integer,w:integer} #Screen resolution in normal pixels
---@field topLeft? Coordinates #**Logitech** coordinates for the top left corner of the screen
--[[=============================================================]] --
---@class RectDefinition
---@field size? integer|string|{[1]:string|integer,[2]:string|integer} #The size of the rectangle, if one number height will equal width
---@field s? integer|string|{[1]:string,[2]:string}|Coordinates #Shorthand for "size"
---@field offset? integer|string|{[1]:string,[2]:string}|Coordinates #Offset from bottom right, if one number offset height will equal offset width
---@field o? integer|string|{[1]:string,[2]:string}|Coordinates #Shorthand for "offset"
---@field screen? integer #The screen the rectangle originates on
---@field exclude? boolean #Rectangle refers to everything outside of itself
--[[=============================================================]] --
---@class Rect #a rectangle, defining its area by corner coordinates.
---@field cr Coordinates #Coordinates of the right corner
---@field cl Coordinates #Coordinates of the left corner
--[[=============================================================]] --
---@class MonitorDefinition:BaseClass #Contains information about a single monitor screen
local MonitorDefinition = rv.baseClass:new()
---@protected
---@param option Coordinates|DeskoptDefinition #Definition to initialize Monitor definition with.
function MonitorDefinition:constructor(option)
   self.w = option[1]
   self.h = option[2]
   self.win = option.win
   self.ratio = (option[1] / option[2])
   self.offsetX = (option.topLeft and option.topLeft[1]) or 0
   self.offsetY = (option.topLeft and option.topLeft[2]) or 0
   self.singleW = {self:getWinPixel(1, 1, true)} ---@type Coordinates
   self.singleL = {0, 0}
end

function MonitorDefinition:setAbsoluteSingle() self.singleL = {rv.mouseMonitorUtils:virtualTransform(self.singleW[1], self.singleW[2])} end

---Receives an absolute virtual **windows** units and outputs whether they are sloacted within the monitor's boundaries
---@param x number #X coordinate
---@param y number #Y coordinate
---@return boolean #true if the coordinates are on this monitor
function MonitorDefinition:contains(x, y) return (x >= self.offsetX) and (x <= self.offsetX + self.win.w) and (y >= self.offsetY) and (y <= self.offsetY + self.win.h) end

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
      local target = ({{x, self.w}, {y, self.h}})[i]
      local t1 = target[1]
      if type(t1) == "string" then -- checking if the strings actually make sense
         local coordinate = assert(sub(t1, -1) == "%" and tonumber(sub(t1, 1, -2), 10), "\"" .. t1 .. "\" is not a valid coordinate value") -- handling percentages
         t1 = target[2] * (coordinate / 100) --[[@as integer]]
      end
      if (not noWrap) and target[1] < 0 then t1 = target[2] + t1 end
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
   local newX = rv.utils.linearTransform(x, 0, self.w, 0, self.win.w)
   local newY = rv.utils.linearTransform(y, 0, self.h, 0, self.win.h)
   if relative then return newX, newY end
   return self.offsetX + newX, self.offsetY + newY
end

return MonitorDefinition
