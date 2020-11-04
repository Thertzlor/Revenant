local tl = ...---@type MainLibObject
local type,running,concat = type,coroutine.running,table.concat
local MacroDefinition = tl:classImport('MacroDefinition')

local KeyMacro = MacroDefinition:new()---@class KeyMacro:MacroDefinition

---Handles the default key functions, called by key name or as simple sequence.
---@param tg string|table<string>
function KeyMacro:parseInstructions()
  local raw = self.rawCommand
  self.triggerMode = 0
  if self.type == "keydown" then  self.triggerMode = 1
  elseif self.type == "keyup" then self.triggerMode = 2
  elseif self.type == "wrapkey" then self.triggerMode = 3
  elseif self.type == "keytoggle" then 
    self.triggerMode = 3 
    self.singleTrigger = true
  end
  if type(raw) == "table" and #raw == 1 then
    self.command = raw[1]
  end
  self.titleExport = self.type..": "
  self:finishInit()
end

function KeyMacro:exportContent(depth)
  return type(self.command) == "table" and concat(self.command," + ") or self.command
end

---@param event Event
function KeyMacro:execute(event)
  local dir,vir,keyName,fam,num,triggerMode,toggled = 
  event.direction, event.virtualType, event.keyName, event.family, event.keyNum,self.triggerMode,self.profile.toggledKeys
  local press = self:keyPress(event)
  press.forceSleep = true
  local state = self.profile.deviceState
  local keyString = self.command
  local releaseToggle = false
  local runner = running()
  tl.eventHandler:swallowKeys()
  if (runner and triggerMode == 0) or (vir and triggerMode == 0 and (vir == 1 or dir == nil)) then
    if type(keyString) == "string" and (state[fam]["_b" .. num] or 
    not (tl.keys.keyboardDefinition[keyString] or tl.keyStates.logiKeys[keyString])) then tl.str:typingDelegator(keyString, press) else
      if type(keyString) ~= "table" then keyString = {keyString}end
      tl.str:bothRay(keyString, press)
      releaseToggle = true
    end
  else

    if (dir == "down" and triggerMode == 0) or triggerMode == 1 or 
    (triggerMode == 4 and (dir == "down" or vir)) or (triggerMode == 3 and toggled["_" .. keyName] == nil) then
      if triggerMode == 3 then
        toggled["_" .. keyName] = 1
      elseif triggerMode == 4 then
        local wrapperTargets = {key=state[fam]["_b" .. num], family = state[fam], global=state}
        local releaseWrapper = wrapperTargets[(self.scope) or "key"]
        if not releaseWrapper then 
          state[fam]["_b"..num] = {}
          releaseWrapper = state[fam]["_b"..num]
        end 
        if not releaseWrapper.wrapperContent then
          releaseWrapper.wrapperContent = {}
        end
        releaseWrapper.wrapperContent[#releaseWrapper.wrapperContent + 1] = keyString
      end
      if type(keyString) == "string" then
        tl.keys:press(tl.str:applyStringBuffer(keyString, press), press)
      elseif type(keyString) == "table" then
        tl.str:preRay(keyString, press)
      end
    elseif
      (dir == "up" and triggerMode == 0) or triggerMode == 2 or (dir == "down" and triggerMode == 3 and toggled["_" .. keyName] ~= nil)
     then
      if triggerMode ~= 5 then
        releaseToggle = true
      end
      if type(keyString) == "string" then
        tl.keys:release(tl.str:applyStringBuffer(keyString, press, 1), press)
      elseif type(keyString) == "table" then
        if keyString.unreverse ~= nil then
          tl.helperUtils.reverseTable(keyString)
        end
        tl.str:relRay(keyString, press)
        if keyString.unreverse ~= nil then
          tl.helperUtils.reverseTable(keyString)
        end
      end
      if triggerMode == 3 then
        toggled["_" .. keyName] = nil
      end
    end
  end
  if releaseToggle then
    tl.keys:autoRelease(press)
  end
if runner then tl.eventHandler:unswallowKeys() end
end

return KeyMacro