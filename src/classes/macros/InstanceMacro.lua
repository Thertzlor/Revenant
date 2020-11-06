local tl = ...---@type MainLibObject
local remove,type,insert,next,abs,pairs,error = table.remove,type,table.insert,next,math.abs,pairs,error
local MacroDefinition = tl:classImport('MacroDefinition')

local InstanceMacro = MacroDefinition:new()---@class InstanceMacro:MacroDefinition

local numericMethods = tl.tbl:propsFrom{"insert","listinsert","listreplace"}
local updateTypes = {r="replace",i="insert",d="delete",lr="listreplace",li="listinsert"};
for k, v in pairs(updateTypes) do updateTypes[v]=v end

local function _walkTable(selector,target)
  local current = target
  local function getIndex(dex)
    return  ((type(dex) ~= "number" or dex > 0) and dex) or #current + dex 
  end
  local key = remove(selector)
  for i = 1, #selector do  current = current[getIndex(selector[i])] end
  return current,getIndex(key)
end

function InstanceMacro:updateMain(update,target)
  local total = #update
  local processed = 0

  local function processContent(method,selector,subject)
    if type(selector[#selector]) == "string" then
      if numericMethods[method] then error("update method "..method.." can only be applied to numeric keys. Current target is property key "..selector[#selector]) 
      elseif method == "delete" and subject then error("positional deletions are only valid for numeric keys.") end
    end
    local table,key = _walkTable(selector,target)
    if method == "replace" then table[key] = subject
    elseif method == "insert" then insert(table,key,subject)
    elseif method == "listinsert" then for i = 1, #subject do insert(table,key,subject[#subject-i+1]) end 
    elseif method == "listreplace" then remove(table,key) for i = 1, #subject do insert(table,key,subject[#subject-i+1]) end 
    elseif method == "delete" then
      if type(key) == "string" then table[key] = nil else
        subject = subject or 0
        remove(table,key)
        for i = 1, abs(subject) do remove(table,(key - ((subject > 0 and 1) or 0))) end
      end
    end
  end

  local function advancedUpdate(updateInput)
    local method = updateInput[1]
    local selector = type(updateInput[2]) == "table" and updateInput[2] or {updateInput[2]}
    local subject = updateInput[3]
    local source = updateInput[4]
    if subject and type(source) == "string" and type(subject) ~= "table" then subject = {subject}
    else source = nil end
    if source then 
      local referencedMacro = self.profile.macroIndex[self:awaitId(source)]
      local tab,dex = _walkTable(subject,referencedMacro.raw)
      subject = tab[dex]
    end
    if tl.tbl:isSingleTypeTable(selector,"table") then
      for i = 1, #selector do processContent(method,selector[i],subject) end 
    else processContent(method,selector,subject) end
    processed = processed +1
    if processed == total then self:finalize(target) end
  end
  if(#update ~= 0 and tl.tbl:hasProperties(update) and not tl.tbl:isSingleTypeTable(update,"table")) then error("malformed update"..((self.name and "on macro "..self.name )or "")) end
  if(tl.tbl:isSingleTypeTable(update,"table") or tl.tbl:hasProperties(update))then
    for k, v in pairs(update) do
     if(type(k) == "string") then target[k] = v else self:async(advancedUpdate,v)end
    end
  else self:async(advancedUpdate,update) end
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