local tl = ...---@type MainLibObject
local remove,unpack,type,insert,next = remove,unpack,type,insert,next
local BaseMacro = tl:classImport('BaseMacro')---@type BaseMacro

---@class LinkMacro:BaseMacro
---@field profile ProfileDefinition
local LinkMacro = BaseMacro:new()

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

function LinkMacro:parseSubMacros()
  local target = self.profile.macroIndex[self:awaitId(self.cmd[1])]
  if not next(self.options) then
    local final = target:new()
    final.pID=final:genId()
    if not self.profile.config.linkStateShare then
      final.state={}
    end
  end
  local newRaw = tl.tbl:intersectSimple(target.command,target.options)
  local tabula
  self:finishInit()
end

function LinkMacro:execute(event)
  if #self.subMacros == 0 then self:resolveLink() end
  local endMacro =  self.profile.macroIndex[self.subMacros[#self.subMacros] or "null"]
  if endMacro then endMacro:run(event) end
end

return LinkMacro