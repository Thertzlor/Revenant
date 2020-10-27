local tl = ...---@type MainLibObject
local remove,unpack,type,insert = remove,unpack,type,insert
local MacroDefinition = tl:classImport('MacroDefinition')

---@class FunctionMacro:MacroDefinition
local FunctionMacro = MacroDefinition:new()
FunctionMacro.singleTrigger = true
function FunctionMacro:execute()
   local func = self.command
   if type(func) == "string" then
      _G[func]()
    elseif type(func) == "table" then
      local namu = func[1]
      remove(func, 1)
      _G[namu](unpack(func))
      insert(func, 1, namu)
    end
end

return FunctionMacro