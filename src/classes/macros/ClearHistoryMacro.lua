local tl = ...---@type MainLibObject
local remove, type = remove, type
local MacroDefinition = tl:classImport('MacroDefinition')

local ClearHistoryMacro = MacroDefinition:new()---@class ClearHistoryMacro:MacroDefinition

ClearHistoryMacro.lintProperties = { __none = {} }
function ClearHistoryMacro:execute()
    local num = self.command
    if type(num) ~= "number" or num < 1 then tl.helperUtils.wipe(tl.keyStates.lastKeysDown)
    else for _ = 1, num + 1 do remove(tl.keyStates.lastKeysDown) end end
end

return ClearHistoryMacro