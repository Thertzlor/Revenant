local tl = ...---@type MainLibObject
local remove,unpack,type,insert,next,abs = remove,unpack,type,insert,next,math.abs
local MacroDefinition = tl:classImport('MacroDefinition')

local LinkMacro = MacroDefinition:new()---@class LinkMacro:MacroDefinition
---Property override for linked macros
---@param u1 table
---@param u2 table
---@param button string
local function _mergeLinkUpdate(u1, u2, button)
  if u1 == nil and u2 == nil then
      return false
  end
  u1 = tl.helperUtils.deepCopy((u1 or {}), nil, button)
  if tl.tbl:isSingleTypeTable(u1, "table") == false then
      u1 = {u1}
  end
  if tl.tbl:isSingleTypeTable(u2, "table") == false then
      u2 = {u2}
  end
  for i = 1, #u2 do
      insert(u1, 1, u2[i])
  end
  return u1
end

local function _tabulate(tbl, startTable, noOff, fallbackTable)
  local minus = noOff or 1
  local position = startTable or fallbackTable or {}
  local finalValue = tbl[#tbl]
  for p = 1, #tbl - minus do
      if type(tbl[p]) == "number" and tbl[p] < 1 then
          tbl[p] = #position + tbl[p]
      end
      position = position[tbl[p]]
  end
  return position, finalValue
end

---Resolves and updates the references in "l" type macros.
---@param link LinkMacro
---@param button string
---@param parentUpdate table
---@return GenericMacro
function LinkMacro:resolveLink(link, button, parentUpdate)

  local lock = link
  local combinedID = ""
  local metaUpdate = parentUpdate
  while (lock.type == "l") and not tl.macroIndex[lock[1]]._dummy do -- If the binding is a link we override the original binding's properties with any new ones
      local lockTarget = lock[1]
      local rideNum = (lock.keepExisting == 1) and 4 or 3
      local lack
      local unlock = self.profile.macroIndex[lockTarget]
      combinedID = combinedID .. lock.pID .. unlock.pID
      if tl.tbl:isContainer(lock) then
          lack = tl.helperUtils.deepCopy(lock)
          for i = 1, #lack do
              lack[i] = self:resolveLink(lack[i], button, metaUpdate)
          end
          lack.pID = combinedID
          ---@type MacroStatContainer
          tl.macroIndex[combinedID] = tl.macroIndex[combinedID] or lack
          return lack
      else
          local currentUpdate = metaUpdate or lock.update
          metaUpdate = _mergeLinkUpdate(currentUpdate, unlock.update, button)
          lock = tl.tbl:intersect(unlock, lock, rideNum, lock.keepExisting)
          lack = tl.helperUtils.deepCopy(lock, nil, button)
          if metaUpdate ~= false and lack.type ~= "l" then
              if type(metaUpdate) == "table" then
                  local function _replaceCycle(reptable)
                      local h = reptable[1]
                      if type(h) ~= "table" then
                          h = {h}
                      end
                      local targTab, valName = _tabulate(h, nil, nil, lack)
                      local endInsert = reptable[2]
                      if type(reptable[4]) == "string" then
                          if type(reptable[2]) ~= "table" then
                              reptable[2] = {reptable[2]}
                          end
                          local importer = self:resolveLink(self.profile.macroIndex[reptable[4]], button)
                          endInsert, _ = _tabulate(reptable[2], importer, 0, lack)
                      end

                      if reptable[3] == nil or reptable[3] == "replace" then
                          targTab[valName] = endInsert
                      elseif reptable[3] == "insert" then
                          insert(targTab, valName, endInsert)
                      elseif reptable[3] == "remove" then
                          local g = reptable[2]
                          if type(g) == "string" then
                              targTab[valName][g] = nil
                          elseif g > 1 then
                              local posi = valName - 1
                              for _ = 1, abs(g) do
                                  remove(targTab, posi)
                                  posi = posi - 1
                              end
                          else
                              local posi = valName
                              for _ = 1, g do
                                  remove(targTab, posi)
                              end
                          end
                      end
                  end

                  if tl.tbl:isSingleTypeTable(metaUpdate, "table") == false then
                      _replaceCycle(metaUpdate)
                  else
                      for i = 1, #metaUpdate do
                          _replaceCycle(metaUpdate[i])
                      end
                  end
                  lock = lack
              end
          end
          lock.pID = combinedID
          ---@type MacroStatContainer
          tl.macroIndex[combinedID] = tl.macroIndex[combinedID] or lock
      end
  end
  return lock
end

function LinkMacro:updateProcess(update,target)
  local h = update[1]
  if type(h) ~= "table" then
      h = {h}
  end
  local targTab, valName = _tabulate(h, nil, nil, target)
  local endInsert = update[2]
  if type(update[4]) == "string" then
      if type(update[2]) ~= "table" then
          update[2] = {update[2]}
      end
      local importer = self.profile --self:resolveLink(self.profile.macroIndex[update[4]], button)
      endInsert, _ = _tabulate(update[2], importer, 0, target)
  end

  if update[3] == nil or update[3] == "replace" then
      targTab[valName] = endInsert
  elseif update[3] == "insert" then
      insert(targTab, valName, endInsert)
  elseif update[3] == "remove" then
      local g = update[2]
      if type(g) == "string" then
          targTab[valName][g] = nil
      elseif g > 1 then
          local posi = valName - 1
          for _ = 1, abs(g) do
              remove(targTab, posi)
              posi = posi - 1
          end
      else
          local posi = valName
          for _ = 1, g do
              remove(targTab, posi)
          end
      end
  end

end

function LinkMacro:parseInstructions()
  self.command = self.rawCommand[1]
  local target = self.profile.macroIndex[self:awaitId(self.command)]
  if not next(self.options) then
    local final = target:new() ---@type MacroDefinition
    final.pID=final:genId()
    tl:put("linky")
    final.sourceDevice = self.sourceDevice
    if not self.profile.config.linkStateShare then
      final.state={}
    end
    self.profile.macroIndex[final.pID] = final
    self.subMacros[#self.subMacros+1] = final.pID
  else
    local myUpdate = self.options.update
    local newType = self.options.newType
    self.options.newType = nil
    self.options.update = nil

    local newRaw = tl.tbl:intersectSimple(target.rawCommand,target.rawOptions)
    if newType then newRaw.type = newType end

    if myUpdate then
      if #myUpdate ~=0 and tl.tbl:isSingleTypeTable(myUpdate,"table") and not tl.tbl.hasProperties(myUpdate) then
        for i = 1, #myUpdate do self:updateProcess(myUpdate[i],newRaw) end
      else self:async(self.updateProcess,myUpdate,newRaw) end
    end

    local subClass = self.profile:getMacroClass(newRaw)---@type MacroDefinition
    local subId = subClass:new(newRaw,self.profile,self.options,self.overrides,self.stack,self.sourceDevice):awaitOwnId()
    self.subMacros[#self.subMacros+1] = subId
  end
  self:finishInit()
end

return LinkMacro