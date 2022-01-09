local rv = ...---@type Revenant
local remove, type, rep = table.remove, type, string.rep

--=============================================================
---@class ClearHistoryMacro:MacroDefinition
---@field command number
local ClearHistoryMacro = rv:classImport('MacroDefinition'):new()
ClearHistoryMacro.lintProperties = { __none = {} }
ClearHistoryMacro.lintCommand = { type = "number" }

function ClearHistoryMacro:parseInstructions()
    local cmd = self.rawCommand[1]
    self.command = (type(cmd) == "number" and cmd > 0) and cmd
    self:finishInit()
end

function ClearHistoryMacro:execute()
    local num = self.command
    if not num then rv.helperUtils.wipe(rv.keyStates.lastKeysDown)
    else for _ = 1, num + 1 do remove(rv.keyStates.lastKeysDown) end end
end

---@param depth number
function ClearHistoryMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Wipe " .. (self.command and 'last ' .. self.command or 'all') .. " pressed keys"
end

return ClearHistoryMacro