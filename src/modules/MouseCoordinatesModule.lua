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

local function _defineMain()

end

local target = {}

function MouseCoordinatesModule:constructor()
  self.monStore = {}
end

---calculate coordinate Data for all defined screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin)
  if not origin[1] then return end
  local multiMonitor = type(origin[1]) == "table"
  local main = origin
  tl.tbl:prettyTab(main)
  if multiMonitor then 
    local found = false
    for i = 1, #origin do local mon = origin[i]
      if mon.main then 
        found = true
        main = mon
      end
      if not found then main = origin[0] end
    end 
  end

  local totalX = 0
  local totalY = 0

  if multiMonitor then
   for i = 1, #origin do local m = origin[i]
    if i == 1 then 
      totalX = m[1]
      totalY = m[2]
    else
      local scale = (m.scale or 100)/100
      tl:put(scale)
      local alignH = (m.align or {})[1] or "right"
      local alignV = (m.align or {})[2] or "center"
      if alignH == "right" or alignH == "left" then
        totalX = totalX + m[1]/scale
      end
      if alignV == "top" or alignV == "bottom" then
        totalY = totalY + m[2]/scale
      end
    end
   end

   for i = 1, #origin do local m = origin[i]
    local offsetX = 0
    local offsetY = 0
    local fractionX = m[1]/totalX
    local fractionY = m[2]/totalY
    local logiArea = {limit*fractionX,limit*fractionY}
    local scale = (m.scale or 100)/100
    if i~=1 then
      local prevMon = self.monStore[i-1]
      local alignH = (m.align or {})[1] or "right"
      local alignV = (m.align or {})[2] or "center"
      local px,py = prevMon:getNormalized(prevMon.w,prevMon.h)
      if alignH == "right" or alignH == "left" then
        offsetX = px
      end
      if alignV == "top" or alignV == "bottom" then
        offsetY = py
      end
    end
    self.monStore[#self.monStore+1] = (tl:classImport('MonitorDefinition')):new(m,{offsetX,offsetY},logiArea,scale)
   end
   local ta,ty = self.monStore[#self.monStore]:getNormalized(0,1080)
   target = {ta,ty}
  end




  
end

---Main function for moving the mouse instantly or over time
---@param arg table
---@param dir string
function MouseCoordinatesModule:mouseMove(arg,options, dir,pID)
  if options.relative then self:relativeMouse(arg[1],arg[2]) else
    tl:put(GetMousePosition())

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