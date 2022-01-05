local rv = ...---@type Revenant
local remove, unpack, type, insert, rep = table.remove, table.unpack, type, table.insert, string.rep
---@alias V any
---@class FunctionMacro:MacroDefinition
---@field command string|any[]
local FunctionMacro = rv:classImport('MacroDefinition'):new()
FunctionMacro.singleTrigger = true
FunctionMacro.lintProperties = { __none = {} }

function FunctionMacro:parseInstructions()
    if #self.rawCommand == 1 then self.command = self.rawCommand[1] end
    self:finishInit()
end

--TODO:More function testing, async
function FunctionMacro:execute()
    local func = self.command
    if type(func) == "string" then _G[func]()
    elseif type(func) == "table" then
        local funcName = func[1]
        remove(func, 1)
        _G[funcName](unpack(func))
        insert(func, 1, funcName)
    elseif type(func) == "function" then
        func()
    end
end

---@param depth number
function FunctionMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. 'Execute function "' .. (type(self.command) == "string" and self.command or self.command[1]) .. '"'
end

return FunctionMacro