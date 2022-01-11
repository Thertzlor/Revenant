local rv = ...---@type Revenant
--=============================================================
---@class _ExternalMacroOptions:MacroOptions
---@field play '"hold"'|'"toggle"'|'"normal"'
---@field macroBlocking "1"|"2"|"3"
---@field lcd number|boolean
--=============================================================
---@class __ExternalMacroShorthands
---@field p '"hold"'|'"toggle"'|'"normal"' Shorthand for "play"
--=============================================================
---@alias ExternalMacroDefinition MacroInitDefinition|_ExternalMacroOptions|__ExternalMacroShorthands
--=============================================================
local rep = string.rep
---A macro for playing external Logitech Macros defined in LGS.  
---@class ExternalMacro:MacroDefinition
---@field options _ExternalMacroOptions
local ExternalMacro = rv:classImport('MacroDefinition'):new()
ExternalMacro.lintProperties = {
    play = { type = "string", values = { "hold", "toggle", "normal" } },
    macroBlocking = { type = "number", range = { 1, 3 } },
    lcd = { type = { "number", "boolean" } }
}
ExternalMacro.shortHands = { p = "play" }
ExternalMacro.lintCommand = { type = "string" }

--TODO:Test if this works
---@param event Event
function ExternalMacro:execute(event)
    local run = rv.logitech:externalMacroWrapper(self.command, self.options, event.direction)
    if self.options.lcd then rv.lcd:displayOnLCD(self.pID .. '_' .. (run and 1 or 2), 1, self.msgDuration) end
end

---@private
function ExternalMacro:parseInstructions()
    self.command = self.rawCommand[1]
    self.singleTrigger = self.options.play ~= "hold"
    if self.options.lcd == nil then self.options.lcd = true end
    if self.options.lcd then
        for i = 1, 2 do rv.lcd:parseToDisplayDefinition((i == 1 and "Playing" or "Stopping") .. ' LGS macro "' .. self.command .. '"', self.pID .. '_' .. i, 1) end
    end
    self:finishInit()
end

---@param depth number
function ExternalMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Play LGS macro "' .. self.command .. '"'
end

return ExternalMacro