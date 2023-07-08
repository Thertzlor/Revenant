local rv = ... ---@type Revenant
local concat, super = table.concat, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _BacklightOptions:MacroOptions
---@field family HardwareFamily|FamilyToken #The Device family targeted by the backlight change.
--[[=============================================================]] --
---Assign a Macro that controls the Backlight of a (compatible) mouse or Keyboard
---@alias AssignBacklight MacroInitDefinition|_BacklightOptions|mt<"backlight","b">|(string|integer)[]
--[[=============================================================]] --
---A Macro that controls the Backlight of a (compatible) mouse or Keyboard
---@class BacklightMacro:MacroDefinition
---@field command {[1]:integer,[2]:integer,[3]:integer}|l<string>
---@field options _BacklightOptions #Individual macro settings
local BacklightMacro = super:new()
BacklightMacro.singleTrigger = true
BacklightMacro.type = "backlight"
BacklightMacro.lintProperties = { ---@type OptionsLintPreset
   family = {type = "string", values = {"mouse", "kb", "lhc"}}
}
BacklightMacro.lintCommand = {type = {"string", "number"}}
---@param event Event
function BacklightMacro:execute(event)
   local fam = rv.str:token(self.options.family or event.family) --[[@as FamilyToken]]
   rv.logitech:backLightControl(self.command, fam)
end

---Export macro data for display
---@param depth? integer
function BacklightMacro:export(depth)
   local fam = self.options.family
   local cmd = self.command
   return self:indent(depth) .. self.titleExport .. "set" .. (fam and " " .. fam or "") .. " Backlight to" .. (type(cmd) == "string" and cmd or concat(cmd --[[@as table]] , " ,"))
end

return BacklightMacro
