local rv = ... ---@type Revenant
local remove, type, GetRunningTime, super = table.remove, type, GetRunningTime, rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _AlterHistoryOptions:MacroOptions
---@field refresh? boolean #Make the first unaffected button appear recently pressed
--[[=============================================================]] --
---@alias AssignAlterHistory MacroInitDefinition<"alterhistory","ah",{},integer[]>
--[[=============================================================]] --
---@class (exact) AlterHistoryMacro:MacroDefinition
---@field options _AlterHistoryOptions
---@field command integer|false
local AlterHistoryMacro = super:new()
AlterHistoryMacro.type = "alterhistory"
AlterHistoryMacro.singleTrigger = true
AlterHistoryMacro.lintProperties = { ---@type OptionsLintPreset
   refresh = {type = "boolean"}
}
AlterHistoryMacro.lintCommand = {type = "number"}

---@async
function AlterHistoryMacro:parseInstructions()
   local cmd = self.rawCommand[1]
   self.command = (type(cmd) == "number" and cmd >= 0) and cmd or -1
   self:finishInit()
end

function AlterHistoryMacro:execute()
   local num = self.command
   if num == -1 then
      rv.utils.wipe(rv.states.keyStates.lastKeysDown) -- deleting all pressed keys.
   else
      for _ = 1, num + 1 do remove(rv.states.keyStates.lastKeysDown) end -- deleting a specific number of keys
   end
   if self.options.refresh and #rv.states.keyStates.lastKeysDown ~= 0 then
      rv.states.keyStates.lastKeysDown[#rv.states.keyStates.lastKeysDown].time = GetRunningTime()
   end
end

---@param depth? integer
function AlterHistoryMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Wipe " .. (self.command and "last " .. self.command or "all") .. " pressed keys" end

return AlterHistoryMacro