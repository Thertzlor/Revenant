local tl,Base = ...---@type MainLibObject

---@class GenericMacrp:BaseClass
local GenericMacro = Base:new()

---@protected
function GenericMacro:constructor(MacroSummary)
  if not MacroSummary then return end
  self.raw = MacroSummary;
  self.command,self.options = self:splitDefinition(MacroSummary)
  self.pID = #tl.macroIndex+1
end

function GenericMacro:splitDefinition(raw)
  local commands = {}
  local options = {}
  for k, v in pairs(raw) do
    if type(k) == "string" then options[k] = v 
    else commands[k] = v end
  end
  return commands, options
end

function GenericMacro:execute() end

local KeyMacro = GenericMacro:new()

function KeyMacro:execute(Event) end