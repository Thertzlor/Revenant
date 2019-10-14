local max,min,abs,ceil, GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, sub, gsub,upper,type,running,MoveMouseRelative =
math.max,math.min,math.abs,math.ceil ,GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, string.sub, string.gsub, string.upper,type, coroutine.running,MoveMouseRelative
local currentSample, mouseCount, mouseHistory
---@type MainLibObject
local tl = ...
-->>> Functions that deal with calculating screen resolution and mouse pos for area and velocity checks. ----------------------

---detect on which monitor a coordinate is located
---@param xVal number
---@param yVal number
---@return number
local function _getMonitor(xVal,yVal)
  if #tl.config.resolutions == 1 then return 1 end
  local cx,cy = GetMousePosition()
  if xVal and yVal then cx,cy = xVal,yVal end
  local monRes = 1
  for d=1,#tl.config.resolutions do local mon = tl.config.resolutions[d]
    local xDeviation =  tl.config.resolutions[tl.mainPos].xPixel/2
    local yDeviation =  tl.config.resolutions[tl.mainPos].yPixel/2
    if (cx >= mon.leftEdge-xDeviation) and (cx <= mon.rightEdge+xDeviation) and (cy >= mon.topEdge-yDeviation) and (cy <= mon.bottomEdge+yDeviation)
    then
      monRes = d;
      break
    end
  end
  return monRes
end

---get the current mouse position either from previous samplesor manual check.
local function _fastPos()
  if not tl.mousePositionCheck then return GetMousePosition() end
  return mouseHistory[currentSample].w,mouseHistory[currentSample].h
end

---transform absolute locator values to virtual desktop values between 0 and 65535
---@param val number
---@param axis string
local function _virtualTransform(val,axis)
  local propRay = {w = {"left","right"}, h = {"top","bottom"}}
  local mop = (val-tl.virtualDesktop[propRay[axis][1].."Edge"])*(65535/(tl.virtualDesktop[propRay[axis][2].."Edge"]-tl.virtualDesktop[propRay[axis][1].."Edge"]))
  return min(max(ceil(mop),0),65535)
end

---transform a pixel value to a locator or virtual coordinate relative to the target monitor
---@param val number
---@param axis string
---@param moNum number
---@param virt boolean
local function _relativePixelTransform(val,axis,moNum,virt)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local newMax = mon["locator"..upper(axis)]
  local mult = 1
  if virt then
    newMax = mon["virtual"..upper(axis)]
    mult = (tl.virtualDesktop.w/tl.virtualDesktop.h)/(mon.ratio/tl.config.resolutions[tl.mainPos].ratio)
  end
  local oldMax = mon[axis]
  local res = val*(newMax/oldMax)
  if axis == "w" then
    res = res/mult
  else
    res = res*mult
  end
  return res
end

---transform pixel values on a specific monitor to absolute or virtual locator values
---@param val number
---@param axis string
---@param moNum number
local function _pixelTransform(val,axis,moNum)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local propRay = {w = {"leftEdge","rightEdge"}, h = {"topEdge","bottomEdge"}}
  return val*((mon[axis])/(mon[propRay[axis][1]]-mon[propRay[axis][2]]))+mon[propRay[axis][2]]
end

--transform logitech units to pixels
---@param val number
---@param axis string
---@param moNum number
---@param virt boolean
local function _logiTransform(val,axis,moNum,virt)
  local mon = tl.config.resolutions[moNum or _getMonitor()]
  local prefRay = { w = {"l","r"}, h = {"t","b"}}
  if virt then prefRay = { w = {"virtualL","virtualR"}, h = {"virtualT","virtualB"}} end
  local propRay = {w = {"eftEdge","ightEdge"}, h = {"opEdge","ottomEdge"}}
  return (val-mon[prefRay[axis][2]..propRay[axis][2]])*((mon.w-1)/(mon[prefRay[axis][1]..propRay[axis][1]]-mon[prefRay[axis][2]..propRay[axis][2]]))
end

---Convert user input coordinates into usable data
---@param coord string|number
---@param axis string
---@param mon number
---@param virt boolean
---@param abso boolean
local function _parseCoordinates(coord,axis,mon,virt,abso)
  local parsed
  local relMode = false
  local moNum = mon or _getMonitor()
  mon = tl.config.resolutions[moNum]
  local logi = false
  local propStrings = {s="locator", h="topEdge",w="leftEdge"}
  -- local scaler = mon.scale or 1
  local switcher = 1
  local baseRay = {}
  local baseW
  -- if not tl.config.scaleCoordinates then scaler = 1 end
  --coord = coord *scaler
  if virt then
    propStrings = {s="virtual",h="virtualTopEdge",w="virtualLeftEdge"}
  end
  if type(coord) == "string" and ((sub(coord,1,1) == "+" or sub(coord,1,1) == "-")) then
    if sub(coord,1,1) == "-" then switcher = -1 end
    coord = sub(coord,2)
    relMode = true
      baseRay={baseW,baseH = GetMousePosition()}
    if virt then
      baseRay["base"..upper(axis)] = _relativePixelTransform(_logiTransform(baseRay["base"..upper(axis)],axis,moNum),axis,moNum,virt)
    end
  end
  if type(coord) == "number" or (type(coord) == "string" and sub(coord,-2) == "px") then
    if type(coord) == "string" then coord = (tonumber(gsub(coord,"[^%d]*$",""),_) or 0) end
    parsed =  _relativePixelTransform(coord,axis,moNum,virt)
   -- tl.put("result:"..axis,coord,parsed)
  elseif type(coord) == "string" then
    if sub(coord,1,1) == "." then
      parsed =  (((tonumber(gsub(coord,"^[^%d]*","0."),_) or 0) * mon[propStrings.s..upper(axis)]))
    elseif sub(coord,-1) == "l" then
      logi = true
      parsed = (tonumber(gsub(coord,"[^%d]*$",""),_) or 0)
    end
  end
  if relMode then
    parsed = baseRay["base"..upper(axis)]+(parsed*switcher)
  end
  if abso and logi == false then
    parsed = mon[propStrings[axis]]+parsed
  end
  return parsed or error("Invalid Format for coordinates")
end

---Find the best way for moving the mouse between two monitors. t1= current monitor, t2= target monitor.
---@param t1 MonitorDefinition
---@param t2 MonitorDefinition
local function _monitorIntersect(t1,t2)
  local switch = 1
  local distance = abs(t1.pos - t2.pos)
  if t1.pos > t2.pos then switch = -1 end
  local m1 = t1
  local m2 = tl.config.resolutions[m1.pos+switch]
  while distance ~= 0 do
    local topLimit = max(m1.virtualTopEdge,m2.virtualTopEdge)
    local bottomLimit = min(m1.virtualBottomEdge,m2.virtualBottomEdge)
    local leftLimit = max(m1.virtualLeftEdge,m2.virtualLeftEdge)
    local rightLimit = min(m1.virtualRightEdge,m2.virtualRightEdge)
    local wCoords = leftLimit+abs(leftLimit-rightLimit)/2
    local hCoords = topLimit+abs(topLimit-bottomLimit)/2
    MoveMouseToVirtual(wCoords+(tl.config.resolutions[tl.mainPos].xPixel*switch),hCoords+(tl.config.resolutions[tl.mainPos].yPixel*switch));
    m1 = tl.config.resolutions[m1.pos+switch]
    m2 = tl.config.resolutions[m1.pos+switch]
    distance = distance - 1
  end
end

---move the mouse until it reaches a certain coordinate within the alloted time
---@param x number
---@param y number
---@param time number
local function _moveUntil(x,y,time)
  local moveFunc = MoveMouseToVirtual;
  local startTime = GetRunningTime()
  local startX,startY = GetMousePosition()
  if #tl.config.resolutions == 1 then
    moveFunc = MoveMouseTo
  else
    startX = _virtualTransform(startX,"w")
    startY = _virtualTransform(startY,"h")
  end
  local xDiff = x-startX
  local yDiff = y-startY
  local ms = 0;

  while ms <= time do
    local fraction = (GetRunningTime() - startTime)/time
    if fraction > 1 then fraction = 1 end
    moveFunc(startX+(xDiff*fraction),(startY+(yDiff*fraction)))
    tl.wait(tl.config.pollInterval)
    ms = ms+tl.config.pollInterval
  end
  moveFunc(x,y)
  return -1
end

---Checks if the mouse is within a certain area.
---@param ar AreaContainer
local function _areaCheck(ar)
  local moNum = ar.monitor or tl.mainPos
  local mon = tl.config.resolutions[moNum]
  local res = false
  if ar.exclude then res = true end
  if moNum ~= _getMonitor() then return res end
  local scaler = mon.scale or 1
  if not tl.config.scaleCoordinates then scaler=1 end
  local posW, posH = _fastPos()
  local off = {"top","bottom","left","right"}
  local offcont={}
  for i=1, #off do local let="h" if i>2 then let="w"end  offcont[off[i]] = _parseCoordinates((ar[off[i]] or 0)*scaler,let,moNum) end
  local wMin, wMax,hMin,hMax

  local w = _parseCoordinates(ar[1],"w",moNum) or nil
  local h = _parseCoordinates(ar[2],"h",moNum) or nil
  local wDeviate = tl.config.resolutions[tl.mainPos].xPixel/2
  local hDeviate = tl.config.resolutions[tl.mainPos].yPixel/2

  if not w  then
    wMin = mon.leftEdge+(offcont.left or 0)
    wMax = mon.rightEdge-(offcont.right or 0)
  else
    if offcont.right ~= nil and offcont.left ~= nil then offcont.right = nil end
    if offcont.right ~= nil then
      wMin = mon.rightEdge-(offcont.right or 0)-mon.leftEdge-(w*scaler)
      wMax = mon.rightEdge-(offcont.right or 0)
    else
      wMin = mon.leftEdge+(offcont.left or 0)
      wMax = mon.leftEdge+(offcont.left or 0)+(w*scaler)
    end
  end

  if not h then
    hMin =  mon.topEdge+(offcont.top or 0)
    hMax =  mon.bottomEdge-(offcont.bottom or 0)
  else
    if offcont.bottom ~= nil and offcont.top ~= nil then offcont.bottom = nil end
    if offcont.bottom ~= nil then
      hMin = mon.bottomEdge-(offcont.bottom or 0)-(h*scaler)
      hMax = mon.bottomEdge-(offcont.bottom or 0)
    else
      hMin = mon.topEdge+(offcont.top or 0)
      hMax = mon.topEdge+(offcont.top or 0)+(h*scaler)
    end
  end
  if posW >= (wMin - wDeviate) and posW <= (wMax + wDeviate) and posH >= (hMin - hDeviate) and posH <= (hMax + hDeviate) then
     res = not res
    end -- ;tl.put("min x: "..floor(wMin).."; max x: "..floor(wMax).."; current pos:"..posW.."\n","min y: "..floor(hMin).."; max y: "..floor(hMax).."; current pos:"..posH)
  return res
end

---calculate coordinate Data for all defined screens
function tl.compileScreenCoordinates()
  local storageX = {}
  local storageY = {}
  local function mainInitialize(obj,num)
    ---@class MonitorDefinition
    local mon = {
      w=obj[1],
      h=obj[2],
      ratio= (obj[1]/obj[2]),
      scale = (obj.scale or 100)/100,
      xPixel = (65535/obj[1])*((obj.scale or 100)/100),
      yPixel = (65535/obj[2])*((obj.scale or 100)/100),
      scaleOffsetX = 0,
      scaleOffsetY = 0,
      logiScaleOffsetX= 0,
      logiScaleOffsetY= 0,
      main = 1,
      pos = num or 1,
      manualTop=nil,
      manualRight=nil,
      locatorW = 65535,
      locatorH = 65535,
      topEdge = 0,
      rightEdge = 65535,
      leftEdge = 0,
      bottomEdge = 65535,
      noOffsetLocatorW = 65535,
      noOffsetLocatorH = 65535,
      noOffsetTopEdge = 0,
      noOffsetRightEdge = 65535,
      noOffsetLeftEdge = 0,
      noOffsetBottomEdge = 65535,
      virtualW = 65535,
      virtualH = 65535,
      virtualTopEdge = 0,
      virtualRightEdge = 65535,
      virtualLeftEdge = 0,
      virtualBottomEdge = 65535,
    }
    mon.xPixel = mon.xPixel*mon.scale
    mon.yPixel = mon.yPixel*mon.scale
    mon.scaleOffsetX = mon.w-(mon.w/mon.scale)
    mon.scaleOffsetY = mon.h-(mon.h/mon.scale)
    mon.logiScaleOffsetX = mon.xPixel*mon.scaleOffsetX
    mon.logiScaleOffsetY = mon.yPixel*mon.scaleOffsetY
    return mon
  end
  if tl.allType(tl.config.resolutions,"table") == false then
   tl.config.resolutions = {mainInitialize(tl.config.resolutions)}
   storageX[#storageX+1]=tl.config.resolutions[1].noOffsetLeftEdge
   storageX[#storageX+1]=tl.config.resolutions[1].noOffsetRightEdge
   storageY[#storageY+1]=tl.config.resolutions[1].noOffsetTopEdge
   storageY[#storageY+1]=tl.config.resolutions[1].noOffsetBottomEdge
   return
  end

  local mainNum = 0
  for g=1, #tl.config.resolutions do
    if tl.config.resolutions[g].main ~=nil then mainNum = g break end
  end

  if mainNum == 0 then
    mainNum = 1
    tl.put("No main monitor defined! Rightmost monitor used as main by default.")
  end

  tl.mainPos = mainNum
  tl.config.resolutions[mainNum]=mainInitialize(tl.config.resolutions[mainNum],mainNum)
  local mainMon = tl.config.resolutions[mainNum]
  storageX[#storageX+1]=mainMon.noOffsetLeftEdge
  storageX[#storageX+1]=mainMon.noOffsetRightEdge
  storageY[#storageY+1]=mainMon.noOffsetTopEdge
  storageY[#storageY+1]=mainMon.noOffsetBottomEdge
  local align = tl.config.resolutions.align or "bottom"

  for i = 1, #tl.config.resolutions do local mon = tl.config.resolutions[i]
    if i ~= mainNum then
      mon.w=mon[1]
      mon.h=mon[2]
      mon.ratio = (mon.h/mon.w)
      mon.scale = (mon.scale or 100)/100
      mon.scaleOffsetX = mon.w-(mon.w/mon.scale)
      mon.scaleOffsetY = mon.h-(mon.h/mon.scale)
      mon.logiScaleOffsetX = mainMon.xPixel*mon.scaleOffsetX
      mon.logiScaleOffsetY = mainMon.yPixel*mon.scaleOffsetY
      mon.manualTop = mon.topEdge
      mon.manualRight = mon.rightEdge
      mon.noOffsetLocatorW = ((mon.w/mainMon.w)*65535)
      mon.locatorW = ((mon.w-mon.scaleOffsetX)/mainMon.w)*65535*mainMon.scale
      mon.noOffsetLocatorH = ((mon.h/mainMon.h)*65535)
      mon.locatorH = ((mon.h-mon.scaleOffsetY)/mainMon.h)*65535*mainMon.scale
      mon.pos = i
    end
  end

  for i = mainNum-1, 1, -1 do local mon = tl.config.resolutions[i] local lastMon = tl.config.resolutions[i+1] --Monitors on the left of the main monitor, counted from right to left
    if mon.manualRight then-- Dealing with left and right edges
      mon.noOffsetRightEdge = mon.manualRight + mon.logiScaleOffsetX
    elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
      mon.rightEdge = lastMon.leftEdge  - mon.logiScaleOffsetX - mainMon.xPixel
      mon.noOffsetRightEdge = lastMon.noOffsetLeftEdge
    elseif align == "left" then
      mon.rightEdge= mon.locatorW
      mon.noOffsetRightEdge= mon.noOffsetLocatorW
    elseif align == "right" then
      mon.rightEdge = mainMon.locatorW
      mon.noOffsetRightEdge = mainMon.noOffsetLocatorW
    elseif align == "vertical-center" then
      mon.rightEdge = ((mainMon.locatorW - mon.locatorW- mon.logiScaleOffsetX)/2)+mon.locatorW
      mon.noOffsetRightEdge = ((mainMon.noOffsetLocatorW-mon.noOffsetLocatorW)/2)+mon.noOffsetLocatorW
    end
    mon.leftEdge = mon.rightEdge - mon.locatorW
    mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW

    if mon.manualTop then -- Dealing with top and bottom edges
      mon.noOffsetTopEdge= mon.topEdge
    elseif align == "left" or align == "right" or align == "vertical-center" then --vertical alignments
      mon.topEdge=lastMon.topEdge-mon.logiScaleOffsetY-mon.locatorH-mainMon.yPixel
      mon.noOffsetTopEdge=lastMon.noOffsetTopEdge - mon.noOffsetLocatorH - mainMon.yPixel
    elseif align == "top" then
      mon.topEdge = 0
      mon.noOffsetTopEdge = 0
    elseif align == "bottom" then
      mon.topEdge = (mainMon.bottomEdge - mon.locatorH - mon.logiScaleOffsetY )
      mon.noOffsetTopEdge = (mainMon.noOffsetBottomEdge - mon.noOffsetLocatorH )
    elseif align == "center" then
      mon.topEdge = (mainMon.locatorH - mon.locatorH)/2
      mon.noOffsetTopEdge = (mainMon.noOffsetLocatorH - mon.noOffsetLocatorH)/2
    end
    mon.bottomEdge = mon.topEdge+mon.locatorH
    mon.noOffsetBottomEdge = mon.noOffsetTopEdge+mon.noOffsetLocatorH
    storageX[#storageX+1]=mon.noOffsetLeftEdge
    storageX[#storageX+1]=mon.noOffsetRightEdge
    storageY[#storageY+1]=mon.noOffsetTopEdge
    storageY[#storageY+1]=mon.noOffsetBottomEdge
  end

  for i = mainNum+1, #tl.config.resolutions do local mon = tl.config.resolutions[i] --Monitors on the right of the main monitor counted from left to right
    local lastMon = tl.config.resolutions[i-1] --Dealing with left and right edges
    if mon.manualRight then
      mon.noOffsetRightEdge = mon.manualRight - mon.logiScaleOffsetX
    elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
      mon.rightEdge = lastMon.rightEdge + mon.locatorW + mainMon.xPixel
      mon.noOffsetRightEdge = lastMon.noOffsetRightEdge + mon.noOffsetLocatorW + mainMon.xPixel
    elseif align == "left" then
      mon.rightEdge= mon.locatorW
      mon.noOffsetRightEdge= mon.noOffsetLocatorW
    elseif align == "right" then
      mon.rightEdge = mainMon.locatorW
      mon.noOffsetRightEdge = mainMon.noOffsetLocatorW
    elseif align == "vertical-center" then
      mon.rightEdge = ((mainMon.locatorW - mon.locatorW- mon.logiScaleOffsetX)/2)+mon.locatorW
      mon.noOffsetRightEdge = ((mainMon.noOffsetLocatorW-mon.noOffsetLocatorW)/2)+mon.noOffsetLocatorW
    end
    mon.leftEdge = mon.rightEdge - mon.locatorW - mon.logiScaleOffsetX
    mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW

    if mon.manualTop then -- Dealing with top and bottom edges
      mon.noOffsetTopEdge= mon.topEdge --Need to check if this works with scales moitors under the main one
    elseif align == "left" or align == "right" or align == "vertical-center" then -- vertical alignments
      mon.topEdge=lastMon.bottomEdge+mainMon.yPixel
      mon.noOffsetTopEdge=lastMon.noOffsetBottomEdge+mainMon.yPixel
    elseif align == "top" then
      mon.topEdge =  0
      mon.noOffsetTopEdge = 0
    elseif align == "bottom" then
      mon.topEdge = (mainMon.bottomEdge - mon.locatorH - mon.logiScaleOffsetY )
      mon.noOffsetTopEdge = (mainMon.noOffsetBottomEdge - mon.noOffsetLocatorH )
    elseif align == "center" then
      mon.topEdge = (mainMon.locatorH - mon.noOffsetLocatorH)/2
      mon.noOffsetTopEdge = (mainMon.noOffsetLocatorH - mon.noOffsetLocatorH)/2
    end
    mon.bottomEdge = mon.topEdge+mon.locatorH+mon.logiScaleOffsetY
    mon.noOffsetBottomEdge = mon.topEdge+mon.noOffsetLocatorH
    storageX[#storageX+1]=mon.noOffsetLeftEdge
    storageX[#storageX+1]=mon.noOffsetRightEdge
    storageY[#storageY+1]=mon.noOffsetTopEdge
    storageY[#storageY+1]=mon.noOffsetBottomEdge
  end

  tl.virtualDesktop.rightEdge = max(unpack(storageX)) --compiling the bounds of the virtual desktop used by MoveMouseToVirtual
  tl.virtualDesktop.leftEdge = min(unpack(storageX))
  tl.virtualDesktop.topEdge = min(unpack(storageY))
  tl.virtualDesktop.bottomEdge = max(unpack(storageY))
  tl.virtualDesktop.w = abs(tl.virtualDesktop.leftEdge-tl.virtualDesktop.rightEdge)
  tl.virtualDesktop.h = abs(tl.virtualDesktop.topEdge-tl.virtualDesktop.bottomEdge)
  tl.virtualDesktop.hDeviation = tl.virtualDesktop.h/65535
  tl.virtualDesktop.wDeviation = tl.virtualDesktop.w/65535

  for i = 1, #tl.config.resolutions do local mon = tl.config.resolutions[i] --compiling virtualDesktop coordinates of individual monitors
    mon.virtualRightEdge = _virtualTransform(mon.noOffsetRightEdge,"w")
    mon.virtualLeftEdge = _virtualTransform(mon.noOffsetLeftEdge,"w")
    mon.virtualTopEdge = _virtualTransform(mon.noOffsetTopEdge,"h")
    mon.virtualBottomEdge = _virtualTransform(mon.noOffsetBottomEdge,"h")
    mon.virtualH = abs(mon.virtualRightEdge-mon.virtualLeftEdge)
    mon.virtualW = abs(mon.virtualTopEdge-mon.virtualBottomEdge)
    mon.ratio = mon.w/mon.h
  end
 -- tl.prettyTab(tl.config.resolutions)
end

---Main function for moving the mouse instantly or over time
---@param arg table
---@param dir string
function tl.mouseMove(arg,dir)
  local moveFunc = MoveMouseToVirtual;
  local virtu = true
  if #tl.config.resolutions == 1 then
    moveFunc = MoveMouseTo
    virtu = false
  end
  local playMode = arg.play or "normal"
  if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") and arg.direction ~= "up") or (arg.direction == "up" and dir=="down") then
    return
  end
  local w,h = 0,0
  local targMon = arg.monitor or _getMonitor()
  local cMon = targMon
  if arg.monitor ~= nil then cMon = _getMonitor() end
  if type(arg) ~= "table" then
    arg = {arg,arg}
  end
  w = _parseCoordinates(arg[1],"w",targMon,virtu,1)
  h = _parseCoordinates(arg[2],"h",targMon,virtu,1)
  --tl.put(arg[1],arg[2])
  if arg[3] then
    if tl.taskList[arg.pID] == nil then
      if running() then
        _moveUntil(w,h,arg[3])
      else
        tl.taskRun(arg.pID,nil,nil,_moveUntil,w,h,arg[3])
      end
    elseif (dir == "up" and arg.play == "hold") or (dir == "down" and arg.play == "toggle")  then
      tl.taskAbort(arg.pID)
    end
  else
   if tl.config.resolutions[cMon].pos ~= tl.config.resolutions[targMon].pos then
      _monitorIntersect(tl.config.resolutions[cMon],tl.config.resolutions[targMon])
   end
    --tl.put(h,w)
    moveFunc(w,h)
  end
end

--- wrapper for the previously broken MoveMouseRelative() function
---@param x number
---@param y number
---@return  nil
function tl.relativeMouse(x,y)
  if x == nil then return end
  local movedX = 0
  local movingX = 0
  local movedY = 0
  local movingY = 0
  local limit = 0
  y = y or 0
  while movedX ~= x or movedY ~= y  do
    movingX = x-movedX
    movingY = y-movedY
    if abs(movingX) > 127 then
      movingX = 127
      if x < 0 then movingX = movingX * -1 end
    end
    if abs(movingY) > 127 then
      movingY = 127
      if y < 0 then movingY = movingY * -1 end
    end
    MoveMouseRelative(movingX,movingY)
    movedX = movedX + movingX
    movedY = movedY + movingY
  end
  limit = limit+1
end

---wrapper for posivite or negative areaChecks.
---@param arg AreaContainer[]
function tl.areaCheckWrapper(arg)
  if tl.allType(arg,"table") then
    local orRay={}
    for g = 1, #arg do local ca = arg[g]
      if not ca.exclude then
        orRay[#orRay+1]= ca
      elseif _areaCheck(ca) == false then
        return false
      end
    end
    for i=1, #orRay do local ory = orRay[i]
      if _areaCheck(ory) then return true end
    end
    return false
  else
    return _areaCheck(arg)
  end
end

---not implemented yet
function tl.mouseVelocity()
end

---automatically check the position of the mouse after a certain interval.
function tl.mouseCheckFunc()
  mouseCount = mouseCount +1
  if mouseCount >= tl.config.mouseInterval then
    currentSample = currentSample + 1
    mouseHistory[currentSample]={}
    mouseHistory[currentSample].w,mouseHistory[currentSample].h =  GetMousePosition();
    if currentSample == tl.config.mouseHistoryLimit then currentSample = 1 end
    mouseCount = 0
  end
end