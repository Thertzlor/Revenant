local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')
local type = type
---@class MonitorChangeMacro:MacroDefinition
local MonitorChangeMacro = MacroDefinition:new()
MonitorChangeMacro.singleTrigger = true

function MonitorChangeMacro:execute()
  local num = self.command
    self.profile.resolutions =
    self.profile.displayStorage[
      tl.tbl:cycleIndex(self.profile.displayStorage,(type(num) == "table") and num[1] or num,self.profile.displayStorage.disPositon)
    ]
end

return MonitorChangeMacro