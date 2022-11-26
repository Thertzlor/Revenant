local rv = ... ---@type Revenant
local unpack, type, rep, running, assert, error = unpack, type, string.rep, coroutine.running, assert, error

--[[=============================================================]] --
---@class _FunctionOptions:MacroOptions
---@field async boolean #true if the function should run in a coroutine.
--[[=============================================================]] --
---@alias AssignFunction MacroInitDefinition|_FunctionOptions
--[[=============================================================]] --
---A Macro used to call a custom lua function.
---@class FunctionMacro:MacroDefinition
---@field command fun(...:any):any
---@field options _FunctionOptions
---@field funcName string #the name of the function
---@field arguments table #the second entry in the command can be an argument or a table of arguments.
local FunctionMacro = rv:classImport('MacroDefinition'):new()
FunctionMacro.singleTrigger = true
FunctionMacro.lintProperties = { async = { type = "boolean" } }
FunctionMacro.lintCommand = {}

function FunctionMacro:parseInstructions()
    local func = self.rawCommand[1]
    local arg = self.rawCommand[2] or {}
    self.continuous = self.options.async --async functions are continous and can be targeted by control macros.
    local fype = type(func)
    self.funcName = ""
    if type(arg) ~= "table" then arg = { arg } end
    if fype == "string" then --The argument can either be the name of a function or a function itself.
        local globalFunc = assert(_G[func], "No function found with name " .. func)
        self.command = globalFunc
        self.funcName = func
    elseif fype == "function" then self.command = func
    else error("First argument of function macro of invalid type " .. fype .. '.') end
    self.arguments = arg
    self:finishInit()
end

---@param event Event
function FunctionMacro:execute(event)
    local func = self.command
    local arg = self.arguments

    if self.options.async then --launching coroutine
        if not running() then rv.threading:taskRun(self.pID, event.family, event.keyNum, func, unpack(arg))
        else --if we are already inside a coroutine we add this function as a subtask for targeting.
            rv.threading:addSubtask(self.pID)
            func(unpack(arg))
            rv.threading:removeSubtask(self.pID)
        end
    else func(unpack(arg)) end --running the function synchronously
end

---@param depth? integer
function FunctionMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Execute " .. (self.funcName == "" and "a manually defined function" or "function " .. self.funcName)
end

return FunctionMacro