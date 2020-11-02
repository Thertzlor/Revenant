local tl = ...---@type MainLibObject
local remove,unpack,type,insert,next,abs = remove,unpack,type,insert,next,math.abs
local MacroDefinition = tl:classImport('MacroDefinition')

local InstanceMacro = MacroDefinition:new()---@class InstanceMacro:MacroDefinition

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

function InstanceMacro:updateProcess(update,target)
  local h = update[1]
  if type(h) ~= "table" then h = {h} end
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
      for _ = 1, g do remove(targTab, posi) end
    end
  end
end

function InstanceMacro:parseInstructions()
  self.command = self.rawCommand[1]
  local target = self.profile.macroIndex[self:awaitId(self.command)]
  if not next(self.options) then
    local final = target:new() ---@type MacroDefinition
    final.pID=final:genId()
    final.sourceDevice = self.sourceDevice
    final.state={}
    self.profile.macroIndex[final.pID] = final
    self.subMacros[#self.subMacros+1] = final.pID
  else
    local myUpdate = self.options.update
    local newType = self.options.newType
    self.options.newType = nil
    self.options.update = nil
    local newRaw = tl.helperUtils.deepCopy(target.raw)
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

return InstanceMacro