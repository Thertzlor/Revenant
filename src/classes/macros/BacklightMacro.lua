local tl = ...---@type MainLibObject
--=============================================================
---@class BackligthOptions:MacroOptions
---@field family '"mouse"'|'"kb"'|'"lhc"'
--=============================================================
local rep, concat = string.rep, table.concat
---@class BacklightMacro:MacroDefinition
---@field command (number|string)[]
---@field options BackligthOptions
local BacklightMacro = tl:classImport('MacroDefinition'):new()
BacklightMacro.singleTrigger = true
BacklightMacro.lintProperties = { family = { type = "string", values = { "mouse", "kb", "lhc" } } }
BacklightMacro.lintCommand = { type = { "string", "number" } }
---@param event Event
function BacklightMacro:execute(event)
    tl.logitech:backLightControl(self.command, self.options.family or event.family)
end

function BacklightMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return (indent or "") .. self.titleExport .. "set" .. (fam and ' ' .. fam or '') .. " Backlight to" .. concat(self.command, ' ,')
end

return BacklightMacro