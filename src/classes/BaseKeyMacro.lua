local tl = ...---@type MainLibObject
local type,running = type,coroutine.running
---@type BaseMacro
local BaseMacro = tl:classImport('BaseMacro')


---@class BaseKeyMacro:BaseMacro
local BaseKeyMacro = BaseMacro:new()
---Handles the default key functions, called by key name or as simple sequence.
---@param tg string|table<string>
---@param dir string
---@param triggerMode number
---@param vir number
---@param bId string
---@param del number
---@param dev number
---@param fam string
---@param num number
function BaseKeyMacro:execute(event,option)
  local dir,vir,bId,fam,num,del,dev, triggerMode,toggled = event.dir,event.vir,event.bId,event.fam,event.num,self.options.delay,self.options.deviation,self.triggerMode,self.originProfile.toggledKeys

  local keyString = self.command
  if type(keyString) == "table" and #keyString == 1 then
    keyString = keyString[1]
  end
  local releaseToggle = false
  if (running() and triggerMode == 0) or (vir and triggerMode == 0 and (vir == 1 or dir == nil)) then
    if type(keyString) == "string" and (tl.deviceState[fam]["_b" .. num] or not (tl.keys.keyboardDefinition[keyString] or tl.keyStates.logiKeys[keyString])) then
      tl.str:typingDelegator(tl.str:applyStringBuffer(keyString, fam, num, 1), nil, del, nil, dev, fam, num)
    else
      if type(keyString) ~= "table" then keyString = {keyString}end
      tl.str:bothRay(keyString, del, dev, fam, num)
      releaseToggle = true
    end
  else
    if
      (dir == "down" and triggerMode == 0) or triggerMode == 1 or (triggerMode == 4 and (dir == "down" or vir)) or
        (triggerMode == 3 and toggled["_" .. bId] == nil)
     then
      if triggerMode == 3 then
        toggled["_" .. bId] = 1
      elseif triggerMode == 4 then
        local wrapperTargets = {key=tl.deviceState[fam]["_b" .. num], family = tl.deviceState[fam], global=tl.deviceState}
        local releaseWrapper = wrapperTargets[(self.scope) or "key"]
        if not releaseWrapper then 
          tl.deviceState[fam]["_b"..num] = {}
          releaseWrapper = tl.deviceState[fam]["_b"..num]
        end 
        if not releaseWrapper.wrapperContent then
          releaseWrapper.wrapperContent = {}
        end
        releaseWrapper.wrapperContent[#releaseWrapper.wrapperContent + 1] = keyString
      end
      if type(keyString) == "string" then
        tl.keys:press(tl.str:applyStringBuffer(keyString, fam, num), del, dev, fam, num)
      elseif type(keyString) == "table" then
        tl.str:preRay(keyString, del, dev, fam, num)
      end
    elseif
      (dir == "up" and triggerMode == 0) or triggerMode == 2 or (dir == "down" and triggerMode == 3 and toggled["_" .. bId] ~= nil)
     then
      if triggerMode ~= 5 then
        releaseToggle = true
      end
      if type(keyString) == "string" then
        tl.keys:release(tl.str:applyStringBuffer(keyString, fam, num, 1), del, dev)
      elseif type(keyString) == "table" then
        if keyString.unreverse ~= nil then
          tl.helperUtils.reverseTable(keyString)
        end
        tl.str:relRay(keyString, del, dev)
        if keyString.unreverse ~= nil then
          tl.helperUtils.reverseTable(keyString)
        end
      end
      if triggerMode == 3 then
        toggled["_" .. bId] = nil
      end
    end
  end
  if releaseToggle then
    tl.keys:autoRelease(fam, num, del, dev)
  end
end

return BaseKeyMacro