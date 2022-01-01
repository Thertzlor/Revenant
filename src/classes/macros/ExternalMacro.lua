local rv = ...---@type MainLibObject
--=============================================================
---@class ExternalMacroOptions:MacroOptions
---@field play ('"hold"'|'"toggle"'|'"normal"')
--=============================================================
local rep = string.rep
---A macro for playing external Logitech Macros defined in LGS.  
---@class ExternalMacro:MacroDefinition
---@field options ExternalMacroOptions
local ExternalMacro = rv:classImport('MacroDefinition'):new()
ExternalMacro.lintProperties = { play = { type = "string", values = { "hold", "toggle", "normal" } } }
ExternalMacro.shortHands = { p = "play" }
ExternalMacro.lintCommand = { type = "string" }

function ExternalMacro:execute(event)
    rv.logitech.externalMacroWrapper(self.command, self.options, event.dir, event.dirMatch)
end

function ExternalMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Play LGS macro "' .. self.command .. '"'
end

return ExternalMacro