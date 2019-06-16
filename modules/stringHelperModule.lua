
local tl = ...
--->>>  Functions that process or type strings ==================================================================

function tl.querylize(query,targ) --implements a javascript-like "/.../" syntax for distinguishing between string and regex matches
    if string.match(query,"^/") and string.match(query,"/$") then
      if string.match(targ,string.sub(query,2,-2)) then return true end
    else
      return targ == query
    end
    return false
  end
  
  function tl.preRay(rayz,del,dev) --pressing down an array of buttons in order
    for i=1,#rayz do local obj = rayz[i]
      if type(obj) == "string" then
        tl.Press(obj,dev)
        local dela =del or tl.keyDelay
        tl.wait(dela,dev)
      end
    end
  end
  
  function tl.relRay(rayz,del,dev) --...and releasing an array of buttons in order
    tl.Reverse(rayz)
    for i=1,#rayz do local obj = rayz[i]
      if type(obj) == "string" then
        tl.Release(obj,nil,dev)
        if del then del=del else del=tl.keyDelay end
        tl.wait(del,dev)
      end
    end
    tl.Reverse(rayz)
  end
  
  function tl.bothRay(blu,del,dev) --press an array of keys, then release it.
    tl.preRay(blu,del,dev)
    if del then tl.wait(del,dev) end
    tl.relRay(blu,del,dev)
  end
  
  function tl.typer(tstring,del,kdel,actionDeviator,keyDeviator) --function for deciding how to type different strings and arrays
    local wt = del or tl.actionDelay
    local kwt = kdel or tl.keyDelay
    if (#tstring == 1 or (string.sub(tstring,0,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(string.sub(tstring,2,3)) < 25)))) then
      tl.PressAndRelease(tstring,kwt,keyDeviator)
    else
      tl.TypeString(tstring,wt,kwt,actionDeviator,keyDeviator)
    end
  end
    
  function tl.addDown (key) --adds currently pressed down keys
    if tl.cutine ~=0 then
      tl.roDown[tl.cutine][#tl.roDown[tl.cutine]+1] = key
    end
  end
  
  function tl.remDown(key,sil) --removes keys from the held down list, when they are released again
    if sil then
      return
    -- else tl.put("removing "..tostring(key))
    end
    if tl.cutine ~=0 then
      for i, va in pairs(tl.roDown[tl.cutine]) do
        if va == key then
          tl.roDown[tl.cutine][i]= nil
        end
      end
    end
  end
  
  function tl.allUp(there) --Releases all keys currently locked/held down, called at the end of the script.
    for _, va in pairs(tl.roDown[there]) do
      if va ~= nil then
        tl.put("auto-released "..va)
        tl.Release(va,0,nil,1)
      end
    end
    tl.wipe(tl.roDown[there])
  end