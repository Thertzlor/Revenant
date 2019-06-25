local tl = ...
--> Functions that deal with calculating screen resolution and mouse position for area and velocity checks. ----------------------

function tl.compileScreenCoordinates()

  if tl.allType(tl.resolutions,"table") == false then
    tl.resolutions= {{
      x=tl.resolutions[1],
      y=tl.resolutions[2],
      [1]=nil,
      [2]=nil,
      posH = 65535, 
      posW = 65535, 
      virtW = 65535, 
      virtH = 65535,
      main = 1,
      topEdge = 0,
      rightEdge = 0
    }}
    tl.resolutions[1].ratio= (tl.resolutions[1].x/tl.resolutions[1].y)
  else
    local alignments={
      top = function(w,h,lastX,lastY,currentX,currentY) return {0,currentX} end,
      bottom = function() end,
      center = function() end,
      left = function() end,
      right = function() end,
      ["vertical-center"] = function() end,
    }
    local align = resolutions.align or "bottom"
    local mainScreenNum
    for i=1, #tl.resolutions do
      if mainScreenNum == nil and #tl.resolutions[i].main ~= nil then
        mainScreenNum = i
        tl.resolutions[1] = {
          x=tl.resolutions[1],
          y=tl.resolutions[2],
          [1]=nil,
          [2]=nil,
          posH = 65535, 
          posW = 65535, 
          virtW = 65535, 
          virtH = 65535,
          main = 1,
          topEdge = 0,
          rightEdge = 0
        }
        break
      end
    end
    local mainScreen = tl.resolutions[mainScreenNum]; 
    for i=1,#tl.resolutions do
      tl.resolutions[i].x = tl.resolutions[i][1]
      tl.resolutions[i].y = tl.resolutions[i][2]
      tl.resolutions[i].x = nil
      tl.resolutions[i].y = nil
      tl.resolutions[i].posH = tl.resolutions[i].x/mainScreen.x
      tl.resolutions[i].posW = tl.resolutions[i].x/mainScreen.y
      tl.resolutions[i].ratio= (tl.resolutions[i].x/tl.resolutions[i].y)
    end
    local offX=0;
    local offY=0;
    local monW
    local monH
    local leftVals,rightVals,topVals,bottomVals = {},{},{},{}

    for i = mainScreenNum-1,i>0, i-1 do local mon = tl.resolutions[i]
      if mon == nil then break end
      if align == "top" then
        mon.topEdge = mon.topEdge or 0 
        mon.rightEdge = mon.rightEdge or offX;
        offX = offX - mon.posW
      elseif align == "bottom" then
        mon.topEdge = mon.topEdge or mainScreen.posH-mon.posH
        mon.rightEdge = mon.rightEdge or offX;
        offX = offX - mon.posW
      elseif align == "center" then
        mon.topEdge = mon.topEdge or (mainScreen.posH-mon.posH)/2
        mon.rightEdge = mon.rightEdge or offX;
        offX = offX - mon.posW
        --vertical alignments here
      elseif align == "left" then
        offY = offY + tl.resolutions[i+1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or mon.posH
      elseif align == "right" then
        offY = offY + tl.resolutions[i+1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or mainScreen.posW-mon.posW
      elseif align =="vertical-center" then
        offY = offY + tl.resolutions[i+1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or (mainScreen.posW-mon.posW)/2
      end
      mon.leftEdge = mon.rightEdge - mon.posW
      mon.bottomEdge = mon.topEdge + mon.posH
      leftVals[#leftVals+1] = mon.leftEdge
      rightVals[#rightVals+1] = mon.rightEdge
      topVals[#topVals+1] = mon.topEdge
      bottomVals[#bottomVals+1] = mon.bottomEdge
    end

    for i = mainScreenNum+1,#tl.resolutions do local mon = tl.resolutions[i]
      if mon == nil then break end
      if align == "top" then
        offX = offX + tl.resolutions[i-1].posW
        mon.topEdge = mon.topEdge or 0 
        mon.rightEdge = mon.rightEdge or offX;
      elseif align == "bottom" then
        offX = offX + tl.resolutions[i-1].posW
        mon.topEdge = mon.topEdge or mainScreen.posH-mon.posH
        mon.rightEdge = mon.rightEdge or offX;
      elseif align == "center" then
        offX = offX + tl.resolutions[i-1].posW
        mon.topEdge = mon.topEdge or (mainScreen.posH-mon.posH)/2
        mon.rightEdge = mon.rightEdge or offX;
        --vertical alignments here
      elseif align == "left" then
        offY = offY - tl.resolutions[i-1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or mon.posH
      elseif align == "right" then
        offY = offY - tl.resolutions[i-1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or mainScreen.posW-mon.posW
      elseif align =="vertical-center" then
        offY = offY - tl.resolutions[i-1].posH
        mon.topEdge = mon.topEdge or offY
        mon.rightEdge = mon.rightEdge or (mainScreen.posW-mon.posW)/2
      end
      mon.leftEdge = mon.rightEdge - mon.posW
      mon.bottomEdge = mon.topEdge + mon.posH
      leftVals[#leftVals+1] = mon.leftEdge
      rightVals[#rightVals+1] = mon.rightEdge
      topVals[#topVals+1] = mon.topEdge
      bottomVals[#bottomVals+1] = mon.bottomEdge
    end
    tl.virtualDesktop.leftEdge = math.min(unpack(leftVals))
    tl.virtualDesktop.rightEdge = math.max(unpack(rightVals))
    tl.virtualDesktop.topEdge = math.min(unpack(topVals))
    tl.virtualDesktop.bottomEdge = math.max(unpack(bottomVals))
    tl.virtualDesktop.realX = math.abs(tl.virtualDesktop.rightEdge-tl.virtualDesktop.leftEdge)
    tl.virtualDesktop.realY = math.abs(tl.virtualDesktop.topEdge-tl.virtualDesktop.bottomEdge)
  end
end

function tl.getMonitor()
  if #tl.resolutions == 1 then return 1 end
  local cx,cy = GetMousePosition()
  local monRes = 1 
  for d=1,#tl.resolutions do local mon = tl.resolutions[d]
    if cx >= mon.leftEdge and cx <= mon.rightEdge and cy >= mon.topEdge and cy <= mon.bottomEdge then 
      monRes = d 
      break 
    end
  end
  return monRes
end

function tl.coordinate(c,t,r)
  if c == nil then return nil end
  local ratio = tl.resolutions[tl.getMonitor()].ratio
  local xy = {x=tl.resolutions[tl.getMonitor()].x,y=(tl.resolutions[tl.getMonitor()].y*ratio)}
  local parsed = nil
  if type(c) == "number" or (type(c) == "string" and string.sub(c,-2) == "px") ~= nil then
    parsed = ((tonumber(string.gsub(c,"[^%d]*$",""),_) or 0) / xy[t] * 65535)
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
  local xDeviation =  (65535/mon.x)
  local yDeviation =  (65535/mon.y)
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
    xc,yc = tl.currentPos()
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
  val = (val/65535)*monRes
  end
  return val
end

function tl.areaCheck(ar,out)
  local ratio = tl.resolutions[tl.getMonitor()].ratio
  local res = false
  if out then res = true end
    local posX, posY = tl.currentPos()
  local off = {"top","bottom","left","right"}
  local offcont={}
  for i=1, #off do local let="y" if i>2 then let="x"end offcont[off[i]] = tl.coordinate(ar[off[i]],let) end
  local xMin, xMax,yMin,yMax

  local w = tl.coordinate(ar[1],"x",true) or nil
  local h = tl.coordinate(ar[2],"y",true) or nil

  if h == nil then
    yMin = offcont.top or 0
    yMax = 65535-(offcont.bottom or 0)
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
      yMin = 65535-(offcont.bottom or 0)-(h*ratio)
      yMax = 65535-(offcont.bottom or 0)
    else
      yMin = offcont.top or 0
      yMax = (offcont.top or 0)+(h*ratio)
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

function tl.currentPos()
  if tl.mousePositionCheck ~= 1 then return GetMousePosition() end
  return tl.mouseHistory[tl.currentSample].x,tl.mouseHistory[tl.currentSample].y
end

function tl.mouseVelocity(target,min)
end

function tl.mouseCheckFunc()
  tl.mouseCount = tl.mouseCount +1
  if tl.mouseCount >= tl.mouseInterval then
    tl.currentSample = tl.currentSample + 1
    tl.mouseHistory[tl.currentSample]={}
    tl.mouseHistory[tl.currentSample].x,tl.mouseHistory[tl.currentSample].y =  GetMousePosition();
    if tl.currentSample == tl.mouseHistoryLimit then tl.currentSample = 1 end
    tl.mouseCount = 0
  end
end