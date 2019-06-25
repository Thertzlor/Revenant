local tl = ...
--> Functions that deal with calculating screen resolution and mouse position for area and velocity checks. ----------------------

function tl.compileScreenCoordinates()
  if tl.allType(tl.resolutions,"table") == false then
    tl.resolutions = {tl.resolutions,posH = 65535, posW=65535, virtW=65535, virtH=65535,main=1,posOffsetX=0,posOffsetY=0,virtOffsetX=0,virtOffsetY=0}
    tl.resolutions[1].ratio= (tl.resolutions[1][1]/tl.resolutions[1][2])
  else
    local mainScreen
    for i=1, #tl.resolutions do
      if mainScreen == nil and #tl.resolutions[i].main ~= nil then
        mainScreen = i
      end
      tl.resolutions[i].ratio= (tl.resolutions[i][1]/tl.resolutions[i][2])
    end
    local offX=0;
    local offY=0;
    local monW
    local monH
    for i = mainScreen-1,i>0, i-1 do local mon = tl.resolutions[i]
      monW = tl.resolutions[mainScreen][1]/mon[1]*65535
      monH = tl.resolutions[mainScreen][2]/mon[2]*65535
      offX = offX - monW
      offY = mon.offsetY or 0
      if tl.resolutions.offSetmode ~= "absolute" then

      else

      end
    end
  end
end

function tl.getMonitor()
  if #tl.resolutions == 1 then return 1 end
  return 1
end

function tl.coordinate(c,t,r)
  if c == nil then return nil end
  local ratio = tl.resolutions[tl.getMonitor()].ratio
  local xy = {x=tl.resolutions[tl.getMonitor()][1],y=(tl.resolutions[tl.getMonitor()][2]*ratio)}
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
  local looplim = 0
  local mon = tl.resolutions[tl.getMonitor()]
  local ratio = mon.ratio
  local startTime = GetRunningTime()
  local xc,yc = GetMousePosition()
  local startX,startY = GetMousePosition()
  local xDeviation =  (65535/mon[1])
  local yDeviation =  (65535/mon[2])
  local xDiff = x-startX
  local yDiff = y*ratio-startY
  while math.abs(xc - x) > xDeviation or math.abs(yc - y*ratio) > yDeviation do
    --tl.put(xc,x,"\n",yc,y)
    local fraction = (GetRunningTime() - startTime)/time
    if fraction > 1 then fraction = 1 end
     MoveMouseToVirtual(startX+(xDiff*fraction),(startY+(yDiff*fraction)))
    tl.wait(tl.PollInterval)
    xc,yc = GetMousePosition()
  end
end

function tl.mouseMove(arg,rel,dir)
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
    MoveMouseToVirtual(x,y*ratio)
  end
end

function tl.unCoordinate(val,axis,unit)
  unit = unit or "px"
  local mon = tl.resolutions[tl.getMonitor()]
  local monRes = mon[1]
  if axis == "y" then monRes = mon[2] end
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
  if tl.mousePositionCheck == 1 then
    return tl.mouseX,tl.mouseY
  else
    return GetMousePosition()
  end
end

function tl.mouseVelocity(target,min)
end

function tl.mouseCheckFunc()
  tl.mouseCount = tl.mouseCount +1
  if tl.mouseCount >= tl.mouseInterval then
    tl.currentSample = tl.currentSample + 1
    tl.mouseHistory[tl.currentSample]={}
    tl.mouseHistory[tl.currentSample][1],tl.mouseHistory[tl.currentSample][2] =  GetMousePosition();
    if tl.currentSample == tl.mouseSamples then tl.currentSample = 0 end
    tl.mouseCount = 0
  end
end