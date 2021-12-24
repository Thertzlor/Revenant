local tl = ...---@type MainLibObject
local rep = string.rep
--=============================================================
---@class ModeChangeOptions:MacroOptions
---@field family '"mouse"'|'"kb"'|'"lhc"'
--=============================================================
---@class ModeChangeMacro:MacroDefinition
---@field options ModeChangeOptions
---@field command number|string
local ModeChangeMacro = tl:classImport("MacroDefinition"):new()
ModeChangeMacro.lintProperties = { family = { type = "string", values = { "mouse", "kb", "lhc" } } }
ModeChangeMacro.lintCommand = { type = { "number", "string" } }

function ModeChangeMacro:execute(event)
    tl.logitech:modeWrapper(self.command[1], self.command[2], self.family or event.family, (self.state.matchDown or self.state.matchUp))
end

function ModeChangeMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "set" .. (fam and ' ' .. fam or '') .. " Mode to" .. self.command
end

return ModeChangeMacro