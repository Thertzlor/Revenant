local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

---A macro for playing external Logitech Macros defined in LGS.  
---@class ExternalMacro:MacroDefinition
---@field options {play:"'hold'"|"'toggle'"|"'normal'"}
local ExternalMacro = MacroDefinition:new()

ExternalMacro.lintProperties={
  play = {type = "string",values = {"hold", "toggle", "normal"}}
}

ExternalMacro.shortHands = {p="play"}

function ExternalMacro:execute(event)
  tl.logitech.externalMacroWrapper(self.command,event.dir,event.dirMatch)
end

return ExternalMacro