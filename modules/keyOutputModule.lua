local tl = ...

--->>> Output functions nabbed from ll.project (modified) ===============================================================================

function tl.isMouseButton(key)
    local b
    if key and string.sub(key,1,2) == "mb" then
      b = tonumber( string.sub(key,3) )
    end
    return b or false
  end
  
  function tl.Press(key, delay)		-- delay is optional for a delay between pressing modifiers before the primary key if there is one.
    -- tl.put("pressing "..key)
    tl.addDown(key)
    local k = tl._KEYBOARD[key]
    delay = delay or 0
  
    if k then
      if k.key then
        tl.__PressKey(k, delay)
      elseif k[1] then		-- if there is no key, there are tables of keys.
        local n
        n = table.maxn(k)
        for i = 1, n do
          tl.__PressKey(k[i], delay)
        end
      elseif k.mb then
        PressMouseButton(k.mb)
      end
    elseif key ~="" then
      if tl.logiKeys[key] then PressKey(key) return true else tl.remDown(key) tl.quiKey({key}) return end
    end
  end
  
  function tl.Release(key, delay,sil)		-- delay is optional for a delay between pressing modifiers before the primary key if there is one.
    local k = tl._KEYBOARD[key]
    delay = delay or 0
    if k then
      if k.key then
        tl.__ReleaseKey(k, delay)
      elseif k[1] then		-- if there is no key, there are tables of keys.
        local n
        n = table.maxn(k)
        for i = 1, n do
          tl.__ReleaseKey(k[i], delay)
        end
      elseif k.mb then
        ReleaseMouseButton(k.mb)
      end
    elseif key ~="" and tl.logiKeys[key] then
      ReleaseKey(key)
    end
    tl.remDown(key,sil)
  end
  
  function tl.PressAndRelease(key, delax)	-- delay is optional delay between all press and releases of keys
    tl.addDown(key)
    local k = tl._KEYBOARD[key]
    local delay = delax or tl.keyDelay
    if k and k[1] then	-- a multiple key press key is found, we must handle key key separate.
      local n
      n = table.maxn(k)
      for i=1, n do
        tl.__PressKey(k[i], delay)
        if delay ~=0 then tl.wait(delay) end
        tl.__ReleaseKey(k[i], delay)
        if i < n then
          tl.wait(delay)
        end
      end
    else
      tl.Press(key, delay)
      if delay ~=0 then tl.wait(delay) end
      tl.Release(key, delay)
    end
    tl.remDown(key)
  end
  
  function tl.__ReleaseKey(k, delay)
    ReleaseKey(k.key)
    if k.modifier then
      if delay then
        tl.wait(delay)
      else
        tl.wait(tl.keyDelay)
      end
  
      if type(k.modifier) == "table" then
        for i=1,#k.modifier do local v = k.modifier[i]
          ReleaseKey(v)
        end
      else
        ReleaseKey(k.modifier)
      end
    end
  end
  
  function tl.__PressKey(k, delay)
    if k.modifier then
      if type(k.modifier) == "table" then
        for i=1,#k.modifier do local v = k.modifier[i]
          PressKey(v)
        end
      else
        PressKey(k.modifier)
      end
      if delay then
        tl.wait(delay)
      else
       tl.wait(tl.keyDelay)
      end
    end
    PressKey(k.key)
  end
  
  function tl.TypeString(s, delay,kelay,aDev,kDev)			-- delay is optional tl.wait time between key presses
    local i, n, c

    n = # s
    i = 1
    while i <= n do
      c = string.sub(s, i, i)				-- get each character from s
      if c == "/" then					-- / signals special character, which is 2 characters wide
        if i < n then
          c = string.sub(s, i, i+1)
          i = i + 1
        else
          error("tl.TypeString(s, delay) - found a single / at end of string.  For a single /, put two in a row. i.e. //", 2)
        end
      end
      tl.PressAndRelease(c,kelay)
      if delay and i < n then
        --tl.put("waiting for "..delay.."ms")
        tl.wait(delay,aDev)
      end
      i = i + 1
    end
  end