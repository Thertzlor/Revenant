local rv = ...---@type Revenant
local rep = string.rep
--=============================================================
---@class _ModeChangeOptions:MacroOptions
---@field family '"mouse"'|'"kb"'|'"lhc"'
--=============================================================
---@alias ModeChangeDefinition _ModeChangeOptions | MacroInitDefinition
--=============================================================
---@class ModeChangeMacro:MacroDefinition
---@field options _ModeChangeOptions
---@field command number|string
local ModeChangeMacro = rv:classImport("MacroDefinition"):new()
ModeChangeMacro.lintProperties = { family = { type = "string", values = { "mouse", "kb", "lhc" } } }
ModeChangeMacro.lintCommand = { type = { "number", "string" } }
ModeChangeMacro.terminus = false

--TODO:Test modes omg
---@param event Event
function ModeChangeMacro:execute(event)
    rv.logitech:modeWrapper(self.command[1], self.command[2], self.options.family or event.family)
end

---@param depth number
function ModeChangeMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "set" .. (fam and ' ' .. fam or '') .. " Mode to" .. self.command[1]
end

return ModeChangeMacro