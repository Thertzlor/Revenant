local tl = ...
--> Functions that deal with calculating screen resolution and mouse position for area and velocity checks. ----------------------

function tl.compileScreenCoordinates()
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

--alignments = bottom, top, center , right, left, vertical-center


  for i = mainNum-1, 1, -1 do local mon = tl.resolutions[i] local lastMon = tl.resolutions[i+1]
   --top
    if align == "top" or align == "bottom" or align == "center" then
      if mon.manualRight then
        mon.noOffsetRightEdge = mon.manualRight + mon.logiScaleOffsetX
      else
        mon.rightEdge = lastMon.leftEdge - mainMon.xPixel - mon.logiScaleOffsetX
        mon.noOffsetRightEdge = lastMon.noOffsetLeftEdge - mainMon.xPixel
      end
      mon.leftEdge = mon.rightEdge - mon.locatorW
      mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW
    elseif align == "left" then
    
    elseif align == "right" then
    
    elseif align == "vertical-center" then
    
    end


    if mon.manualTop then
      mon.noOffsetTopEdge= mon.topEdge
    elseif align == "left" or align == "right" or align == "vertical-center" then
      mon.topEdge=lastMon.bottomEdge+mainMon.yPixel
      mon.noOffsetBottomEdge=lastMon.noOffsetBottomEdge+mainMon+yPixel
    elseif align == "top" then
      mon.topEdge = mon.manualTop or 0
      mon.noOffsetTopEdge = mon.manualTop or 0
    elseif align == "bottom" then 
      mon.topEdge = mainMon.bottomEdge + mon.locatorH + mon.logiScaleOffsetY
      mon.noOffsetTopEdge = mainMon.noOffsetBottomEdge + mon.noOffsetLocatorH 
    elseif align == "center" then
      mon.topEdge = (mainMon.locatorH - mon.noOffsetLocatorH)/2
    end
    mon.bottomEdge = mon.topEdge+mon.locatorH
    mon.noOffsetBottomEdge = mon.noOffsetTopEdge+mon.noOffsetLocatorH

  end

  for i = mainNum+1, #tl.resolutions do local mon = tl.resolutions[i]
    local lastMon = tl.resolutions[i-1]

    if align == "top" or align == "bottom" or align == "center" then 
      if mon.manualRight then
        mon.noOffsetRightEdge = mon.manualRight - mon.logiScaleOffsetX
      else
        mon.rightEdge = lastMon.rightEdge + mon.locatorW + mon.logiScaleOffsetX + mainMon.xPixel
        mon.noOffsetRightEdge = lastMon.noOffsetRightEdge + mon.noOffsetLocatorW + mainMon.xPixel
      end
      mon.leftEdge = mon.rightEdge - mon.locatorW
      mon.noOffsetLeftEdge = mon.noOffsetRightEdge - mon.noOffsetLocatorW
    elseif align == "left" then
    
    elseif align == "right" then
    
    elseif align == "vertical-center" then
    
    end


    if mon.manualTop then
      mon.noOffsetTopEdge= mon.topEdge
    elseif align == "left" or align == "right" or align == "vertical-center" then
      mon.topEdge=lastMon.topEdge+mon.locatorH+mainMon.yPixel
      mon.noOffsetTopEdge=lastMon.noOffsetTopEdge+mon.NoOffsetLocatorH+mainMon+yPixel
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
  end

end

function tl.getMonitor()
  if #tl.resolutions == 1 then return 1 end
  local cx,cy = GetMousePosition()
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

function tl.coordinate(c,t,r)
  if c == nil then return nil end
  local ratio = tl.resolutions[tl.getMonitor()].ratio
  local xy = {x=tl.resolutions[tl.getMonitor()].w,y=(tl.resolutions[tl.getMonitor()].h*ratio)}
  local parsed = nil
  local numValue = (tonumber(string.gsub(c,"[^%d]*$",""),_) or 0)
  if type(c) == "number" or (type(c) == "string" and string.sub(c,-2) == "px") ~= nil then
    parsed = math.floor(numValue * (2^16-1) / (xy[t]-1) + 0.5)

  elseif type(c) == "string" then
    if string.sub(c,1,1) == "." then
      parsed = (((tonumber(string.gsub(c,"^[^%d]*","0."),_) or 0) * 65535))
      if t == "y" then parsed = parsed/ratio end
    elseif string.sub(c,-1) == "l" then
      parsed = (tonumber(string.gsub(c,"[^%d]*$",""),_) or 0)
    end
  end
  if parsed and r == nil and parsed < 0 then parsed = 65535 + parsed end
  return parsed
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
  local xc,yc = GetMousePosition()
  local startX,startY = GetMousePosition()
  local xDeviation =  (65535/mon.w)
  local yDeviation =  (65535/mon.h)
  local xDiff = x-startX
  local yDiff = y*ratio-startY
  while math.abs(xc - x) > xDeviation or math.abs(yc - y*ratio) > yDeviation do
    --tl.put(xc,x,"\n",yc,y)
    local fraction = (GetRunningTime() - startTime)/time
    if fraction > 1 then fraction = 1 end
    moveFunc(startX+(xDiff*fraction),(startY+(yDiff*fraction)))
    tl.wait(tl.PollInterval)
    xc,yc = GetMousePosition()
  end
end

function tl.mouseMove(arg,rel,dir)
  local moveFunc = MoveMouseToVirtual;
  if #tl.resolutions == 1 then moveFunc = MoveMouseTo end
  local playMode = arg.play or "normal"
  if ((playMode == "normal" or playMode == "toggle") and (dir ~= nil and dir ~= "down") and arg.direction ~= "up") or (arg.direction == "up" and dir=="down") then
    return
  end
  local process = tl.coordinate
  if rel then process = function(f) return f end end
  local mon = tl.resolutions[tl.getMonitor()]
  local ratio = mon.ratio
  local x,y,xc,yc = 0,0,0,0
  if rel == nil then
    xc,yc = tl.fastPos()
  end

  if type(arg) ~= "table" then
    x= process(arg,"x",rel)
    y=yc*ratio
  else
    x = process(arg[1],"x") or xc
    y = process(arg[2],"y") or yc
  end

  if arg[3] then
    if tl.TaskList[arg.pID] == nil then 
      if coroutine.running() then
        tl.moveUntil(x,y,arg[3])
      else 
        tl.TaskRun(arg.pID,tl.moveUntil,x,y,arg[3])
      end
    elseif (dir == "up" and arg.play == "hold") or (dir == "down" and arg.play == "toggle")  then
      tl.TaskAbort(arg.pID)
    end
  elseif rel then 
    MoveMouseRelative(x,y*ratio)
  else
    moveFunc(x,y*ratio)
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

function tl.areaCheck(ar,out)
  local mon = tl.resolutions[ar.monitor or tl.mainPos]
  local res = false
  if out then res = true end
    local posX, posY = tl.fastPos()
  local off = {"top","bottom","left","right"}
  local offcont={}
  for i=1, #off do local let="y" if i>2 then let="x"end offcont[off[i]] = tl.coordinate(ar[off[i]],let) end
  local xMin, xMax,yMin,yMax

  local w = tl.coordinate(ar[1],"x",true) or nil
  local h = tl.coordinate(ar[2],"y",true) or nil

  if h == nil then
    yMin =  offcont.top or 0
    yMax =  65535-(offcont.bottom or 0)
  else
    if offcont.right ~= nil and offcont.left ~= nil then offcont.right = nil end
    if offcont.right ~= nil then
      xMin = 65535-(offcont.right or 0)-w
      xMax = 65535-(offcont.right or 0)
    else
      xMin = offcont.left or 0
      xMax = (offcont.left or 0)+w
    end
  end

  if w == nil then
    xMin = offcont.left or 0
    xMax = 65535-(offcont.right or 0)
  else
    if offcont.bottom ~= nil and offcont.top ~= nil then offcont.bottom = nil end
    if offcont.bottom ~= nil then
      yMin = 65535-(offcont.bottom or 0)-(h*mon.ratio)
      yMax = 65535-(offcont.bottom or 0)
    else
      yMin = offcont.top or 0
      yMax = (offcont.top or 0)+(h*mon.ratio)
    end
  end
    if
    posX >= xMin and posX <= xMax
    and
    posY >= yMin and posY <= yMax
    then
     res = not res
    end
  --tl.putNoLCD(w,h,posX,posY)
  return res
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