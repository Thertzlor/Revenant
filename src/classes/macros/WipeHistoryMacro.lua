local rv = ... ---@type Revenant
local remove, type = table.remove, type

--[[=============================================================]] --
---@alias AssignWipeHistory MacroInitDefinition|mt<"wipehistory","wh">
--[[=============================================================]] --
---@class WipeHistoryMacro:MacroDefinition
---@field command integer|false
local WipeHistoryMacro = rv.importer:classImport("MacroDefinition"):new()
WipeHistoryMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {}
}
WipeHistoryMacro.lintCommand = {type = "number"}

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
function WipeHistoryMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Wipe " .. (self.command and "last " .. self.command or "all") .. " pressed keys" end

return WipeHistoryMacro
