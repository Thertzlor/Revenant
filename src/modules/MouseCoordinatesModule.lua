local tl = ...---@type MainLibObject
local abs,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,type,running,MoveMouseRelative,error,next, sqrt,floor,pcall =
  math.abs,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,type,coroutine.running,MoveMouseRelative,error,next, math.sqrt,math.floor,pcall
local currentSample, mouseCount
local MonitorDefinition = tl:classImport("MonitorDefinition")---@type MonitorDefinition
--=============================================================
local MouseCoordinatesModule = tl.baseClass:new()---@class MouseCoordinatesModule:BaseClass Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.
local mouseHistory = {}
local limit = (2^16)-1 --65535

---Checks if the mouse is within a certain area.
---@param ar AreaContainer
local function _areaCheck(ar,x,y)
  return (x >= ar.cl[1]) and (x <= ar.cr[1])
  and (y >= ar.cl[2]) and (y <= ar.cr[2])
end

function MouseCoordinatesModule:constructor()
  self.screens = {}---@type MonitorDefinition[]
  self.rectStoreP = {}
  self.rectStoreN = {}
  self.pointStore = {}
  self.mainScreen = 1
  self.xRangeWin = {0,limit}
  self.yRangeWin = {0,limit}
  self.moveFunction = MoveMouseToVirtual---@type fun():void
  self.abortThreshold = 200
  self.lagSample = 5
  self.interval = 2
end

---calculate coordinate Data for all defined screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin,profile)
  if not origin[1] then return end
  if tl.profile.config.restrictToMainScreen then self.moveFunction = MoveMouseTo end
  self.interval = tl.profile.config.pollInterval
  local multiMonitor = type(origin[1]) == "table"
  if multiMonitor then
    for i = 1, #origin do local m = origin[i]
      if m.main then  self.mainScreen = i end
      local cl = (m.main and ({0,0})) or m.topLeft
      local cr = (m.main and ({limit,limit})) or m.bottomRight
      if  (not cl) or (not cr) then error('please corner coordinates for a multi monitor setup') end
      m.win = {w=abs(cl[1] - cr[1]), h=abs(cl[2] - cr[2])}
      if not tl.profile.config.restrictToMainScreen then
        if cr[1] > self.xRangeWin[2] then self.xRangeWin[2] = cr[1] end
        if cl[1] < self.xRangeWin[1] then self.xRangeWin[1] = cl[1] end
        if cl[2] < self.yRangeWin[1] then self.yRangeWin[1] = cl[2] end
        if cr[2] > self.yRangeWin[2] then self.yRangeWin[2] = cr[2] end
      end
      self.screens[#self.screens+1]= (tl:classImport('MonitorDefinition')):new(m)
    end
  else self.screens[#self.screens+1]= (tl:classImport('MonitorDefinition')):new(origin) end
  for i = 1, #self.screens do self.screens[i]:setAbsoluteSingle() end
end

function MouseCoordinatesModule:virtualTransform(absX,absY)
  return tl.helperUtils.linearTransform(absX,self.xRangeWin[1],self.xRangeWin[2],0,limit),tl.helperUtils.linearTransform(absY,self.yRangeWin[1],self.yRangeWin[2],0,limit)
end

function MouseCoordinatesModule:genPoint(arg,opts,id)
  local x,y =self:virtualTransform(self.screens[opts.screen]:getWinPixel(arg[1],arg[2]))
  self.pointStore[id] = {x,y}
  return {x,y}
end

function MouseCoordinatesModule:addRect(def,id)
  local store = def.exclude and self.rectStoreN[id] or self.rectStoreP[id]
  local rect = self.screens[def.screen or self.mainScreen]:getRect(def)
  store[#store+1] = {cl={self:virtualTransform(rect.cl[1],rect.cl[2])},cr={self:virtualTransform(rect.cr[1],rect.cr[2])}}
end

function MouseCoordinatesModule:genRects(rectDef,id)
  self.rectStoreN[id] = {}
  self.rectStoreP[id] = {}
  if rectDef[1] then for i = 1, #rectDef do  self:addRect(rectDef[i],id) end    
  else self:addRect(rectDef,id) end
  return self.rectStoreP[id]
end

function MouseCoordinatesModule:getMonitorNo(x,y)
  for i = 1, #self.screens do if self.screens[i]:contains(x,y) then return i end end
  error('could not find mouse location.')
end

function MouseCoordinatesModule:onMonitor(i,x,y)
  return self.screens[i]:contains(x,y)
end

--- wrapper for the previously broken MoveMouseRelative() function
---@param x number
---@param y number
---@return  nil
function MouseCoordinatesModule:relativeMouse(x, y)
  if x == nil then return end
  local movedX = 0
  local movingX = 0
  local movedY = 0
  local movingY = 0
  local limit = 0
  y = y or 0
  while movedX ~= x or movedY ~= y do
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
    MoveMouseRelative(movingX, movingY)
    movedX = movedX + movingX
    movedY = movedY + movingY
  end
  limit = limit + 1
end

---@param arg table<number,number>
---@param dir '"up"'|'"down"'
---@param pID string
function MouseCoordinatesModule:relativeWrapper(arg,options,dir,pID)
  local x,y = arg[1],arg[2]
  if x == nil then return end
  self:relativeMouse(x,y) 
end


---@param arg table<number,number>
---@param num number
local function avNum(arg,num)
  local av = arg[#arg]
  for i = 1, num-1 do av = av+ arg[#arg-i] end
  return av/num
end

local firstMove = true
local lagMultiplier = 1
local averageLag = {}---@type table<number,number>
local noLag = false
---@private
function MouseCoordinatesModule:moveFor(x,y,baseX,baseY,steps,relative,finalCoords)
  local func = relative and self.relativeMouse or self.rawMove
  local int = self.interval
  local checkTime = GetRunningTime()
  local now = checkTime
  local tenCompare = int*10
  local bx = baseX or 0
  local by = baseY or 0
  for i = 1, steps/lagMultiplier do
    func(self,(bx+x*lagMultiplier),(by+y*lagMultiplier))
    if not relative then
      bx = bx+ x*lagMultiplier
      by = by+ y*lagMultiplier
    end
    if noLag == false and i % 10 == 0 then
      now = GetRunningTime()
      averageLag[#averageLag+1] = (now-checkTime)/tenCompare
      if #averageLag % self.lagSample == 0 then lagMultiplier = avNum(averageLag,self.lagSample) end
      checkTime=now
      if firstMove and abs(bx-finalCoords[1]) < self.abortThreshold then
        self:rawMove(finalCoords[1],finalCoords[2])
        return -1
      end
    end
    tl.coroutines:wait(int)
  end
  if (not relative) and finalCoords then self:rawMove(finalCoords[1],finalCoords[2]) end
  firstMove = false
  if noLag == false and #averageLag > 100 then 
    local currentAvg =avNum(averageLag,#averageLag)
    noLag = (abs(currentAvg-1)) < 0.1 
    averageLag = {currentAvg}
  end
  return -1
end

---wrapper for posivite or negative areaChecks.
---@param arg AreaContainer[]
function MouseCoordinatesModule:areaCheckWrapper(arg,id)
  if #self.screens == 0 or not next(arg) then return true end
  local posX, posY = GetMousePosition();
  local posMap = self.rectStoreP[id] or self:genRects(arg,id)
  local negMap = self.rectStoreN[id]
  for i = 1, #negMap do if _areaCheck(negMap[i],posX,posY) then return false end end
  for i = 1, #posMap do if _areaCheck(posMap[i],posX,posY) then return true end end
  return #posMap == 0
end

---not implemented yet
function MouseCoordinatesModule:mouseVelocity()
end

---automatically check the position of the mouse after a certain interval.
function MouseCoordinatesModule:mouseCheckFunc()
  local config = tl.profile.config
  mouseCount = mouseCount + 1
  if mouseCount >= config.mouseInterval then
    currentSample = currentSample + 1
    mouseHistory[currentSample] = {}
    mouseHistory[currentSample].w, mouseHistory[currentSample].h = GetMousePosition()
    if currentSample == config.mouseHistoryLimit then currentSample = 1 end
    mouseCount = 0
  end
end

function MouseCoordinatesModule:rawMove(x,y)
  pcall(self.moveFunction,x,y)
end

---Main function for moving the mouse instantly or over time
---@param arg table
---@param dir string
---@param pID string
function MouseCoordinatesModule:mouseMoveWrapper(arg,options, dir,pID)
  if options.relative and (not options.duration) and (not options.velocity) then return self:relativeWrapper(arg,options,dir,pID) end
  if (not options.duration) and (not options.velocity) then return self:mouseMove(arg,options,pID) end
  local coords = self.pointStore[pID] or self:genPoint(arg,options,pID)
  local currentX,currentY = self:virtualTransform(GetMousePosition())
  local targetX,targetY = coords[1],coords[2]
  if options.relative then targetX,targetY = currentX+targetX,currentY+targetY end
  local distanceX,distanceY = (targetX-currentX),(targetY-currentY)
  local numStep = 0
  if options.velocity then
    local pixelSize = self.screens[options.screen].singleL
    local pixelDistance = sqrt(((distanceX/pixelSize[1])^2) + ((distanceY/pixelSize[2])^2))
    local time = floor((pixelDistance/options.velocity)*(1000))
    numStep = floor(time/self.interval)
  else numStep = options.duration/self.interval end
  tl:put(numStep)
  local stepX,stepY = (distanceX/numStep),(distanceY/numStep)
  if running() then self:moveFor(stepX,stepY,currentX,currentY,numStep,false,{targetX,targetY})
  else tl.coroutines:taskRun(pID, nil, nil, self.moveFor, self, stepX,stepY,currentX,currentY,numStep,false,{targetX,targetY}) end
end

function MouseCoordinatesModule:mouseMove(arg,opts,id)
  local coords = self.pointStore[id] or self:genPoint(arg,opts,id)
  self.moveFunction(coords[1],coords[2])
end

return MouseCoordinatesModule