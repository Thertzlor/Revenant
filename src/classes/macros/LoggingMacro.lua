local tl = ...---@type MainLibObject
local type,OutputDebugMessage,error = type,OutputDebugMessage,error
local MacroDefinition = tl:classImport('MacroDefinition')

local LoggingMacro = MacroDefinition:new()---@class LoggingMacro:MacroDefinition

---@protected
function LoggingMacro:parseInstructions()
  self.singleTrigger = true
  self.command = self.rawCommand[1]
  if type(self.command) == "table" then self.command = tl.helperUtils.pprint(self.command) end 
  self.options.persist = self.rawCommand[2] or self.profile.config.persistLCD;
end

function LoggingMacro:execute()
  local config,msg,options = self.profile.config,self.command,self.options
  if msg== nil then error("No Message to Display") end
  local persist = config.persistLCD
  local stay = options.persist
  if options.debug then return OutputDebugMessage(msg) end
  if options.noLCD == 1 then tl.logitech:putNoLCD(msg) else
    config.persistLCD = stay
    tl:put(msg)
    config.persistLCD = persist
  end
end

return LoggingMacro