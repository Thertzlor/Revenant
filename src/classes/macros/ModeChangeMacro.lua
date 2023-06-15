local rv = ... ---@type Revenant
local PlayMacro, pairs = PlayMacro, pairs
--[[=============================================================]] --
---@class _ModeChangeOptions:MacroOptions
---@field family HardwareFamily|FamilyToken|'all' #The device family that should change its mode
---@field hardwareOnly boolean #only change the mouse/kb mode, not the mode seen by Revenant
---@field temporary boolean #If true only changes the mode while the button is pressed. Basically an additional g-shift
--[[=============================================================]] --
---Assign macro used to change the mouse to different modes, that may or
---may be not correspond to the Hardware mode buttons.
---@alias AssignModeChange _ModeChangeOptions | MacroInitDefinition | mt<"mode","m">
--[[=============================================================]] --
---A macro used to change the mouse to different modes, that may or
---may be not correspond to the Hardware mode buttons.
---@class ModeChangeMacro:MacroDefinition
---@field options _ModeChangeOptions
---@field command integer|string
local ModeChangeMacro = rv.importer:classImport("MacroDefinition"):new()
ModeChangeMacro.lintProperties = { ---@type OptionsLintPreset
   family = {type = "string", values = {"mouse", "kb", "lhc"}},
   hardwareOnly = {type = "boolean"},
   temporary = {type = "boolean"}
}
ModeChangeMacro.lintCommand = {type = {"number", "string"}}
ModeChangeMacro.terminus = false

---@async
function ModeChangeMacro:parseInstructions()
   self.singleTrigger = self.options.hardwareOnly or not self.options.temporary
   self:finishInit()
end

---@param event Event
---@async
function ModeChangeMacro:execute(event)
   -- `hardwareOnly` usually attempts to sync the hardware with the internal mode.
   if not self.options.hardwareOnly then return rv.logitech:modeWrapper(self.command[1], self.options.temporary, self.options.family or event.family) end
   local adjustment = self.command[1] or 1
   if self.options.family == "all" then for _, v in pairs(rv.profile.deviceState) do for _ = 1, adjustment do PlayMacro("Mode Switch (" .. v.name .. ")") end end end
   local fam = rv.str:token(self.options.family or event.family) --[[@as FamilyToken]]
   for _ = 1, adjustment do PlayMacro("Mode Switch (" .. rv.profile.deviceState[fam].name .. ")") end
end

---@param depth? integer
function ModeChangeMacro:export(depth)
   local fam = self.options.family
   return self:indent(depth) .. self.titleExport .. "set" .. (fam and " " .. fam or "") .. " Mode to " .. self.command[1]
end

return ModeChangeMacro
