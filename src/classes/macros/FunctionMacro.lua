local rv = ...---@type Revenant
local remove, unpack, type, insert, rep = table.remove, table.unpack, type, table.insert, string.rep
---@alias V any
--=============================================================
------@class FunctionOptions:MacroOptions
---@field async boolean
--=============================================================
---@class FunctionMacro:MacroDefinition
---@field command string|any[]|function
---@field options FunctionOptions
local FunctionMacro = rv:classImport('MacroDefinition'):new()
FunctionMacro.singleTrigger = true
FunctionMacro.lintProperties = { async = { type = "boolean" } }
FunctionMacro.lintCommand = {}

function FunctionMacro:parseInstructions()
    if #self.rawCommand == 1 then self.command = self.rawCommand[1] end
    self:finishInit()
end

--TODO:async testing
---@param event Event
function FunctionMacro:execute(event)
    local func = self.command
    if type(func) == "string" then _G[func]()
    elseif type(func) == "table" then
        local tion = (type(func[1]) == "string" and _G[func[1]]) or func[1] ---@type function
        remove(func, 1)
        if self.options.async then rv.coroutines:taskRun(self.pID, event.family, event.keyNum, tion, unpack(func))
        else tion(unpack(func)) end
        insert(func, 1, func)
    elseif type(func) == "function" then
        if self.options.async then rv.coroutines:taskRun(self.pID, event.family, event.keyNum, func)
        else func() end
    end
end

---@param depth number
function FunctionMacro:export(depth)
    depth = depth or 0
    local cmd = self.command
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. (type(cmd) == "function" and "Execute a manual function") or ('Execute function"' .. (type(cmd) == "string" and cmd or (type(cmd[1])) == "string" and " " .. cmd[1] or "") .. '"')
end

return FunctionMacro