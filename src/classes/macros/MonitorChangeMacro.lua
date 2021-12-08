local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local type = type

local MonitorChangeMacro = MacroDefinition:new()---@class MonitorChangeMacro:MacroDefinition
MonitorChangeMacro.singleTrigger = true
MonitorChangeMacro.lintProperties={__none={}}
function MonitorChangeMacro:execute()
  local num = self.command

end

return MonitorChangeMacro