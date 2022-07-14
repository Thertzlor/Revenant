local rv = ... ---@type Revenant
local rep, concat = string.rep, table.concat

--[[=============================================================]] --
---@class _BacklightOptions:MacroOptions
---@field family HardwareFamily The Device family targeted by the backlight change.
--[[=============================================================]] --
---Assign a Macro that controls the Backlight of a (compatible) mouse or Keyboard
---@alias AssignBacklight MacroInitDefinition|_BacklightOptions|mt<"backlight"|"b">
--[[=============================================================]] --
---A Macro that controls the Backlight of a (compatible) mouse or Keyboard
---@class BacklightMacro:MacroDefinition
---@field command integer[]|l<string>
---@field options _BacklightOptions Individual macro settings
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
