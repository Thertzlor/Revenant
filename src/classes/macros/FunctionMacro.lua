local rv = ...---@type Revenant
local  unpack, type, rep, running = unpack, type, string.rep, coroutine.running
--=============================================================
---@class _FunctionOptions:MacroOptions
---@field async boolean
--=============================================================
---@alias FunctionDefinition MacroInitDefinition|_FunctionOptions
--=============================================================
---@class FunctionMacro:MacroDefinition
---@field command fun(...:any):any
---@field options _FunctionOptions
---@field funcName string
---@field arguments table
local FunctionMacro = rv:classImport('MacroDefinition'):new()
FunctionMacro.singleTrigger = true
FunctionMacro.lintProperties = { async = { type = "boolean" } }
FunctionMacro.lintCommand = {}

function FunctionMacro:parseInstructions()
    local func = self.rawCommand[1]
    local arg = self.rawCommand[2] or {}
    self.continuous = self.options.async
    local fype = type(func)
    self.funcName = ""
    if type(arg) ~="table" then arg = {arg} end
    if fype =="string" then
        local globalFunc = _G[func]
        if not globalFunc then error("No function found with name "..func) end
        self.command = globalFunc
        self.funcName = func
    elseif fype == "function" then
        self.command = func
    else error("First argument of function macro of invalid type "..fype..'.') end
    self.arguments = arg
    self:finishInit()
end

---@param event Event
function FunctionMacro:execute(event)
    local func = self.command
    local arg = self.arguments

    if self.options.async then
        if not running() then rv.coroutines:taskRun(self.pID, event.family, event.keyNum, func,unpack(arg))
        else
            rv.coroutines:addSubtask(self.pID)
            func(unpack(arg))
            rv.coroutines:removeSubtask(self.pID)
        end
    else func(unpack(arg)) end
end

---@param depth number
function FunctionMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Execute "..(self.funcName == "" and "a manually defined function" or "function "..self.funcName)
end

---TODO:add control

return FunctionMacro