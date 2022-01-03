local rv = ...---@type MainLibObject
local rep = string.rep
--=============================================================
---@class ModeChangeOptions:MacroOptions
---@field family '"mouse"'|'"kb"'|'"lhc"'
--=============================================================
---@class ModeChangeMacro:MacroDefinition
---@field options ModeChangeOptions
---@field command number|string
local ModeChangeMacro = rv:classImport("MacroDefinition"):new()
ModeChangeMacro.lintProperties = { family = { type = "string", values = { "mouse", "kb", "lhc" } } }
ModeChangeMacro.lintCommand = { type = { "number", "string" } }
ModeChangeMacro.terminus = false

---@param event Event
function ModeChangeMacro:execute(event)
    rv.logitech:modeWrapper(self.command[1], self.command[2], self.family or event.family, (self.state.matchDown or self.state.matchUp))
end

---@param depth number
function ModeChangeMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "set" .. (fam and ' ' .. fam or '') .. " Mode to" .. self.command[1]
end

return ModeChangeMacro