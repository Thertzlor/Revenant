local tl = ...---@type MainLibObject
--=============================================================
---@class BacklightMacro:MacroDefinition
---@field command (number|string)[]
local BacklightMacro = tl:classImport('MacroDefinition'):new()
BacklightMacro.singleTrigger = true
BacklightMacro.lintProperties = { __none = {} }
BacklightMacro.lintCommand = { type = { "string", "number" } }
---@param event Event
function BacklightMacro:execute(event)
    tl.logitech:backLightControl(self.command, event.family)
end

return BacklightMacro