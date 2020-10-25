local tl,Base = ...---@type MainLibObject
local max,min,abs,ceil,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,sub,gsub,upper,type,running,MoveMouseRelative,unpack,tonumber =
  math.max,math.min,math.abs,math.ceil,GetRunningTime,MoveMouseToVirtual,MoveMouseTo,GetMousePosition,string.sub,string.gsub,string.upper,type,coroutine.running,MoveMouseRelative,unpack,tonumber
local currentSample, mouseCount, mouseHistory
local MonitorDefinition = tl:classImport("MonitorDefinition")---@type MonitorDefinition
--=============================================================
---@class MouseCoordinatesModule
---: Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.
local MouseCoordinatesModule = Base:new()
---detect on which monitor a coordinate is located
---@param xVal number
---@param yVal number
---@return number
local function _getMonitor(xVal, yVal)
  if #tl.config.resolutions == 1 then return 1 end
  local cx, cy = GetMousePosition()
  if xVal and yVal then cx, cy = xVal, yVal end
  local monRes = 1
  for d = 1, #tl.config.resolutions do
    local mon = tl.config.resolutions[d]
    local xDeviation = tl.config.resolutions[tl.scriptStates.mainPos].xPixel / 2
    local yDeviation = tl.config.resolutions[tl.scriptStates.mainPos].yPixel / 2
    if(cx >= mon.leftEdge - xDeviation) and (cx <= mon.rightEdge + xDeviation) 
    and (cy >= mon.topEdge - yDeviation) and(cy <= mon.bottomEdge + yDeviation) then
      monRes = d
      break
    end
  end
  return monRes
end
---get the current mouse position either from previous samplesor manual check.
local function _fastPosition()
  return (not tl.mousePositionCheck and GetMousePosition()) or mouseHistory[currentSample].w, mouseHistory[currentSample].h
end

---transform absolute locator values to virtual desktop values between 0 and 65535
---@param val number
---@param axis string
local function _virtualTransform(val, axis)
  local propRay = {w = {"left", "right"}, h = {"top", "bottom"}}
  local mop =(val - tl.config.resolutions.virtualDesktop[propRay[axis][1] .. "Edge"]) *
  (65535 / (tl.config.resolutions.virtualDesktop[propRay[axis][2] .. "Edge"] - tl.config.resolutions.virtualDesktop[propRay[axis][1] .. "Edge"]))
  return min(max(ceil(mop), 0), 65535)
end

---transform a pixel value to a locator or virtual coordinate relative to the target monitor
---@param val number
---@param axis string
---@param moNum number
---@param virt boolean
local function _relativePixelTransform(val, axis, moNum, virt)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local newMax = mon["locator" .. upper(axis)]
  local mult = 1
  if virt then
    newMax = mon["virtual" .. upper(axis)]
    mult =(tl.config.resolutions.virtualDesktop.w / tl.config.resolutions.virtualDesktop.h) /
    (mon.ratio / tl.config.resolutions[tl.scriptStates.mainPos].ratio)
  end
  local oldMax = mon[axis]
  local res = val * (newMax / oldMax)
  return (axis == "w" and res / mult) or res * mult
end

---transform pixel values on a specific monitor to absolute or virtual locator values
---@param val number
---@param axis string
---@param moNum number
local function _pixelTransform(val, axis, moNum)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local propRay = {w = {"leftEdge", "rightEdge"}, h = {"topEdge", "bottomEdge"}}
  return val * ((mon[axis]) / (mon[propRay[axis][1]] - mon[propRay[axis][2]])) + mon[propRay[axis][2]]
end

--transform logitech units to pixels
---@param val number
---@param axis string
---@param moNum number
---@param virt boolean
local function _logiTransform(val, axis, moNum, virt)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local prefRay =
    virt and {w = {"virtualL", "virtualR"}, h = {"virtualT", "virtualB"}} or {w = {"l", "r"}, h = {"t", "b"}}
  local propRay = {w = {"eftEdge", "ightEdge"}, h = {"opEdge", "ottomEdge"}}
  return (val - mon[prefRay[axis][2] .. propRay[axis][2]]) *
    ((mon.w - 1) / (mon[prefRay[axis][1] .. propRay[axis][1]] - mon[prefRay[axis][2] .. propRay[axis][2]]))
end

---Convert user input coordinates into usable data
---@param coord string|number
---@param axis string
---@param mon number
---@param virt boolean
---@param abso boolean
local function _parseCoordinates(coord, axis, mon, virt, abso)
  local parsed
  local relMode = false
  local moNum = mon or _getMonitor()
  mon = tl.config.resolutions[moNum]
  local logi = false
  local propStrings =virt and {s = "virtual", h = "virtualTopEdge", w = "virtualLeftEdge"} 
  or{s = "locator", h = "topEdge", w = "leftEdge"}
  -- local scaler = mon.scale or 1
  local switcher = 1
  local baseRay = {}
  local baseW
  -- if not tl.config.scaleCoordinates then scaler = 1 end
  --coord = coord *scaler
  if type(coord) == "string" and (sub(coord, 1, 1) == "+" or sub(coord, 1, 1) == "-") then
    if sub(coord, 1, 1) == "-" then switcher = -1 end
    coord = sub(coord, 2)
    relMode = true
    baseRay = {baseW, baseH = GetMousePosition()}
    if virt then
      baseRay["base" .. upper(axis)] =
        _relativePixelTransform(_logiTransform(baseRay["base" .. upper(axis)], axis, moNum), axis, moNum, virt)
    end
  end
  if type(coord) == "number" or (type(coord) == "string" and sub(coord, -2) == "px") then
    -- tl:put("result:"..axis,coord,parsed)
    if type(coord) == "string" then coord = (tonumber(gsub(coord, "[^%d]*$", ""), _) or 0) end
    parsed = _relativePixelTransform(coord, axis, moNum, virt)
  elseif type(coord) == "string" then
    if sub(coord, 1, 1) == "." then
      parsed = ((tonumber(gsub(coord, "^[^%d]*", "0."), _) or 0) * mon[propStrings.s .. upper(axis)])
    elseif sub(coord, -1) == "l" then
      logi = true
      parsed = (tonumber(gsub(coord, "[^%d]*$", ""), _) or 0)
    end
  end
  if relMode then parsed = baseRay["base" .. upper(axis)] + (parsed * switcher) end
  if abso and logi == false then parsed = mon[propStrings[axis]] + parsed end
  return parsed or error("Invalid Format for coordinates")
end

---Find the best way for moving the mouse between two monitors. t1= current monitor, t2= target monitor.
---@param t1 MonitorDefinition
---@param t2 MonitorDefinition
local function _monitorIntersect(t1, t2)
  local switch = 1
  local distance = abs(t1.pos - t2.pos)
  if t1.pos > t2.pos then switch = -1 end
  local m1 = t1
  local m2 = tl.config.resolutions[m1.pos + switch]
  while distance ~= 0 do
    local topLimit = max(m1.virtualTopEdge, m2.virtualTopEdge)
    local bottomLimit = min(m1.virtualBottomEdge, m2.virtualBottomEdge)
    local leftLimit = max(m1.virtualLeftEdge, m2.virtualLeftEdge)
    local rightLimit = min(m1.virtualRightEdge, m2.virtualRightEdge)
    local wCoords = leftLimit + abs(leftLimit - rightLimit) / 2
    local hCoords = topLimit + abs(topLimit - bottomLimit) / 2
    MoveMouseToVirtual(
      wCoords + (tl.config.resolutions[tl.scriptStates.mainPos].xPixel * switch),
      hCoords + (tl.config.resolutions[tl.scriptStates.mainPos].yPixel * switch)
    )
    m1 = tl.config.resolutions[m1.pos + switch]
    m2 = tl.config.resolutions[m1.pos + switch]
    distance = distance - 1
  end
end

---move the mouse until it reaches a certain coordinate within the alloted time
---@param x number
---@param y number
---@param time number
local function _moveUntil(x, y, time)
  local moveFunc = (#tl.config.resolutions == 1) and MoveMouseTo or MoveMouseToVirtual
  local startTime = GetRunningTime()
  local startX, startY = GetMousePosition()
  if #tl.config.resolutions ~= 1 then
    startX = _virtualTransform(startX, "w")
    startY = _virtualTransform(startY, "h")
  end
  local xDiff = x - startX
  local yDiff = y - startY
  local ms = 0

  while ms <= time do local fraction = (GetRunningTime() - startTime) / time
    if fraction > 1 then fraction = 1 end
    moveFunc(startX + (xDiff * fraction), (startY + (yDiff * fraction)))
    tl.coroutines:wait(tl.config.pollInterval)
    ms = ms + tl.config.pollInterval
  end
  moveFunc(x, y)
  return -1
end

---Checks if the mouse is within a certain area.
---@param ar AreaContainer
local function _areaCheck(ar)
  local moNum = ar.monitor or tl.scriptStates.mainPos
  local mon = tl.config.resolutions[moNum]
  local res = false
  if ar.exclude then res = true end
  if moNum ~= _getMonitor() then return res end
  local scaler = mon.scale or 1
  if not tl.config.scaleCoordinates then scaler = 1 end
  local posW, posH = _fastPosition()
  local off = {"top", "bottom", "left", "right"}
  local offcont = {}
  for i = 1, #off do
    local let = "h"
    if i > 2 then let = "w" end
    offcont[off[i]] = _parseCoordinates((ar[off[i]] or 0) * scaler, let, moNum)
  end
  local wMin, wMax, hMin, hMax

  local w = _parseCoordinates(ar[1], "w", moNum) or nil
  local h = _parseCoordinates(ar[2], "h", moNum) or nil
  local wDeviate = tl.config.resolutions[tl.scriptStates.mainPos].xPixel / 2
  local hDeviate = tl.config.resolutions[tl.scriptStates.mainPos].yPixel / 2

  if not w then
    wMin = mon.leftEdge + (offcont.left or 0)
    wMax = mon.rightEdge - (offcont.right or 0)
  else
    if offcont.right ~= nil and offcont.left ~= nil then offcont.right = nil end
    if offcont.right ~= nil then
      wMin = mon.rightEdge - (offcont.right or 0) - mon.leftEdge - (w * scaler)
      wMax = mon.rightEdge - (offcont.right or 0)
    else
      wMin = mon.leftEdge + (offcont.left or 0)
      wMax = mon.leftEdge + (offcont.left or 0) + (w * scaler)
    end
  end

  if not h then
    hMin = mon.topEdge + (offcont.top or 0)
    hMax = mon.bottomEdge - (offcont.bottom or 0)
  else
    if offcont.bottom ~= nil and offcont.top ~= nil then offcont.bottom = nil end
    if offcont.bottom ~= nil then
      hMin = mon.bottomEdge - (offcont.bottom or 0) - (h * scaler)
      hMax = mon.bottomEdge - (offcont.bottom or 0)
    else
      hMin = mon.topEdge + (offcont.top or 0)
      hMax = mon.topEdge + (offcont.top or 0) + (h * scaler)
    end
  end
  if posW >= (wMin - wDeviate) and posW <= (wMax + wDeviate) and posH >= (hMin - hDeviate) and posH <= (hMax + hDeviate) then
    res = not res
  end -- ;tl:put("min x: "..floor(wMin).."; max x: "..floor(wMax).."; current pos:"..posW.."\n","min y: "..floor(hMin).."; max y: "..floor(hMax).."; current pos:"..posH)
  return res
end

---calculate coordinate Data for all defined screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin, profile)
if not origin then return false end
  local resolutions = {}
  local storageX = {}
  local storageY = {}
  ---@type MonitorDefinition[]
  local displayDef = origin 

  if tl.tbl:isSingleTypeTable(displayDef, "table") == false then
    displayDef = {MonitorDefinition:new(displayDef)}
    storageX[#storageX + 1] = displayDef[1].noOffsetLeftEdge
    storageX[#storageX + 1] = displayDef[1].noOffsetRightEdge
    storageY[#storageY + 1] = displayDef[1].noOffsetTopEdge
    storageY[#storageY + 1] = displayDef[1].noOffsetBottomEdge
    resolutions = displayDef
    return resolutions
  elseif displayDef[1][1] and type(displayDef[1][1]) == "table" then
    for i = 1, #displayDef do local def = displayDef[i]
      resolutions[#resolutions + 1] = self:compileScreenCoordinates(def,profile)
      resolutions[#resolutions].disPositon = i
    end
    return resolutions
  end

  local mainNum = 0
  for g = 1, #displayDef do
    if displayDef[g].main ~= nil then
      mainNum = g
      break
    end
  end

  if mainNum == 0 then
    mainNum = 1
    tl:put("No main monitor defined! Rightmost monitor used as main by default.")
  end

  tl.scriptStates.mainPos = mainNum
  displayDef[mainNum] = MonitorDefinition:new(displayDef[mainNum], mainNum)
  local mainMon = displayDef[mainNum]
  storageX[#storageX + 1] = mainMon.noOffsetLeftEdge
  storageX[#storageX + 1] = mainMon.noOffsetRightEdge
  storageY[#storageY + 1] = mainMon.noOffsetTopEdge
  storageY[#storageY + 1] = mainMon.noOffsetBottomEdge
  local align = displayDef.align or "bottom"

  for i = 1, #displayDef do
    if i ~= mainNum then
      displayDef[i] = MonitorDefinition:new(displayDef[i],i)
      displayDef[i]:setScale(mainMon)
    end
  end

  for i = mainNum - 1, 1, -1 do local mon = displayDef[i]
    local lastMon = displayDef[i + 1] --Monitors on the left of the main monitor, counted from right to left
    mon:shiftLeft(lastMon,mainMon,align)
    storageX[#storageX + 1] = mon.noOffsetLeftEdge
    storageX[#storageX + 1] = mon.noOffsetRightEdge
    storageY[#storageY + 1] = mon.noOffsetTopEdge
    storageY[#storageY + 1] = mon.noOffsetBottomEdge
  end

  for i = mainNum + 1, #displayDef do local mon = displayDef[i] --Monitors on the right of the main monitor counted from left to right
    local lastMon = displayDef[i - 1] --Dealing with left and right edges
    mon:shiftRight(lastMon,mainMon,align)
    storageX[#storageX + 1] = mon.noOffsetLeftEdge
    storageX[#storageX + 1] = mon.noOffsetRightEdge
    storageY[#storageY + 1] = mon.noOffsetTopEdge
    storageY[#storageY + 1] = mon.noOffsetBottomEdge
  end

  displayDef.virtualDesktop = {}
  displayDef.virtualDesktop.rightEdge = max(unpack(storageX)) --compiling the bounds of the virtual desktop used by MoveMouseToVirtual
  displayDef.virtualDesktop.leftEdge = min(unpack(storageX))
  displayDef.virtualDesktop.topEdge = min(unpack(storageY))
  displayDef.virtualDesktop.bottomEdge = max(unpack(storageY))
  displayDef.virtualDesktop.w = abs(displayDef.virtualDesktop.leftEdge - displayDef.virtualDesktop.rightEdge)
  displayDef.virtualDesktop.h = abs(displayDef.virtualDesktop.topEdge - displayDef.virtualDesktop.bottomEdge)
  displayDef.virtualDesktop.hDeviation = displayDef.virtualDesktop.h / 65535
  displayDef.virtualDesktop.wDeviation = displayDef.virtualDesktop.w / 65535

  for i = 1, #displayDef do local mon = displayDef[i] --compiling virtualDesktop coordinates of individual monitors
    mon.virtualRightEdge = _virtualTransform(mon.noOffsetRightEdge, "w")
    mon.virtualLeftEdge = _virtualTransform(mon.noOffsetLeftEdge, "w")
    mon.virtualTopEdge = _virtualTransform(mon.noOffsetTopEdge, "h")
    mon.virtualBottomEdge = _virtualTransform(mon.noOffsetBottomEdge, "h")
    mon.virtualH = abs(mon.virtualRightEdge - mon.virtualLeftEdge)
    mon.virtualW = abs(mon.virtualTopEdge - mon.virtualBottomEdge)
    mon.ratio = mon.w / mon.h
  end
  return displayDef
end

---Main function for moving the mouse instantly or over time
---@param arg table
---@param dir string
function MouseCoordinatesModule:mouseMove(arg,options, dir,pID)
  local moveFunc = MoveMouseToVirtual
  local virtu = true
  if #tl.activeProfile.config.resolutions == 1 then
    moveFunc = MoveMouseTo
    virtu = false
  end
  local playMode = options.play or "normal"
  if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") 
  and options.direction ~= "up") or (options.direction == "up" and dir == "down")
   then return end
  local w, h = 0, 0
  local targMon = options.monitor or _getMonitor()
  local cMon = (options.monitor ~= nil) and _getMonitor() or targMon
  arg = (type(arg) ~= "table") and {arg, arg} or arg
  w = _parseCoordinates(arg[1], "w", targMon, virtu, 1)
  h = _parseCoordinates(arg[2], "h", targMon, virtu, 1)
  --tl:put(arg[1],arg[2])
  if arg[3] then
    if tl.coroutines.taskList[arg.pID] == nil then
      if running() then _moveUntil(w, h, arg[3])
      else tl.coroutines:taskRun(pID, nil, nil, _moveUntil, w, h, arg[3]) end
    elseif (dir == "up" and options.play == "hold") or (dir == "down" and options.play == "toggle") then
      tl.coroutines:taskAbort(pID)
    end
  else
    if tl.activeProfile.resolutions[cMon].pos ~= tl.activeProfile.resolutions[targMon].pos then
      _monitorIntersect(tl.activeProfile.resolutions[cMon], tl.activeProfile.resolutions[targMon])
    end
    --tl:put(h,w)
    moveFunc(w, h)
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
  if tl.tbl:isSingleTypeTable(arg, "table") then
    local orRay = {}
    for g = 1, #arg do
      local ca = arg[g]
      if not ca.exclude then orRay[#orRay + 1] = ca
      elseif _areaCheck(ca) == false then return false end
    end
    for i = 1, #orRay do local ory = orRay[i]
      if _areaCheck(ory) then return true end
    end
    return false
  else return _areaCheck(arg) end
end

---not implemented yet
function MouseCoordinatesModule:mouseVelocity()
end

---automatically check the position of the mouse after a certain interval.
function MouseCoordinatesModule:mouseCheckFunc()
  mouseCount = mouseCount + 1
  if mouseCount >= tl.config.mouseInterval then
    currentSample = currentSample + 1
    mouseHistory[currentSample] = {}
    mouseHistory[currentSample].w, mouseHistory[currentSample].h = GetMousePosition()
    if currentSample == tl.config.mouseHistoryLimit then currentSample = 1 end
    mouseCount = 0
  end
end

return MouseCoordinatesModule