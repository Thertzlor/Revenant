local rv = ...---@type Revenant
local rep, concat = string.rep, table.concat
--=============================================================
---@class _BackligthOptions:MacroOptions
---@field family '"mouse"'|'"kb"'|'"lhc"' The Device family targeted by the backlight change.
--=============================================================
---@alias BacklightDefinition MacroInitDefinition|_BackligthOptions
--=============================================================
--=============================================================
---@class BacklightMacro:MacroDefinition
---@field command number[]|string[]
---@field options _BackligthOptions
local BacklightMacro = rv:classImport('MacroDefinition'):new()
BacklightMacro.singleTrigger = true
BacklightMacro.lintProperties = { family = { type = "string", values = { "mouse", "kb", "lhc" } } }
BacklightMacro.lintCommand = { type = { "string", "number" } }
---@param event Event
function BacklightMacro:execute(event)
    rv.logitech:backLightControl(self.command, self.options.family or event.family)
end

---@param depth? integer
function BacklightMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "set" .. (fam and ' ' .. fam or '') .. " Backlight to" .. concat(self.command, ' ,')
end

return BacklightMacro