local tl = ...
--> Functions that deal with calculating screen resolution and mouse position for area and velocity checks. ----------------------

function tl.compileScreenCoordinates()
  local storageX = {}
  local storageY = {}
  local function mainInitialize(obj)
    return {
      w=obj[1],
      h=obj[2],
      ratio= (obj[1]/obj[2]),
      scale = obj.scale or 100,
      xPixel = 65535/obj[1],
      yPixel = 65535/obj[2],
      scaleOffsetX = 0,
      scaleOffsetY = 0,
      logiScaleOffsetX= 0,
      logiScaleOffsetY= 0,
      main = 1,
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
  end

  if tl.allType(tl.resolutions,"table") == false then
   tl.resolutions = {mainInitialize(tl.resolutions)}
   storageX[#storageX+1]=tl.resolutions[1].noOffsetLeftEdge
   storageX[#storageX+1]=tl.resolutions[1].noOffsetRightEdge
   storageY[#storageY+1]=tl.resolutions[1].noOffsetTopEdge
   storageY[#storageY+1]=tl.resolutions[1].noOffsetBottomEdge
   return
  end

  local mainNum = 0
  for g=1, #tl.resolutions do
    if tl.resolutions[g].main ~=nil then mainNum = g break end
  end

  if mainNum == 0 then 
    mainNum = 1
    tl.put("No main monitor defined! Rightmost monitor used as main by default.") 
  end
  tl.mainPos = mainNum
  tl.resolutions[mainNum]=mainInitialize(tl.resolutions[mainNum])
  local mainMon = tl.resolutions[mainNum]
  storageX[#storageX+1]=mainMon.noOffsetLeftEdge
  storageX[#storageX+1]=mainMon.noOffsetRightEdge
  storageY[#storageY+1]=mainMon.noOffsetTopEdge
  storageY[#storageY+1]=mainMon.noOffsetBottomEdge
  local align = tl.resolutions.align or "bottom"

  for i = 1, #tl.resolutions do local mon = tl.resolutions[i]
    if i ~= mainNum then
      mon.w=mon[1]
      mon.h=mon[2]
      mon.ratio = (mon.h/mon.w)
      mon.scale = mon.scale or 100
      mon.scaleOffsetY = mon.h-(mon.h/(mon.scale/100))
      mon.scaleOffsetX = mon.w-(mon.w/(mon.scale/100))
      mon.logiScaleOffsetX = mainMon.xPixel*mon.scaleOffsetX
      mon.logiScaleOffsetY = mainMon.yPixel*mon.scaleOffsetY
      mon.manualTop = mon.topEdge
      mon.manualRight = mon.rightEdge
      mon.noOffsetLocatorW = (mon.w/mainMon.w)*65535
      mon.locatorW = ((mon.w-mon.scaleOffsetX)/mainMon.w)*65535
      mon.noOffsetLocatorH = (mon.h/mainMon.h)*65535
      mon.locatorH = ((mon.h-mon.scaleOffsetY)/mainMon.h)*65535
    end
  end

  for i = mainNum-1, 1, -1 do local mon = tl.resolutions[i] local lastMon = tl.resolutions[i+1] --Monitors on the left of the main monitor, counted from right to left
    if mon.manualRight then-- Dealing with left and right edges
      mon.noOffsetRightEdge = mon.manualRight + mon.logiScaleOffsetX
    elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
      mon.rightEdge = lastMon.leftEdge - mainMon.xPixel - mon.logiScaleOffsetX
      mon.noOffsetRightEdge = lastMon.noOffsetLeftEdge - mainMon.xPixel 
    elseif align == "left" then
      mon.rightEdge= mon.locatorW
      mon.noOffsetRightEdge= mon.noOffsetLocatorW    
    elseif align == "right" then
      mon.rightEdge = mainMon.locatorW
      mon.noOffsetRightEdge = mainMon.noOffsetLocatorW
    elseif align == "vertical-center" then
      mon.rightEdge = (mainMon.locatorW - mon.locatorW)/2
      mon.noOffsetRightEdge = (mainMon.noOffsetLocatorW-mon.noOffsetLocatorW)/2
    end
    mon.leftEdge = mon.rightEdge - mon.locatorW
    mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW
    
    if mon.manualTop then -- Dealing with top and bottom edges
      mon.noOffsetTopEdge= mon.topEdge
    elseif align == "left" or align == "right" or align == "vertical-center" then --vertical alignments
      mon.topEdge=lastMon.bottomEdge+mainMon.yPixel
      mon.noOffsetBottomEdge=lastMon.noOffsetBottomEdge + mainMon+yPixel
    elseif align == "top" then
      mon.topEdge = mon.manualTop or 0
      mon.noOffsetTopEdge = mon.manualTop or 0
    elseif align == "bottom" then 
      mon.topEdge = mainMon.bottomEdge + mon.locatorH + mon.logiScaleOffsetY
      mon.noOffsetTopEdge = mainMon.noOffsetBottomEdge + mon.noOffsetLocatorH 
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
  
  for i = mainNum+1, #tl.resolutions do local mon = tl.resolutions[i] --Monitors on the right of teh main monitor counted from left to right
    local lastMon = tl.resolutions[i-1] --Dealing with left and right edges
    if mon.manualRight then
      mon.noOffsetRightEdge = mon.manualRight - mon.logiScaleOffsetX
    elseif align == "top" or align == "bottom" or align == "center" then --horizontal alignments
      mon.rightEdge = lastMon.rightEdge + mon.locatorW + mon.logiScaleOffsetX + mainMon.xPixel
      mon.noOffsetRightEdge = lastMon.noOffsetRightEdge + mon.noOffsetLocatorW + mainMon.xPixel
    elseif align == "left" then
      mon.rightEdge= mon.locatorW
      mon.noOffsetRightEdge= mon.noOffsetLocatorW    
    elseif align == "right" then
      mon.rightEdge = mainMon.locatorW
      mon.noOffsetRightEdge = mainMon.noOffsetLocatorW
    elseif align == "vertical-center" then
      mon.rightEdge = (mainMon.locatorW - mon.locatorW)/2
      mon.noOffsetRightEdge = (mainMon.noOffsetLocatorW-mon.noOffsetLocatorW)/2
    end
    mon.leftEdge = mon.rightEdge - mon.locatorW
    mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW

    if mon.manualTop then -- Dealing with top and bottom edges
      mon.noOffsetTopEdge= mon.topEdge --Need to check if this works with scales moitors under the main one
    elseif align == "left" or align == "right" or align == "vertical-center" then -- vertical alignments
      mon.topEdge=lastMon.topEdge+mon.locatorH+mainMon.yPixel
      mon.noOffsetTopEdge=lastMon.noOffsetTopEdge+mon.noOffsetLocatorH+mainMon+yPixel
    elseif align == "top" then
      mon.topEdge =  0
      mon.noOffsetTopEdge = 0
    elseif align == "bottom" then 
      mon.topEdge = mainMon.bottomEdge + mon.locatorH + mon.logiScaleOffsetY
      mon.noOffsetTopEdge = mainMon.noOffsetBottomEdge + mon.noOffsetLocatorH 
    elseif align == "center" then 
      mon.topEdge = (mainMon.locatorH - mon.noOffsetLocatorH)/2
    end
    mon.bottomEdge = mon.topEdge+mon.locatorH
    mon.noOffsetBottomEdge = mon.topEdge+mon.noOffsetLocatorH

    storageX[#storageX+1]=mon.noOffsetLeftEdge
    storageX[#storageX+1]=mon.noOffsetRightEdge
    storageY[#storageY+1]=mon.noOffsetTopEdge
    storageY[#storageY+1]=mon.noOffsetBottomEdge
  end
  
  tl.virtualDesktop.rightEdge = math.max(unpack(storageX)) --compiling the bounds of the virtual desktop used by MoveMouseToVirtual
  tl.virtualDesktop.leftEdge = math.min(unpack(storageX))
  tl.virtualDesktop.topEdge = math.min(unpack(storageY))
  tl.virtualDesktop.bottomEdge = math.max(unpack(storageY))
  tl.virtualDesktop.w = math.abs(tl.virtualDesktop.rightEdge-tl.virtualDesktop.leftEdge)
  tl.virtualDesktop.h = math.abs(tl.virtualDesktop.topEdge-tl.virtualDesktop.bottomEdge)

  for i = 1, #tl.resolutions do local mon = tl.resolutions[i] --compiling virtualDesktop coordinates of individual monitors
    mon.virtualRightEdge = tl.virtualTransform(mon.noOffsetRightEdge,"w")
    mon.virtualLeftEdge = tl.virtualTransform(mon.noOffsetLeftEdge,"w")
    mon.virtualTopEdge = tl.virtualTransform(mon.noOffsetTopEdge,"h")
    mon.virtualBottomEdge = tl.virtualTransform(mon.noOffsetBottomEdge,"h")
    mon.virtualH = math.abs(mon.virtualRightEdge-mon.virtualLeftEdge)
    mon.virtualW = math.abs(mon.virtualTopEdge-mon.virtualBottomEdge)
  end
end

function tl.virtualTransform(val,axis) -- transform absolute locator values to virtual desktop values between 0 and 65535 
  local propRay = {w = {"right","left"}, h = {"bottom","top"}}
  return(val-tl.virtualDesktop[propRay[axis][2].."Edge"])*(65535/(tl.virtualDesktop[propRay[axis][2].."Edge"]-tl.virtualDesktop[propRay[axis][1].."Edge"]))
end

function tl.pixelTransform(val,axis,moNum,virt) --transform pixel values on a specific monitor to absolute locator values
  moNum = moNum or tl.getMonitor()
  local mon = tl.resolutions[moNum]
  local prefRay = { w = {"r","l"}, h = {"b","t"}}
  if virt then prefRay = { w = {"virtualR","virtualL"}, h = {"virtualB","virtualT"}} end
  local propRay = {w = {"ightEdge","eftEdge"}, h = {"ottomEdge","opEdge"}}
  return val*((mon[prefRay[axis][1]..propRay[axis][1]]-mon[prefRay[axis][2]..propRay[axis][2]])/(mon[axis]-1))+mon[prefRay[axis][2]..propRay[axis][2]]
end

function tl.getMonitor(xVal,yVal)
  if #tl.resolutions == 1 then return 1 end
  local cx,cy = GetMousePosition()
  if xVal and yVal then cx,cy = xVal,yVal end
  local monRes = 1 
  for d=1,#tl.resolutions do local mon = tl.resolutions[d]
    local xDeviation =  tl.resolutions[tl.mainPos].xPixel/2
    local yDeviation =  tl.resolutions[tl.mainPos].yPixel/2
    tl.put("X: "..cx.." between "..mon.leftEdge.." and "..mon.rightEdge.."\nY: "..cy.." between "..mon.topEdge.." and "..mon.bottomEdge)
    if (cx >= mon.leftEdge+xDeviation or cx >= mon.leftEdge-xDeviation)  and (cx <= mon.rightEdge+xDeviation or cx <= mon.rightEdge-xDeviation ) and (cy >= mon.topEdge-yDeviation or cy >= mon.topEdge+yDeviation) and (cy <= mon.bottomEdge-yDeviation or cy <= mon.bottomEdge+yDeviation) then 
      monRes = d 
      tl.put(monRes)
      break 
    end
  end
  return monRes
end

function tl.parseCoordinates(coord,axis,mon,virt)
  local parsed
  local relMode = false
  local moNum = mon or tl.getMonitor()
  local mon = tl.resolutions[moNum]
  local propString = "locator"
  if virt then
    propString = "virtual"
  end
  if type(coord) == "string" and (string.sub(coord,1,1) == "+" or string.sub(coord,1,1) == "-") then
    local switcher = 1
    if string.sub(coord,1,1) == "-" then switcher = -1 end
    relMode = true
    local baseRay={baseW,baseH = GetMousePosition()}
    if virt then baseRay["base"..string.upper(axis)] = tl.virtualTransform(baseRay["base"..string.upper(axis)],axis) end
  end
  if type(coord) == "number" or (type(coord) == "string" and string.sub(coord,-2) == "px") then
    if type(coord) == "string" then coord = (tonumber(string.gsub(coord,"[^%d]*$",""),_) or 0) end
    parsed=  tl.pixelTransform(coord,axis,moNum,virt)
  elseif type(coord) == "string" then
    if string.sub(coord,1,1) == "." then
      parsed =  (((tonumber(string.gsub(coord,"^[^%d]*","0."),_) or 0) * mon[propString..string.upper(axis)]))
    elseif string.sub(coord,-1) == "l" then
      parsed = (tonumber(string.gsub(coord,"[^%d]*$",""),_) or 0)
    end
  end
  if relMode then parsed = baseRay["base"..string.upper(axis)]+(parsed*switcher) end
  return parsed or error("Invalid Format for coordinates")
end

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
    if math.abs(movingX) > 127 then
      movingX = 127
      if x < 0 then movingX = movingX * -1 end
    end
    if math.abs(movingY) > 127 then
      movingY = 127
      if y < 0 then movingY = movingY * -1 end
    end
    MoveMouseRelative(movingX,movingY)
    movedX = movedX + movingX
    movedY = movedY + movingY
  end
  limit = limit+1
end

function tl.moveUntil(x,y,time,abs)
  local moveFunc = MoveMouseToVirtual;
  if #tl.resolutions == 1 then moveFunc = MoveMouseTo end
  local looplim = 0
  local mon = tl.resolutions[tl.getMonitor()]
  local ratio = mon.ratio
  local startTime = GetRunningTime()
  local wc,hc = GetMousePosition()
  local startX,startY = GetMousePosition()
  local xDeviation =  tl.resolutions[tl.mainPos].xPixel/2
  local yDeviation =  tl.resolutions[tl.mainPos].yPixel/2
  local xDiff = x-startX
  local yDiff = y-startY
  while math.abs(wc - x) > xDeviation or math.abs(hc - y*ratio) > yDeviation do--tl.put(wc,x,"\n",hc,y)
    local fraction = (GetRunningTime() - startTime)/time
    if fraction > 1 then fraction = 1 end
    moveFunc(startX+(xDiff*fraction),(startY+(yDiff*fraction)))
    tl.wait(tl.PollInterval)
    wc,hc = GetMousePosition()
  end
end

function tl.mouseMove(arg,dir)
  local moveFunc = MoveMouseToVirtual;
  if #tl.resolutions == 1 then moveFunc = MoveMouseTo end
  local playMode = arg.play or "normal"
  if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") and arg.direction ~= "up") or (arg.direction == "up" and dir=="down") then
    return
  end
  local mon = tl.resolutions[tl.getMonitor()]
  local ratio = mon.ratio
  local w,h,wc,hc = 0,0,0,0
  if rel == nil then wc,hc = tl.fastPos() end
  local targMon = arg.monitor or tl.getMonitor()
  local cMon = targMon
  if arg.monitor ~= nil then cMon = tl.getMonitor() end

  if type(arg) ~= "table" then
    w= tl.parseCoordinates(arg,"w",targMon)
    h= tl.parseCoordinates(arg,"h",targMon)
  else
    w = parseCoordinates(arg[1],"w",targMon) or wc
    h = parseCoordinates(arg[2],"h",targMon) or hc
  end

  if arg[3] then
    if tl.TaskList[arg.pID] == nil then 
      if coroutine.running() then
        tl.moveUntil(w,h,arg[3])
      else 
        tl.TaskRun(arg.pID,tl.moveUntil,w,h,arg[3])
      end
    elseif (dir == "up" and arg.play == "hold") or (dir == "down" and arg.play == "toggle")  then
      tl.TaskAbort(arg.pID)
    end
  else
    moveFunc(w,h)
  end
end

function tl.unCoordinate(val,axis,unit)
  unit = unit or "px"
  local mon = tl.resolutions[tl.getMonitor()]
  local monRes = mon[axis]
  if unit == "px" then
  val = math.floor((val + (0.5 + 2^-16)) * (monRes-1) / (2^16-1))
  end
  return val
end

function tl.areaCheck(ar)
  local moNum = ar.monitor or tl.mainPos
  local mon = tl.resolutions[moNum]
  local res = false
  if ar.exclude then res = true end
  local posW, posH = tl.fastPos()
  local off = {"top","bottom","left","right"}
  local offcont={}
  for i=1, #off do local let="h" if i>2 then let="w"end offcont[off[i]] = tl.parseCoordinates((ar[off[i]] or 0),let,moNum) end
  local wMin, wMax,hMin,hMax

  local w = tl.parseCoordinates(ar[1],"w",moNum) or nil
  local h = tl.parseCoordinates(ar[2],"h",moNum) or nil

  if not h  then
    hMin =  mon.topEdge+offcont.top or 0
    hMax =  mon.bottomEdge-(offcont.bottom or 0)
  else
    if offcont.right ~= nil and offcont.left ~= nil then offcont.right = nil end
    if offcont.right ~= nil then
      wMin = mon.rightEdge-(offcont.right or 0)-w
      wMax = mon.rightEdge-(offcont.right or 0)
    else
      wMin = mon.leftEdge+offcont.left or 0
      wMax = mon.leftEdge+(offcont.left or 0)+w
    end
  end

  if not w then
    wMin = mon.leftEdge+offcont.left or 0
    wMax = mon.rightEdge-(offcont.right or 0)
  else
    if offcont.bottom ~= nil and offcont.top ~= nil then offcont.bottom = nil end
    if offcont.bottom ~= nil then
      hMin = mon.bottomEdge-(offcont.bottom or 0)-(h)
      hMax = mon.bottomEdge-(offcont.bottom or 0)
    else
      hMin = mon.topEdge+offcont.top or 0
      hMax = mon.topEdge+(offcont.top or 0)+(h)
    end
  end
  if posW >= wMin and posW <= wMax and posH >= hMin and posH <= hMax then
     res = not res
    end
  tl.putNoLCD(w,h,posW,posH)
  return res
end

function tl.areaCheckWrapper(arg)
  if allType(arg,"table") then
    local andRay={}
    local orRay={}
    for g = 1, #arg do local ca = arg[g]
      if not ca.exclude then
        orRay[#orRay+1]= ca
      elseif tl.areaCheck(ca) == false then
        return false
      end
    end
    for i=1, #orRay do local ory = orRay[i]
      if tl.areaCheck(ory) then return true end
    end
    return false
  else
    return tl.areaCheck(arg)
  end
end

function tl.fastPos()
  if tl.mousePositionCheck ~= 1 then return GetMousePosition() end
  return tl.mouseHistory[tl.currentSample].w,tl.mouseHistory[tl.currentSample].h
end

function tl.mouseVelocity(target,min)
end

function tl.mouseCheckFunc()
  tl.mouseCount = tl.mouseCount +1
  if tl.mouseCount >= tl.mouseInterval then
    tl.currentSample = tl.currentSample + 1
    tl.mouseHistory[tl.currentSample]={}
    tl.mouseHistory[tl.currentSample].w,tl.mouseHistory[tl.currentSample].h =  GetMousePosition();
    if tl.currentSample == tl.mouseHistoryLimit then tl.currentSample = 1 end
    tl.mouseCount = 0
  end
end