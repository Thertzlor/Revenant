local rv = ...---@type Revenant
local rep = string.rep
--=============================================================
---@class _LinkOptions:MacroOptions
---@field override boolean Overrides shit.
--=============================================================
---@alias LinkDefinition _LinkOptions | MacroInitDefinition
--=============================================================
---@class LinkMacro:MacroDefinition
---@field command string
---@field options _LinkOptions
local LinkMacro = rv:classImport('MacroDefinition'):new()
LinkMacro.lintProperties = { override = { type = "boolean" } }
LinkMacro.lintCommand = { type = "string" }
LinkMacro.terminus = false

---@protected
function LinkMacro:parseInstructions()
    local rawName = self.rawCommand[1]
    self.command = self:awaitId(rawName, true)
    self:finishInit()
end

--TODO:Test override again
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