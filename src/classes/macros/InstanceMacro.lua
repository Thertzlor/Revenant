local tl = ...---@type MainLibObject
local remove,type,insert,next,abs,pairs,error = table.remove,type,table.insert,next,math.abs,pairs,error
local MacroDefinition = tl:classImport('MacroDefinition')

local InstanceMacro = MacroDefinition:new()---@class InstanceMacro:MacroDefinition

local numericMethods = tl.tbl:propsFrom{"insert","listinsert","listreplace"}
local updateTypes = {r="replace",i="insert",d="delete",lr="listreplace",li="listinsert"};
for k, v in pairs(updateTypes) do updateTypes[v]=v end

local function walkTable(selector,target)
  local current = target
  local function getIndex(dex)
    return  ((type(dex) ~= "number" or dex > 0) and dex) or #current + dex 
  end
  local key = remove(selector)
  for i = 1, #selector do  current = current[getIndex(selector[i])] end
  return current,getIndex(key)
end

function InstanceMacro:updateProcess(update,target)
  local updato = update[1]
  if type(updato) ~= "table" then updato = {updato} end
  local targTab, valName = _tabulate(updato, nil, nil, target)
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

function InstanceMacro:updateMain(update,target)
  local total = #update
  local processed = 0

  local function processContent(method,selector,subject)
    if type(selector[#selector]) == "string" then
      if numericMethods[method] then error("update method "..method.." can only be applied to numeric keys. Current target is property key "..selector[#selector]) 
      elseif method == "delete" and subject then error("positional deletions are only valid for numeric keys.") end
    end
    local table,key = walkTable(selector,target)
    if method == "replace" then table[key] = subject
    elseif method == "insert" then insert(table,key,subject)
    elseif method == "delete" then
      if type(key) == "string" then table[key] = nil else
        subject = subject or 0
        remove(table,key)
        for i = 1, abs(subject) do remove(table,(key - ((subject > 0 and 1) or 0))) end
      end
    end
  end

  local function advancedUpdate(method,selector,subject,source)
    if source then 
      local referencedMacro = self.profile.macroIndex[self:awaitId(source)]
      local tab,dex = walkTable(subject,referencedMacro.raw)
      subject = tab[dex]
    end
    if tl.tbl:isSingleTypeTable(selector,"table") then
      for i = 1, #selector do processContent(method,selector[i],subject) end 
    else processContent(method,selector,subject) end
    processed = processed +1
    if processed == total then self:finalize(target) end
  end

  for k, v in pairs(update) do
    if(type(k) == "string") then target[k] = v else
      local firstArg = updateTypes(v[1])
      local base = (firstArg and 0) or 1
      local method = firstArg or "replace"
      local selector = type(v[base+1]) == "table" and v[base+1] or {v[base+1]}
      local subject = v[base+2]
      local source = v[base+3]
      if subject and type(source) == "string" and type(subject) ~= "table" then subject = {subject}
      else source = nil end
      self:async(advancedUpdate,method,selector,subject,source)
    end
  end
end

function InstanceMacro:finalize(newRaw)
  if self.init then return end
  local subClass = self.profile:getMacroClass(newRaw)---@type MacroDefinition
  local subId = subClass:new(newRaw,self.profile,self.options,self.overrides,self.stack,self.sourceDevice):awaitOwnId()
  self.subMacros[#self.subMacros+1] = subId
  self:finishInit()
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
    if myUpdate then self:updateMain(myUpdate,newRaw) else self:finalize(newRaw) end
  end
end

return InstanceMacro