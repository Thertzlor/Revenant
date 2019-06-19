local tl = ...
--> Functions that deal with calculating screen resolution and mouse position for area and velocity checks. ----------------------

function tl.compileScreenCoordinates()
    if tl.allType(tl.resolutions,"table") == false then
      tl.resolutions = {tl.resolutions}
      tl.normalizedScreens[1]={65535,65535,0,0}
    else
      local mainScreen
      for i=1, #tl.resolutions do
        if #tl.resolutions[i].main ~= nil then
          tl.normalizedScreens[i]={65535,65535,0,0}
          mainScreen = i 
          break 
        end 
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
          tl.normalizedScreens[i]={monW,monH,(offX-monOffX),offY}
        else
          tl.normalizedScreens[i]={monW,monH,mon.offsetX,mon.offsetY}
        end
        
      end
  
    end
  end

  function tl.getMonitor()
  if #tl.resolutions == 1 then return 1 end
  return 1
  end

  --]]
  function tl.coordinate(c,t,r)
  if c == nil then return nil end
  local xy = {x=tl.resolutions[1],y=tl.resolutions[2]}
  local parsed = nil
  if type(c) == "number" or (type(c) == "string" and string.match(c,"px$")) ~= nil then 
    parsed = ((tonumber(string.gsub(c,"[^%d]*$",""),_) or 0) / xy[t] * 65535)
  elseif type(c) == "string" then
    if string.match(c,"^.") ~= nil then
      parsed = (((tonumber(string.gsub(c,"^[^%d]*","0."),_) or 0)*65535))
    elseif string.match(c,"l$") ~= nil then
      parsed = (tonumber(string.gsub(c,"[^%d]*$",""),_) or 0)
    end
  end
  if parsed and r == nil and parsed < 0 then parsed = 65535 + parsed end
  return parsed
  end
  
  function tl.mouseMove(arg,rel)
    local x,y,xc,yc = 0,0,0,0
    if rel == nil then
      xc,yc = tl.currentPos()
    end
    
    if type(arg) ~= "table" then 
      x=tl.coordinate(arg,"x",rel)
      y=yc
    else
      x = tl.coordinate(arg[1],"x",rel) or xc
      y = tl.coordinate(arg[2],"y",rel) or yc
      
    end
    
    if rel then MoveMouseRelative(x,y) else
      MoveMouseToVirtual(x,y)
    end
  end
  ---[[
  function tl.areaCheck(ar,out)
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
        xMax = (offcont.left or 0)+h
      end
    end
  
    if w == nil then
      xMin = offcont.left or 0
      xMax = 65535-(offcont.right or 0)
    else
      if offcont.bottom ~= nil and offcont.top ~= nil then offcont.bottom = nil end 
      if offcont.bottom ~= nil then 
        yMin = 65535-(offcont.bottom or 0)-h
        yMax = 65535-(offcont.bottom or 0)
      else
        yMin = offcont.top or 0
        yMax = (offcont.top or 0)+h
      end
    end
  
      if
      posX >= xMin and posX <= xMax
      and 
      posY >= yMin and posY <= yMax
      then 
      res = not res
      end
    tl.put(w,h,posX,posY)
    return res
  end

  tl.currentPos = function()
    if tl.mousePositionCheck then 
      return tl.mouseX,tl.mouseY
    else
      return GetMousePosition()
    end
  end

  tl.mouseVelocity = function(target,min)
  end

  tl.mouseCheckFunc = function()
    tl.mouseCount = tl.mouseCount +1
    if tl.mouseCount >= tl.mouseInterval then
      if tl.mouseX then
        tl.lastX, tl.lastY = tl.mouseX, tl.mouseY
      else
        tl.lastX, tl.lastY = GetMousePosition()
      end
      tl.mouseX, tl.mouseY = GetMousePosition()    
    tl.mouseCount = 0
    end
  end