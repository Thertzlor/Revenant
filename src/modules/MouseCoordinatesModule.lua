local tl = ...---@type MainLibObject
local abs,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,type,running,MoveMouseRelative,error =
  math.abs,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,type,coroutine.running,MoveMouseRelative,error
local currentSample, mouseCount, mouseHistory
local MonitorDefinition = tl:classImport("MonitorDefinition")---@type MonitorDefinition
--=============================================================
local MouseCoordinatesModule = tl.baseClass:new()---@class MouseCoordinatesModule:BaseClass Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.

local limit = (2^16)-1 --65535

---get the current mouse position either from previous samplesor manual check.
local function _fastPosition()
  return (not tl.mousePositionCheck and GetMousePosition()) or mouseHistory[currentSample].w, mouseHistory[currentSample].h
end


---move the mouse until it reaches a certain coordinate within the alloted time
---@param x number
---@param y number
---@param time number
local function _moveUntil(x, y, time)

end

---Checks if the mouse is within a certain area.
---@param ar AreaContainer
local function _areaCheck(ar,x,y)
  return (x >= ar.cl[1]) and (x <= ar.cr[1])
  and (y >= ar.cl[2]) and (y <= ar.cr[2])
end

function MouseCoordinatesModule:constructor()
  self.monStore = {}---@type MonitorDefinition[]
  self.rectStoreP = {}
  self.rectStoreN = {}
  self.pointStore = {}
  self.mainNum = 1
  self.xRangeWin = {0,limit}
  self.yRangeWin = {0,limit}
end

---calculate coordinate Data for all defined screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin,profile)
  if not origin[1] then return end
  local multiMonitor = type(origin[1]) == "table"
  if multiMonitor then
    for i = 1, #origin do local m = origin[i]
      if m.main then  self.mainNum = i end
      local cl = (m.main and ({0,0})) or m.topLeft
      local cr = (m.main and ({limit,limit})) or m.bottomRight
      if  (not cl) or (not cr) then error('please corner coordinates for a multi monitor setup') end
      m.win = {w=abs(cl[1] - cr[1]), h=abs(cl[2] - cr[2])}
      if cr[1] > self.xRangeWin[2] then self.xRangeWin[2] = cr[1] end
      if cl[1] < self.xRangeWin[1] then self.xRangeWin[1] = cl[1] end
      if cl[2] < self.yRangeWin[1] then self.yRangeWin[1] = cl[2] end
      if cr[2] > self.yRangeWin[2] then self.yRangeWin[2] = cr[2] end
      self.monStore[#self.monStore+1]= (tl:classImport('MonitorDefinition')):new(m)
    end
    tl.tbl:prettyTab({self.xRangeWin,self.yRangeWin})
  else self.monStore[#self.monStore+1]= (tl:classImport('MonitorDefinition')):new(origin) end
end

function MouseCoordinatesModule:virtualTransform(absX,absY)
  return tl.helperUtils.linearTransform(absX,self.xRangeWin[1],self.xRangeWin[2],0,limit),tl.helperUtils.linearTransform(absY,self.yRangeWin[1],self.yRangeWin[2],0,limit)
end

function MouseCoordinatesModule:genPoint(arg,opts,id)
  local x,y =self:virtualTransform(self.monStore[opts.screen or self.mainNum]:getWinPixel(arg[1],arg[2]))
  self.pointStore[id] = {x,y}
  return {x,y}
end

function MouseCoordinatesModule:addRect(def,id)
  local store = def.exclude and self.rectStoreN[id] or self.rectStoreP[id]
  local rect = self.monStore[def.screen or self.mainNum]:getRect(def)
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
  for i = 1, #self.monStore do if self.monStore[i]:contains(x,y) then return i end end
  error('could not find mouse location.')
end

function MouseCoordinatesModule:onMonitor(i,x,y)
  return self.monStore[i]:contains(x,y)
end

---Main function for moving the mouse instantly or over time
---@param arg table
---@param dir string
function MouseCoordinatesModule:mouseMoveWrapper(arg,options, dir,pID)
  if options.relative then self:relativeMouse(arg[1],arg[2]) else
    local x,y = GetMousePosition()
    self:mouseMove(arg,options,pID)
  end
end

function MouseCoordinatesModule:mouseMove(arg,opts,id)
  local coords = self.pointStore[id] or self:genPoint(arg,opts,id)
  MoveMouseToVirtual(coords[1],coords[2])
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

---wrapper for posivite or negative areaChecks.
---@param arg AreaContainer[]
function MouseCoordinatesModule:areaCheckWrapper(arg,id)
  if #self.monStore ==0 then return true end
  local posX, posY = _fastPosition();
  local posMap = self.rectStoreP[id] or self:genRects(arg,id)
  local negMap = self.rectStoreN[id]
  for i = 1, #negMap do if _areaCheck(negMap[i],posX,posY) then return false end end
  for i = 1, #posMap do if _areaCheck(posMap[i],posX,posY) then return true end end
  return #posMap ~= 0
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

return MouseCoordinatesModule