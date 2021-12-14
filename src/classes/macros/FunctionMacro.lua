local tl = ...---@type MainLibObject
local remove,unpack,type,insert = table.remove,table.unpack,type,table.insert
local MacroDefinition = tl:classImport('MacroDefinition')

local FunctionMacro = MacroDefinition:new()---@class FunctionMacro:MacroDefinition yorp

FunctionMacro.lintProperties={__none={}}
FunctionMacro.singleTrigger = true

function FunctionMacro:parseInstructions()
  if #self.rawCommand == 1 then self.command = self.rawCommand[1] end
  self:finishInit()
end

--TODO:More function testing
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