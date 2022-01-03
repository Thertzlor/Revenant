local rv = ...---@type MainLibObject
local remove, unpack, type, insert, next, abs, rep = remove, unpack, type, insert, next, math.abs, string.rep
---@class LinkMacro:MacroDefinition
---@field command string
local LinkMacro = rv:classImport('MacroDefinition'):new()
LinkMacro.lintProperties = { __none = {} }
LinkMacro.lintCommand = { type = "string" }

---@protected
function LinkMacro:parseInstructions()
    local rawName = self.rawCommand[1]
    self.command = self:awaitId(rawName, true)
    self:finishInit()
end

---@param event Event
function LinkMacro:execute(event)
    if self.options.override then self.profile.macroIndex[self.command]:runFree(event)
    else self.profile.macroIndex[self.command]:run(event) end
end

---@param depth number
function LinkMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Link to macro "' .. self.command .. '"'
end

return LinkMacro