local tl = ...---@type MainLibObject
local remove,unpack,type,insert = remove,unpack,type,insert
local MacroDefinition = tl:classImport('MacroDefinition')

local FunctionMacro = MacroDefinition:new()---@class FunctionMacro:MacroDefinition
FunctionMacro.singleTrigger = true
function FunctionMacro:execute()
   local func = self.command
   if type(func) == "string" then
      _G[func]()
    elseif type(func) == "table" then
      local funcName = func[1]
      remove(func, 1)
      _G[funcName](unpack(func))
      insert(func, 1, funcName)
    end
end

return FunctionMacro