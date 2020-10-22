local tl = ...---@type MainLibObject
local pairs = pairs
local BaseMacro = tl:classImport('BaseMacro')---@type BaseMacro

---@class GroupMacro:BaseMacro
---@field profile ProfileDefinition
local GroupMacro = BaseMacro:new()

function GroupMacro:parseInstructions()
  local processed=0  
  ---@param class BaseMacro
  local function subFetch(class)
    local classID = class:awaitOwnId()
    if classID then
     self.subMacros[#self.subMacros+1] = classID 
    end
    processed = processed +1
    if processed == #self.command then 
      if self:checkNecessity() then self.pID = self:genId() end
      self:finishInit()
    end
  end
  for i = 1, #self.command do local entry = self.command[i]
    local macroClass = tl.bindings:getMacroClass(entry)
    if macroClass then
      ---@type BaseMacro|GroupMacro
      local subClass = macroClass:new(entry,self.profile,self.options,self.overrides,self.stack)
      self:async(subFetch,subClass)
    end
  end
end

---@private
function GroupMacro:checkNecessity()
  if #self.subMacros > 1 then return true elseif #self.subMacros == 0 then return false end
  local entry = self.subMacros[1]
  if self.options.name and self.profile.macroIndex[entry].name then
    return self.name ~= entry.name
  end
  return false
end

function GroupMacro:execute(event)
  local entries = self.subMacros
  for i = 1, #entries do local entry = entries[i]
    self.profile.macroIndex[entry]:run(event)
  end
end
