local tl = ...---@type MainLibObject
local remove,unpack,type,insert,next,abs = remove,unpack,type,insert,next,math.abs
local MacroDefinition = tl:classImport('MacroDefinition')

local LinkMacro = MacroDefinition:new()---@class LinkMacro:MacroDefinition

function LinkMacro:parseInstructions()
  local rawName = self.rawCommand[1]
  self.command = self:awaitId(rawName,true)
  self:finishInit()
end

function LinkMacro:execute(event)
  if self.options.override then self.profile.macroIndex[self.command]:runFree(event)
  else  self.profile.macroIndex[self.command]:run(event) end
end

return LinkMacro