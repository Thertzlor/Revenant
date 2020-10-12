local tl,Base = ...---@type MainLibObject
local pairs = pairs
---@class MacroGroup:BaseClass
local MacroGroup = Base:new()

---@protected
---@param groupSummary table
---@param parentProfile ProfileDefinition
function MacroGroup:constructor(groupSummary,parentProfile,defaults,overrides,stack)
  if not groupSummary then return end
  self.stack = stack or {}
  self.profile = parentProfile
  self.raw = groupSummary;
  self.name = self.options.name
  self.subDefinitions,self.options = tl.tbl:splitDefinition(groupSummary)
  self.subMacros = {}
  for k, v in pairs(defaults or {}) do self.options[k] = self.options[k] or v; end
  self.overrides = overrides
  if self:checkNecessity() then self:genId() end
  self:parseMacros()
  if self.pID then 
    self.profile.macroIndex[self.pID]=self
  end
end

function MacroGroup:parseMacros()
  for i = 1, #self.subDefinitions do local entry = self.subDefinitions[i]
    local macroClass = tl.bindings:getMacroClass(entry)
    if macroClass then
      ---@type BaseMacro|MacroGroup
      local subClass = macroClass:new(entry,self.profile,self.options,self.overrides,self.stack)
      if subClass.pID or #subClass.subMacros ~=0 then
        self.subMacros[#self.subMacros+1] = subClass.pID or subClass.subMacros[#subClass.subMacros]
      end
    end
  end
end

---@private
function MacroGroup:checkNecessity()
  if #self.subDefinitions ~= 1 then return true end
  local entry = self.subDefinitions[1]
  if self.options.name and self.profile.macroIndex[entry].name then
    return self.name ~= entry.name
  end
  return false
end

function MacroGroup:execute(Event,Config)
  local entries = self.subMacros
  for i = 1, #entries do local entry = entries[i]
    self.profile.macroIndex[entry]:execute(Event,Config)
  end
end
