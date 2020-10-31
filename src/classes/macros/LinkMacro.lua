local tl = ...---@type MainLibObject
local remove,unpack,type,insert,next,abs = remove,unpack,type,insert,next,math.abs
local MacroDefinition = tl:classImport('MacroDefinition')

local LinkMacro = MacroDefinition:new()---@class LinkMacro:MacroDefinition

function LinkMacro:parseInstructions()
  self.command = self.rawCommand[1] 
  self:finishInit()
end

function LinkMacro:execute(event)
  self.profile.macroIndex[self.command]:run(event)
end

return LinkMacro