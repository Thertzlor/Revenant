local tl = ...---@type MainLibObject
local type, rep, concat = type, string.rep, table.concat
---@class FlagMacro:MacroDefinition
---@field command string|string[]
local FlagMacro = tl:classImport('MacroDefinition'):new()
FlagMacro.lintProperties = { __none = {} }
FlagMacro.lintCommand = { type = { "string", "table" }, tableKeys = "number", tableTypes = "string" }

function FlagMacro:execute()
    local cmd = self.command
    if type(cmd) == "string" then tl.scriptStates.flags[cmd] = not tl.scriptStates.flags[cmd]
    else
        for i = 1, #cmd, 2 do local cm, cmNext = cmd[i], cmd[i + 1]
            if cmNext then tl.scriptStates.flags[cm] = cmNext
            else tl.scriptStates.flags[cm] = not tl.scriptStates.flags[cm] end
        end
    end
end

---@protected
function FlagMacro:parseInstructions()
    self.singleTrigger = (self.type == "toggleflag")
    self:finishInit()
end

function FlagMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (self.singleTrigger and 'set' or 'toggle') .. ' flag' .. (type(self.cmd) == "string" and '' or 's') .. ' ' .. (type(self.command == 'string' and self.command or concat(self.command, ', ')))
end

return FlagMacro