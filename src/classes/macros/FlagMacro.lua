local tl = ...---@type MainLibObject
local type = type
local MacroDefinition = tl:classImport('MacroDefinition')

local FlagMacro = MacroDefinition:new()---@class FlagMacro:MacroDefinition


function FlagMacro:execute()
  local cmd = self.command
  if type(cmd) == "string" then tl.scriptStates.flags[cmd] = not tl.scriptStates.flags[cmd] 
  else
    for i = 1, #cmd, 2 do local cm,cmNext = cmd[i],cmd[i+1]
      if cmNext then tl.scriptStates.flags[cm] = cmNext 
      else tl.scriptStates.flags[cm] = not tl.scriptStates.flags[cm] end
    end
  end
end

function FlagMacro:parseInstructions()
  self.singleTrigger = (self.type == "toggleflag")
  self:finishInit()
end

return FlagMacro