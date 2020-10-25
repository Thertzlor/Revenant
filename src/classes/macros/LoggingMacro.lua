local tl = ...---@type MainLibObject
local type,OutputDebugMessage,error = type,OutputDebugMessage,error
local BaseMacro = tl:classImport('BaseMacro')

---@class LoggingMacro:BaseMacro
local LoggingMacro = BaseMacro:new()
LoggingMacro.singleTrigger = true
function LoggingMacro:execute()
  local config,msg = self.profile.config,self.command
    if msg[1] == nil then
      error("No Message to Display")
    end
    local persist = config.persistLCD
    local stay = msg[2] or config.persistLCD
    if msg.debug then
      OutputDebugMessage(msg[1])
      return
    end
    if type(msg[1]) == "table" then
      tl.tbl:prettyTab(msg[1])
    elseif msg.noLCD == 1 then
      tl.logitech:putNoLCD(msg[1])
    else
      config.persistLCD = stay
      tl:put(msg[1])
      config.persistLCD = persist
    end
  end

return LoggingMacro