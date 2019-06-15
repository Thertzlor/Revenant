
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
  
  function tl.preRay(rayz,del) --pressing down an array of buttons in order
    for i=1,#rayz do local obj = rayz[i]
      if type(obj) == "string" then
        tl.Press(obj)
        if del then del=del  else del=tl.keyDelay end
        tl.wait(del)
      end
    end
  end
  
  function tl.relRay(rayz,del) --...and releasing an array of buttons in order
    tl.Reverse(rayz)
    for i=1,#rayz do local obj = rayz[i]
      if type(obj) == "string" then
        tl.Release(obj)
        if del then del=del else del=tl.keyDelay end
        tl.wait(del)
      end
    end
    tl.Reverse(rayz)
  end
  
  function tl.bothRay(blu,del) --press an array of keys, then release it.
    tl.preRay(blu,del)
    if del then tl.wait(del) end
    tl.relRay(blu,del)
  end
  
  function tl.typer(tstring,del,kdel,aDev,kDev) --function for deciding how to type different strings and arrays
    local wt = del or tl.actionDelay
    local kwt = kdel or tl.keyDelay
    if (#tstring == 1 or (string.sub(tstring,0,1) == "/" and (#tstring == 2 or (#tstring == 3 and tonumber(string.sub(tstring,2,3)) < 25)))) then
      tl.PressAndRelease(tstring,kwt,kDev)
    else
      tl.TypeString(tstring,wt,kwt)
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
        tl.Release(va,0,1)
      end
    end
    tl.wipe(tl.roDown[there])
  end