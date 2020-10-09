local tl,Base = ...---@type MainLibObject
local pairs = pairs
---@class BaseMacro:BaseClass
local BaseMacro = Base:new()

---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
function BaseMacro:constructor(macroSummary,parentProfile,defaults,overrides)
  if not macroSummary then return end
  self.originProfile = parentProfile
  self.raw = macroSummary;
  self.command,self.options = tl.tbl:splitDefinition(macroSummary)
  for k, v in pairs(defaults or {}) do self.options[k] = self.options[k] or v; end
  for k, v in pairs(overrides or {}) do self.options[k] = v; end
  self.pID = #tl.macroIndex+1
end

function BaseMacro:execute() end

return BaseMacro
