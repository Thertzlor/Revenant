local tl = ...---@type MainLibObject
--=============================================================
---@class ExternalMacroOptions:MacroOptions
---@field play ('"hold"'|'"toggle"'|'"normal"')
--=============================================================
---A macro for playing external Logitech Macros defined in LGS.  
---@class ExternalMacro:MacroDefinition
---@field options ExternalMacroOptions
local ExternalMacro = tl:classImport('MacroDefinition'):new()

ExternalMacro.lintProperties = { play = { type = "string", values = { "hold", "toggle", "normal" } } }
ExternalMacro.shortHands = { p = "play" }
ExternalMacro.lintCommand = { type = "string" }

function ExternalMacro:execute(event)
    tl.logitech.externalMacroWrapper(self.command, self.options, event.dir, event.dirMatch)
end

return ExternalMacro