local rv = ... ---@type Revenant
local abs, GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, type, running, MoveMouseRelative, error, next, sqrt, floor, pcall, ceil, min, max = math.abs, GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, type, coroutine.running, MoveMouseRelative, error, next, math.sqrt, math.floor, pcall, math.ceil, math.min, math.max
-- local currentSample, mouseCount
local MonitorDefinition = rv.importer:classImport("MonitorDefinition")

--[[=============================================================]] --
---Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.
---@class MouseCoordinatesModule:BaseClass
local MouseCoordinatesModule = rv.baseClass:new()
local limit = (2 ^ 16) - 1 -- 65535
local firstMove = true
local lagMultiplier = 1
local averageLag = 0
local lagSampleCount = 0
local maxMovementLagSamples = 100
local offsetLag = true
local lagThreshold = 1000

---@protected
function MouseCoordinatesModule:constructor()
   self.screens = {} ---@type MonitorDefinition[]
   self.enabledOn = {} ---@type table<string,table<number,boolean>>
   self.mainScreen = 1
   self.moveFunction = MoveMouseTo ---@type fun(x:integer, y:integer)
   self.interval = 2
end

---calculate coordinate Data for all screens
---@param origin l<DeskoptDefinition>
function MouseCoordinatesModule:compileScreenCoordinates(origin)
   if not origin[1] then return end

   local restricted = rv.profile.config.restrictToMainScreen

   self.interval = rv.profile.config.pollInterval
   lagMultiplier = rv.profile.config.defaultLagFactor
   local multiMonitor = type(origin[1]) == "table" -- there might only be one monitor
   if multiMonitor then ---@cast origin DeskoptDefinition[]
      if #origin == 1 then
         origin[1].main = true
         self.screens[#self.screens + 1] = MonitorDefinition:new(origin[1])
      else
         if not restricted then self.moveFunction = MoveMouseToVirtual end
         for i = 1, #origin do
            local monitor = origin[i]
            if monitor.main then self.mainScreen = i end
            self.screens[#self.screens + 1] = MonitorDefinition:new(monitor, not restricted)
         end
      end
   else
      origin.main = true
      self.screens[#self.screens + 1] = MonitorDefinition:new(origin --[[@as DeskoptDefinition]] )
   end
end

---Check which monitor the coordinates are on. Accepts normalized or virtual coordinates
---@param x number
---@param y number
---@param virtual? boolean
function MouseCoordinatesModule:getMonitorNo(x, y, virtual)
   for i = 1, #self.screens do if self.screens[i]:includes({x, y}, virtual) then return i end end
   return false
end

---Check if a specific monitor contains the given coordinates
---@param i number
---@param x number
---@param y number
---@param v? boolean
function MouseCoordinatesModule:onMonitor(i, x, y, v) return self.screens[i]:includes({x, y}, v) end

---wrapper for the previously broken MoveMouseRelative() function
---@param x integer
---@param y integer
---@return  nil
function MouseCoordinatesModule:relativeMouse(x, y)
   if x == nil then return end
   local movedX = 0
   local movingX = 0
   local movedY = 0
   local movingY = 0
   y = y or 0
   while movedX ~= x or movedY ~= y do -- the original function only works with less than 128 pixels, hence the loop
      movingX = x - movedX
      movingY = y - movedY
      if abs(movingX) > 127 then
         movingX = 127
         if x < 0 then movingX = movingX * -1 end
      end
      if abs(movingY) > 127 then
         movingY = 127
         if y < 0 then movingY = movingY * -1 end
      end
      MoveMouseRelative(movingX, movingY) -- calling the actual function with clamped values
      movedX = movedX + movingX
      movedY = movedY + movingY
   end
end

---@param arg Coordinates
function MouseCoordinatesModule:relativeWrapper(arg)
   local x, y = arg[1], arg[2]
   if x == nil then return end
   self:relativeMouse(x, y)
end

function MouseCoordinatesModule:initLagSettings()
   offsetLag = rv.profile.config.offsetMovementLag
   lagThreshold = rv.profile.config.lagPositionThreshold
   maxMovementLagSamples = rv.profile.config.maxMovementLagSamples
end

---@private
---@param x number
---@param y number
---@param baseX number
---@param baseY number
---@param destX number
---@param destY number
---@param steps number
---@async
function MouseCoordinatesModule:moveFor(x, y, baseX, baseY, destX, destY, steps)
   local func = self.rawMove
   local int = self.interval
   local checkTime = GetRunningTime()
   local now = checkTime
   local bx = baseX or 0
   local by = baseY or 0
   for _ = 1, floor(steps / lagMultiplier) do
      func(self, (bx + (x * lagMultiplier)), (by + (y * lagMultiplier)))
      bx = bx + (x * lagMultiplier)
      by = by + (y * lagMultiplier)
      if offsetLag then
         now = GetRunningTime()
         averageLag = averageLag + ((now - checkTime) / int)
         lagSampleCount = lagSampleCount + 1
         checkTime = now
         if firstMove and abs(bx - destX) < lagThreshold then
            rv.threading:wait(int)
            break
         end
      end
      rv.threading:wait(int)
   end
   lagMultiplier = averageLag / lagSampleCount
   self:rawMove(destX, destY)
   firstMove = false
   if offsetLag and lagSampleCount % maxMovementLagSamples then
      averageLag = averageLag / 100
      lagSampleCount = 1
   end
   return -1
end

---wrapper for posivite or negative areaChecks.
---@param arg l<RectDefinition>
---@param id string
function MouseCoordinatesModule:areaCheckWrapper(arg, id)
   ---If there are no screens or areas there's no restriction.
   if #self.screens == 0 or not next(arg) then return true end
   local posX, posY = GetMousePosition(); -- getting the mouse position
   local screenIndex = self:getMonitorNo(posX, posY)
   --- There cannot be a restriction outside registered screens.
   if not screenIndex then return true end
   --- This constellation means that the macro is restricted to an area on another screen.
   if self.enabledOn[id] and not self.enabledOn[id][screenIndex] then return false end
   return self.screens[screenIndex]:validateAreas({posX, posY}, id)
end

---@param arg l<RectDefinition>
function MouseCoordinatesModule:parseRectangles(arg, id)
   if #self.screens == 0 or not next(arg) then return end
   ---@type RectDefinition[]
   local defTab = (arg[1] and type(arg[1]) == "table") and arg or {arg}
   for i = 1, #defTab do defTab[i].screen = (defTab[i].screen or self.mainScreen) end
   --- if we are restricted to the main screen, we only parse rectangles for the main screen.
   local screenTab = rv.profile.config.restrictToMainScreen and {self.screens[self.mainScreen]} or self.screens
   for i = 1, #screenTab do
      local mon = screenTab[i]
      local filteredDefs = rv.tbl:propFilter(defTab, "screen", i)
      for j = 1, #filteredDefs do
         if not filteredDefs[j].exclude then
            if not self.enabledOn[id] then
               self.enabledOn[id] = {[i] = true}
            else
               self.enabledOn[id][i] = true
            end
         end
      end
      if next(filteredDefs) then mon:genRects(filteredDefs, id) end
   end
end

---not implemented yet
function MouseCoordinatesModule:mouseVelocity() end

function MouseCoordinatesModule:rawMove(x, y) pcall(self.moveFunction, x, y) end

---Sanitizing potentially out of bounds coordinates.
---@param coordinate number
---@return number
function MouseCoordinatesModule:clamp(coordinate) return min(limit, max(0, coordinate)) end

---Main function for moving the mouse instantly or over time
---@param options _MousePositionOptions
---@param pID string
---@async
function MouseCoordinatesModule:mouseMoveWrapper(options, pID)
   local screen = self.screens[options.screen]
   local points = screen.movementPoints[pID]
   local pixelSize = screen.absolutePixel
   local velo = options.velocity
   local dura = options.duration
   if not next(points) then return end
   local currentX, currentY = screen:currentPosition()
   for i = 1, #points do
      local point = points[i]
      local coords = point.pos
      local targetX, targetY = coords[1], coords[2]
      if options.relative then
         targetX, targetY = self:clamp(currentX + targetX), self:clamp(currentY + targetY)
      else
         targetX, targetY = self:clamp(coords[1]), self:clamp(coords[2])
      end
      if (not (dura or point.duration)) and (not (velo or point.velocity)) then
         self:mouseMove({targetX, targetY})
      else
         local distanceX, distanceY = (targetX - currentX), (targetY - currentY)
         local numStep = 0
         local speedCalc = options.velocity and "v" or "d"
         if speedCalc == "v" and point.duration then
            speedCalc = "d"
         elseif speedCalc == "d" and point.velocity then
            speedCalc = "v"
         end
         if speedCalc == "v" then
            local pixelDistance = sqrt(((distanceX / pixelSize[1]) ^ 2) + ((distanceY / pixelSize[2]) ^ 2))
            local time = floor((pixelDistance / (point.velocity or velo)) * (1000))
            numStep = ceil(time / self.interval)
         else
            numStep = (point.duration or dura) / self.interval
         end
         local stepX, stepY = (distanceX / numStep), (distanceY / numStep)
         self:moveFor(stepX, stepY, currentX, currentY, targetX, targetY, numStep)
      end
      currentX, currentY = targetX, targetY
   end
end

---comment
---@param coords Coordinates
function MouseCoordinatesModule:mouseMove(coords) self.moveFunction(coords[1], coords[2]) end

return MouseCoordinatesModule
