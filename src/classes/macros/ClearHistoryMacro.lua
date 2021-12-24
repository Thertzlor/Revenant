local tl = ...---@type MainLibObject
local remove, type, rep = remove, type, string.rep
---@class ClearHistoryMacro:MacroDefinition
---@field command number
local ClearHistoryMacro = tl:classImport('MacroDefinition'):new()
ClearHistoryMacro.lintProperties = { __none = {} }
ClearHistoryMacro.lintCommand = { type = "number" }

function ClearHistoryMacro:parseInstructions()
    local cmd = self.rawCommand[1]
    self.command = (type(cmd) ~= "number" or cmd < 1) and cmd or nil
    self:finishInit()
end

function ClearHistoryMacro:execute()
    local num = self.command
    if not num then tl.helperUtils.wipe(tl.keyStates.lastKeysDown)
    else for _ = 1, num + 1 do remove(tl.keyStates.lastKeysDown) end end
end

function ClearHistoryMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Wipe " .. (self.command and 'last ' .. self.command or 'all') .. " pressed keys"
end

return ClearHistoryMacro