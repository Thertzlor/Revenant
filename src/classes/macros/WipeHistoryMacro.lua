local rv = ... ---@type Revenant
local remove, type, rep = table.remove, type, string.rep

--[[=============================================================]] --
---@alias AssignWipeHistory MacroInitDefinition|mt<"wipehistory"|"wh">
--[[=============================================================]] --
---@class WipeHistoryMacro:MacroDefinition
---@field command number
local WipeHistoryMacro = rv:classImport('MacroDefinition'):new()
WipeHistoryMacro.lintProperties = { __none = {} }
WipeHistoryMacro.lintCommand = { type = "number" }

function WipeHistoryMacro:parseInstructions()
    local cmd = self.rawCommand[1]
    self.command = (type(cmd) == "number" and cmd > 0) and cmd
    self:finishInit()
end

function WipeHistoryMacro:execute()
    local num = self.command
    if not num then rv.utils.wipe(rv.keyStates.lastKeysDown)
    else for _ = 1, num + 1 do remove(rv.keyStates.lastKeysDown) end end
end

---@param depth? integer
function WipeHistoryMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Wipe " .. (self.command and 'last ' .. self.command or 'all') .. " pressed keys"
end

return WipeHistoryMacro
