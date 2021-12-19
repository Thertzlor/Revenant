local tl = ...---@type MainLibObject
local remove, unpack, type, insert, next, abs = remove, unpack, type, insert, next, math.abs
local MacroDefinition = tl:classImport('MacroDefinition')

local LinkMacro = MacroDefinition:new()---@class LinkMacro:MacroDefinition
LinkMacro.lintProperties = { __none = {} }
LinkMacro.lintCommand = { type = "string" }

---@protected
function LinkMacro:parseInstructions()
    local rawName = self.rawCommand[1]
    self.titleExport = tl.classMap[self.type or "key"][1] .. " (" .. rawName .. ")"
    self.command = self:awaitId(rawName, true)
    self:finishInit()
end

---@param event Event
function LinkMacro:execute(event)
    if self.options.override then self.profile.macroIndex[self.command]:runFree(event)
    else self.profile.macroIndex[self.command]:run(event) end
end

return LinkMacro