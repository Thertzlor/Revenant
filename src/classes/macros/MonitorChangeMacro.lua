local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
local type = type
---@class MonitorChangeMacro:BaseMacro
local MonitorChangeMacro = BaseMacro:new()
MonitorChangeMacro.singleTrigger = true
function MonitorChangeMacro:execute()
  local num = self.command
    self.profile.resolutions =
    self.profile.displayStorage[
      tl.tbl:cycleIndex(self.profile.displayStorage,(type(num) == "table") and num[1] or num,self.profile.displayStorage.disPositon)
    ]
end

return MonitorChangeMacro