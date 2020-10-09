local tl,Base = ...---@type MainLibObject
local pairs = pairs
---@class MacroGroup:BaseClass
local MacroGroup = Base:new()

---@protected
---@param groupSummary table
---@param parentProfile ProfileDefinition
function MacroGroup:constructor(groupSummary,parentProfile,defaults,overrides)
  if not groupSummary then return end
  self.originProfile = parentProfile
  self.raw = groupSummary;
  self.name = self.options.name
  self.entries,self.options = tl.tbl:splitDefinition(groupSummary)
  for k, v in pairs(defaults or {}) do self.options[k] = self.options[k] or v; end
  for k, v in pairs(overrides or {}) do self.options[k] = v; end
  if self:checkNecessity() then self.pID = #tl.macroIndex+1 end
end

function MacroGroup:inheritOptions() end

---@private
function MacroGroup:checkNecessity()
  if #self.entries ~= 1 then return true end
  local entry = self.entries[1]
  if self.options.name and self.originProfile.macroIndex[entry].name then
    return self.name ~= entry.name
  end
  return false
end

function MacroGroup:execute(Event,Config)
  local entries = self.entries
  for i = 1, #entries do local entry = entries[i]
    self.originProfile.macroIndex[entry]:execute(Event,Config)
  end

end
