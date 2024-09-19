local rv = ... ---@type Revenant
local remove, type, super = table.remove, type, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@alias AssignWipeHistory MacroInitDefinition<"wipehistory","wh",{},integer[]>
--[[=============================================================]] --
---@class WipeHistoryMacro:MacroDefinition
---@field command integer|false
local WipeHistoryMacro = super:new()
WipeHistoryMacro.type = "wipehistory"
WipeHistoryMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {}
}
WipeHistoryMacro.lintCommand = {type = "number"}

---@async
function WipeHistoryMacro:parseInstructions()
   local cmd = self.rawCommand[1]
   self.command = (type(cmd) == "number" and cmd > 0) and cmd
   self:finishInit()
end

function WipeHistoryMacro:execute()
   local num = self.command
   if not num then
      rv.utils.wipe(rv.states.keyStates.lastKeysDown) -- deleting all pressed keys.
   else
      for _ = 1, num + 1 do remove(rv.states.keyStates.lastKeysDown) end -- deleting a specific number of keys
   end
end

---@param depth? integer
function WipeHistoryMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Wipe " .. (self.command and "last " .. self.command or "all") .. " pressed keys" end

return WipeHistoryMacro
