local rv = ... ---@type Revenant
local unpack, type, assert, error, super = unpack, type, assert, error, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _FunctionOptions:MacroOptions
---@field async? boolean #true if the function should run in a coroutine.
--[[=============================================================]] --
---@alias AssignFunction MacroInitDefinition<'func','fn',_FunctionOptions>
--[[=============================================================]] --
---A Macro used to call a custom lua function.
---@class (exact) FunctionMacro:MacroDefinition
---@field command fun(...:any):any
---@field options _FunctionOptions
---@field funcName string #the name of the function
---@field arguments table #the second entry in the command can be an argument or a table of arguments.
local FunctionMacro = super:new()
FunctionMacro.type = "func"
FunctionMacro.singleTrigger = true
FunctionMacro.lintProperties = { --
   async = {type = "boolean"}
}
FunctionMacro.lintCommand = {}

---@async
function FunctionMacro:parseInstructions()
   local func = self.rawCommand[1]
   local arg = self.rawCommand[2] or {}
   self.continuous = self.options.async -- async functions are continuous and can be targeted by control macros.
   local fype = type(func)
   self.funcName = ""
   if type(arg) ~= "table" then arg = {arg} end
   if fype == "string" then -- The argument can either be the name of a function or a function itself.
      local globalFunc = assert(_G[func], "No function found with name " .. func) ---@type fun()
      self.command = globalFunc
      self.funcName = func
   elseif fype == "function" then
      self.command = func
   else
      error("First argument of function macro of invalid type " .. fype .. ".")
   end
   self.arguments = arg
   self:finishInit()
end

---@async
function FunctionMacro:execute() self.command(unpack(self.arguments)) end

---@param depth? integer
function FunctionMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Execute " .. (self.funcName == "" and "a manually defined function" or "function " .. self.funcName) end

return FunctionMacro