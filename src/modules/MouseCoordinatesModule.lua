local tl = ...---@type MainLibObject
local max,min,abs,ceil,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,sub,gsub,upper,type,running,MoveMouseRelative,unpack,tonumber,error =
  math.max,math.min,math.abs,math.ceil,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,string.sub,string.gsub,string.upper,type,coroutine.running,MoveMouseRelative,unpack,tonumber,error
local currentSample, mouseCount, mouseHistory
local MonitorDefinition = tl:classImport("MonitorDefinition")---@type MonitorDefinition
--=============================================================
local MouseCoordinatesModule = tl.baseClass:new()---@class MouseCoordinatesModule:BaseClass Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.

local limit = (2^16)-1 --65535
local screenGap = 0.64

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
local function _areaCheck(ar)

end

function MouseCoordinatesModule:constructor()
  self.monStore = {}---@type MonitorDefinition[]
  self.rectStore = {}
  self.mainNum = 1
  self.xRangeWin = {0,limit}
  self.yRangeWin = {0,limit}
end

---calculate coordinate Data for all defined screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin)
  if not origin[1] then return end
  local multiMonitor = type(origin[1]) == "table"
  if multiMonitor then
    for i = 1, #origin do local m = origin[i]
      if m.main then  self.mainNum = i end
      if not m.topLeft or not m.bottomRight then error('please corner coordinates for a multi monitor setup') end
      m.win = {w=abs(m.topLeft[1] - m.bottomRight[1]), h=abs(m.topLeft[2] - m.bottomRight[2])}
      if m.topLeft[1] < self.xRangeWin[1] then self.xRangeWin[1] = m.topLeft[1] end
      if m.topLeft[2] < self.yRangeWin[1] then self.yRangeWin[1] = m.topLeft[2] end
      if m.bottomRight[2] > self.xRangeWin[2] then self.xRangeWin[2] = m.bottomRight[2] end
      if m.bottomRight[1] > self.yRangeWin[2] then self.yRangeWin[2] = m.bottomRight[1] end
      self.monStore[#self.monStore+1]= (tl:classImport('MonitorDefinition')):new(m)
    end
  else self.monStore[#self.monStore+1]= (tl:classImport('MonitorDefinition')):new(origin) end
end

function MouseCoordinatesModule:virtualTransform(absX,absY)
  return tl.helperUtils.linearTransform(absX,self.xRangeWin[1],self.xRangeWin[2],0,limit),tl.helperUtils.linearTransform(absY,self.yRangeWin[1],self.yRangeWin[2],0,limit)
end

function MouseCoordinatesModule:genRect(rectDef,id)
  self.rectStore[id] = {}
  if rectDef[1] then
    for i = 1, #rectDef do local def = rectDef[i]
      self.rectStore[id][#self.rectStore[id]+1] = self.monStore[def.screen or self.mainNum]:getRect(def)
    end    
  else self.rectStore[id][#self.rectStore[id]+1] = self.monStore[rectDef.screen or self.mainNum]:getRect(rectDef) end
  return self.rectStore[id]
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
function MouseCoordinatesModule:mouseMove(arg,options, dir,pID)
  if options.relative then self:relativeMouse(arg[1],arg[2]) else
    local co,ca = GetMousePosition()
    tl:put('{'..co..','..ca..'}')
    --local winX,winY = self.monStore[2]:getWinPixel(1920,1080)
    --local worp,warp = self:virtualTransform(winX,winY)
    tl:put(self.monStore[1]:convertToPixel("100%",-10))
   -- MoveMouseToVirtual(worp,warp)
  end
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
function MouseCoordinatesModule:areaCheckWrapper(arg)
  return true
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