local rv = ... ---@type Revenant
local type, tonumber, sub, assert, error = type, tonumber, string.sub, assert, error

--[[=============================================================]] --
---@alias (exact) Coordinates {[1]:number,[2]:number} #first Position: X value, second position: Y value.
--[[=============================================================]] --
---@class (exact) UserCoordinates  #first Position: X value, second position: Y value. cen be pixels or percentages
---@field [1] integer|string
---@field [2]? integer|string
--[[=============================================================]] --
---@class (exact) DeskoptDefinition #The Option for Screen construction provided in the options
---@field [1] integer #Width in normal pixels
---@field [2] integer #Height in normal pixels
---@field topLeft? number[] #**Logitech** coordinates for the top left corner of the screen
---@field bottomRight? number[] #**Logitech** coordinates for the bottom right corner of the screen
---@field main? boolean #true if main monitor
--[[=============================================================]] --
---@class (exact) RectDefinition:UserCoordinates
---@field offset? integer|string|UserCoordinates #Offset from bottom right, if one number offset height will equal offset width
---@field o? integer|string|UserCoordinates #Shorthand for "offset"
---@field screen? integer #The screen the rectangle originates on
---@field exclude? boolean #Rectangle refers to everything outside of itself
--[[=============================================================]] --
---@class Rect #a rectangle, defining its area by corner coordinates.
---@field upperLeft Coordinates #Coordinates of the left corner
---@field lowerRight Coordinates #Coordinates of the right corner
--[[=============================================================]] --
--[[=============================================================]] --
---@class (exact) MovementPoint #Encodes a mouse movement based on normalized coordinates and a few options
---@field pos Coordinates #The normalized position to move to
---@field relative? boolean #If true the actual target position is the value of pos added to the current position.
---@field duration? integer #An individually set duration value for this movement.
---@field velocity? integer #An individually set velocity value for this movement.
--[[=============================================================]] --
---Contains information about a single monitor screen
---@class MonitorDefinition:BaseClass
---@field new fun(self:self,option: DeskoptDefinition, index:integer, isVirtual?: boolean)
---@field inclusionRects table<string, Rect[]>
---@field exclusionRects table<string, Rect[]>
---@field index integer
---@field movementPoints table<string,MovementPoint[]>
local MonitorDefinition = rv.baseClass:new()
---@protected
---@param option DeskoptDefinition #Definition to initialize Monitor definition with.
---@param index integer #Number of the monitor
---@param isVirtual? boolean #If true, this monitor uses virtual desktop coordinates
function MonitorDefinition:constructor(option, index, isVirtual)
   local limit = (2 ^ 16) - 1 -- 65535
   self.pixelWidth = option[1]
   self.pixelHeight = option[2]
   self.main = option.main
   self.index = index
   if isVirtual and (not option.topLeft or not option.bottomRight) then error("You need to provide normalized coordinates for mouse position and movement support across multiple monitors!") end

   self.isVirtual = isVirtual
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

   self.inclusionRects = {}
   self.exclusionRects = {}
   self.movementPoints = {}

   self.absolutePixel = isVirtual and self:pxToVirtual({1, 1}) or self:pxToNormal({1, 1})
end

---Check if a normalized or virtual coordinate is included in the screen space of this monitor
---@param val Coordinates
---@param virtual? boolean
---@return boolean
function MonitorDefinition:includes(val, virtual)
   local x, y = val[1], val[2]
   return x >= (virtual and self.xMinVirtual or self.xMinNormalized) and x <= (virtual and self.xMaxVirtual or self.xMaxNormalized) and y >= (virtual and self.yMinVirtual or self.yMinNormalized) and y <= (virtual and self.yMaxVirtual or self.yMaxNormalized)
end

---Add a logitech Rectanlge
---@param def RectDefinition
---@param id string
function MonitorDefinition:addRect(def, id)
   local store = def.exclude and self.exclusionRects[id] or self.inclusionRects[id]
   store[#store + 1] = self:getRect(def)
end

---Checks if the mouse is within a certain area.
---@param ar Rect
local function _areaCheck(ar, x, y) return (x >= ar.upperLeft[1]) and (x <= ar.lowerRight[1]) and (y >= ar.upperLeft[2]) and (y <= ar.lowerRight[2]) end

---Validate Rectangles computed for a specific macro.
---@param coords Coordinates
function MonitorDefinition:validateAreas(coords, id)
   local include, exclude = self.inclusionRects[id], self.exclusionRects[id]
   --- No areas defined for id => no restrictions
   if not include then return true end
   local posX, posY = coords[1], coords[2]
   -- If we're in ANY exclusion zones, return false.
   for i = 1, #exclude do if _areaCheck(exclude[i], posX, posY) then return false end end
   -- If we're in ANY exclusion zones, return true
   for i = 1, #include do if _areaCheck(include[i], posX, posY) then return true end end
   -- If we had exclusion zones, and none triggered then return false, but if there were only exclusion zones and none triggered, return true.
   return #include == 0
end

---Add one or more logitech Rectangles
---@param rectDef l<RectDefinition>
---@param id string
function MonitorDefinition:genRects(rectDef, id)
   self.inclusionRects[id] = self.inclusionRects[id] or {}
   self.exclusionRects[id] = self.exclusionRects[id] or {}
   if rectDef[1] and type(rectDef[1]) == "table" then ---@cast rectDef RectDefinition[]
      for i = 1, #rectDef do self:addRect(rectDef[i], id) end
   else ---@cast rectDef RectDefinition
      self:addRect(rectDef, id)
   end
end

---generate movement points for a macro
---@param val ExtendedCoordinates[]
---@param id string # A macro id
---@param relative? boolean
function MonitorDefinition:genPoints(val, relative, id)
   self.movementPoints[id] = self.movementPoints[id] or {}
   for i = 1, #val do
      local eco = val[i]
      local rel = relative
      if eco.r ~= nil then
         rel = eco.r
      elseif eco.relative ~= nil then
         rel = eco.relative
      end
      self.movementPoints[id][#self.movementPoints[id] + 1] = {relative = rel, pos = self:dynamicNormalizer(eco, not rel, rel), duration = eco.d or eco.duration, velocity = eco.v or eco.velocity}
   end
end

function MonitorDefinition:currentPosition()
   local x, y = GetMousePosition()
   if not self.isVirtual then return x, y end
   local virtualized = self:normalToVirtual({x, y}, true)
   return virtualized[1], virtualized[2]
end

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:dynamicPixels(val, abs) return self.isVirtual and self:virtualToPx(val, abs) or self:normalToPx(val, abs) end

---@param vals UserCoordinates
---@param abs? boolean
---@param noWrap? boolean
---@param noVirtual? boolean
---@return Coordinates
function MonitorDefinition:dynamicNormalizer(vals, abs, noWrap, noVirtual)
   local result = {0, 0}
   local needsVirtual = self.isVirtual and (not noVirtual)
   for i = 1, #vals do
      local target = vals[i]
      local isX = i == 1
      if type(target) == "string" then -- checking if the strings actually make sense
         local coordinate = assert(sub(target, -1) == "%" and tonumber(sub(target, 1, -2), 10), "\"" .. target .. "\" is not a valid coordinate value") -- handling percentages
         ---@cast coordinate integer
         if (not noWrap) and coordinate < 0 then coordinate = 100 + coordinate end
         local single = {isX and coordinate or 0, isX and 0 or coordinate}
         result[i] = (needsVirtual and self:percToVirtual(single, abs) or self:percToNormal(single, abs))[i]
      else
         if (not noWrap) and target < 0 then target = (isX and self.pixelWidth or self.pixelHeight) + target end
         local single = {isX and target or 0, isX and 0 or target}
         result[i] = (needsVirtual and self:pxToVirtual(single, abs) or self:pxToNormal(single, abs))[i]
      end
   end
   return {result[1], result[2]}
end

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:percToNormal(val, abs)
   return {
      rv.utils.linearTransform(val[1], 0, 100, (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth)), --
      rv.utils.linearTransform(val[2], 0, 100, (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight)) --
   }
end

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:percToVirtual(val, abs)
   return {
      rv.utils.linearTransform(val[1], 0, 100, (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth)), --
      rv.utils.linearTransform(val[2], 0, 100, (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight)) --
   }
end

---@param val Coordinates
---@return Coordinates
function MonitorDefinition:percToPx(val)
   return {
      (self.pixelWidth / 100) * val[1], --
      (self.pixelHeight / 100) * val[2] --
   }
end

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:pxToNormal(val, abs)
   return {
      rv.utils.linearTransform(val[1], 0, self.pixelWidth, (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth)), --
      rv.utils.linearTransform(val[2], 0, self.pixelHeight, (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight)) --
   }
end

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
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

---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:normalToVirtual(val, abs)
   return {
      rv.utils.linearTransform(val[1], (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth), (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth)), --
      rv.utils.linearTransform(val[2], (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight), (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight)) --
   }
end

---convert normalized units to pixels
---@param val Coordinates
---@param abs? boolean
---@return Coordinates
function MonitorDefinition:normalToPx(val, abs)
   return {
      rv.utils.linearTransform(val[1], (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth), 0, self.pixelWidth), --
      rv.utils.linearTransform(val[2], (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight), 0, self.pixelHeight) --
   }
end

---Convert normalized coordinates to screen percentagses
---@param val Coordinates
---@param abs? boolean #Are we asking which  specific percentile of the screen an absolute normalized coordinate is at, or how many percentages make up a number of normalized units?
---@return Coordinates
function MonitorDefinition:normalToPerc(val, abs)
   return {
      rv.utils.linearTransform(val[1], (abs and self.xMinNormalized or 0), (abs and self.xMaxNormalized or self.normalizedWidth), 0, 100), --
      rv.utils.linearTransform(val[2], (abs and self.yMinNormalized or 0), (abs and self.yMaxNormalized or self.normalizedHeight), 0, 100) --
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
      rv.utils.linearTransform(val[1], (abs and self.xMinVirtual or 0), (abs and self.xMaxVirtual or self.virtualWidth), 0, 100), --
      rv.utils.linearTransform(val[2], (abs and self.yMinVirtual or 0), (abs and self.yMaxVirtual or self.virtualHeight), 0, 100)
   }
end

---generate normalized coordinate rectangle from a Rectangle definition.\
---Rectangles tend to be exclusively used with checks against GetMousePosition,\
---so we never use virtual coordinates.
---@param def RectDefinition #Definition for our rectangle
---@return Rect #new Rectangle object in normalized coordinates
function MonitorDefinition:getRect(def)
   local offset = def.offset or def.o or 0
   if def[2] == nil then def[2] = def[1] end -- if only one value is provided, both size are equal
   if type(offset) ~= "table" then ---@cast offset string|number
      offset = {offset, offset}
   elseif offset[2] == nil then
      offset[2] = offset[1]
   end -- same for equal offsets

   local offsetCoordinates = self:dynamicNormalizer(offset, true, false, true)
   local sizeValues = self:dynamicNormalizer(def, false, nil, true)

   return {upperLeft = offsetCoordinates, lowerRight = {offsetCoordinates[1] + sizeValues[1], offsetCoordinates[2] + sizeValues[2]}}
end

---Converts non-standard sizes like negative pixels and percentages to normal pixels
---@param x integer|string #X pixel coordinate or percentage
---@param y integer|string #Y pixel coordinate or percentage
---@param noWrap? boolean #prevent coordinates from wrapping around
---@return integer, integer #Two numbers in actual pixels
function MonitorDefinition:convertToPixel(x, y, noWrap)
   local result = {0, 0}
   local vals = {x, y}
   for i = 1, #vals do
      local target = vals[i]
      local isX = i == 1
      if type(target) == "string" then -- checking if the strings actually make sense
         local coordinate = assert(sub(target, -1) == "%" and tonumber(sub(target, 1, -2), 10), "\"" .. target .. "\" is not a valid coordinate value") -- handling percentages
         ---@cast coordinate integer
         if (not noWrap) and coordinate < 0 then coordinate = 100 + coordinate end
         result[i] = (self:percToPx({isX and coordinate or 0, isX and 0 or coordinate}))[i]
      else
         if (not noWrap) and target < 0 then target = (isX and self.pixelWidth or self.pixelHeight) + target end
         result[i] = target
      end
   end
   return result[1], result[2]
end

return MonitorDefinition
