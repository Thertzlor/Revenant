local rv = ... ---@type Revenant
local PlayMacro, pairs, super = PlayMacro, pairs, rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _ModeChangeOptions:MacroOptions
---@field family? HardwareFamily|FamilyToken|'all' #The device family that should change its mode
---@field hardwareOnly? boolean #only change the mouse/kb mode, not the mode seen by Revenant
---@field temporary? boolean #If true only changes the mode while the button is pressed. Basically an additional g-shift
--[[=============================================================]] --
---Assign macro used to change the mouse to different modes, that may or
---may be not correspond to the Hardware mode buttons. <br>[Documentation](https://github.com/Thertzlor/Revenant/wiki/Mode-Change-Macro)
---@alias AssignModeChange MacroInitDefinition<"mode","m",_ModeChangeOptions,(string|integer)[]>
--[[=============================================================]] --
---A macro used to change the mouse to different modes, that may or
---may be not correspond to the Hardware mode buttons.
---@class (exact) ModeChangeMacro:MacroDefinition
---@field options _ModeChangeOptions
---@field lastModes table<FamilyToken,integer>
---@field command integer|string
local ModeChangeMacro = super:new()
ModeChangeMacro.type = "mode"
ModeChangeMacro.lintProperties = { --
   family = {type = "string", values = {"mouse", "kb", "lhc"}},
   hardwareOnly = {type = "boolean"},
   temporary = {type = "boolean"}
}
ModeChangeMacro.lintCommand = {type = {"number", "string"}}
ModeChangeMacro.terminus = false

---@async
function ModeChangeMacro:parseInstructions()
   self.singleTrigger = self.options.hardwareOnly or not self.options.temporary
   self.lastModes = {}
   self:finishInit()
end

---@param event Event
---@async
function ModeChangeMacro:execute(event)
   -- `hardwareOnly` usually attempts to sync the hardware with the internal mode.
   local fam = rv.str:token(self.options.family or event.family) --[[@as FamilyToken]]
   if self.options.family == "all" then
      for k, v in pairs(rv.profile.deviceState) do
         rv.states.scriptStates.lastAccess['mode_' .. k] = self.pID
         self.lastModes[k] = v.modus
      end
   else
      rv.states.scriptStates.lastAccess['mode_' .. fam] = self.pID
      self.lastModes[fam] = rv.profile.deviceState[fam].modus
   end
   if not self.options.hardwareOnly then return rv.logitech:modeWrapper(self.command[1], self.options.temporary, self.options.family or event.family) end
   local adjustment = self.command[1] or 1
   if self.options.family == "all" then for _, v in pairs(rv.profile.deviceState) do for _ = 1, adjustment do PlayMacro("Mode Switch (" .. v.name .. ")") end end end
   for _ = 1, adjustment do PlayMacro("Mode Switch (" .. rv.profile.deviceState[fam].name .. ")") end
end

---@async
function ModeChangeMacro:onTimeout(event)
   local fam = rv.str:token(self.options.family or event.family) --[[@as FamilyToken]]
   local accessor = rv.states.scriptStates.lastAccess
   if not self.options.hardwareOnly then
      if self.options.family == "all" then
         for k, v in pairs(rv.profile.deviceState) do
            if (accessor['mode_' .. k] or self.pID) == self.pID then
               rv.logitech:modeWrapper(self.lastModes[k], self.options.temporary, v.family)
            end
         end
         return
      end
      if (accessor['mode_' .. fam] or self.pID) ~= self.pID then return end
      return rv.logitech:modeWrapper(self.lastModes[fam], self.options.temporary, self.options.family or event.family)
   end
   for k, v in pairs(self.options.family == "all" and rv.profile.deviceState or {[fam] = rv.profile.deviceState[fam]}) do
      if (accessor['mode_' .. k] or self.pID) == self.pID then
         local adjustment = self.lastModes[k] % v.modeCount
         for _ = 1, adjustment do PlayMacro("Mode Switch (" .. rv.profile.deviceState[fam].name .. ")") end
      end
   end
end

---@param depth? integer
function ModeChangeMacro:stringify(depth)
   local fam = self.options.family
   return self:indent(depth) .. self.titleExport .. "set" .. (fam and " " .. fam or "") .. " Mode to " .. self.command[1]
end

return ModeChangeMacro