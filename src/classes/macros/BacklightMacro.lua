local tl = ...---@type MainLibObject
local MacroDefinition = tl:classImport('MacroDefinition')

---@class BacklightMacro:MacroDefinition
---@field command (number|string)[]
local BacklightMacro = MacroDefinition:new()
BacklightMacro.singleTrigger = true
BacklightMacro.lintProperties = { __none = {} }
BacklightMacro.lintCommand = { type = { "string", "number" } }
---@param event Event
function BacklightMacro:execute(event)
    tl.logitech:backLightControl(self.command, event.family)
end

return BacklightMacro