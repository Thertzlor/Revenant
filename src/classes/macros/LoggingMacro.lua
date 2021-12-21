local tl = ...---@type MainLibObject
local type, OutputDebugMessage, error = type, OutputDebugMessage, error
---@class LoggingOptions:MacroOptions
---@field noLCD boolean
---@field debug boolean
---@field persist number
--=============================================================

---@class LoggingMacro:MacroDefinition
---@field command string
---@field options LoggingOptions
local LoggingMacro = tl:classImport('MacroDefinition'):new()
LoggingMacro.lintProperties = { noLCD={type="boolean"}, debug={type="boolean"} }
LoggingMacro.singleTrigger = true

---@protected
function LoggingMacro:parseInstructions()
    local logCont = self.rawCommand[1]
    if type(logCont) == "table" then logCont = tl.helperUtils.pprint(logCont) end
    self.command = tl.lcd:parseToDisplayDefinition(logCont,self.pID).origin
    self.options.persist = self.rawCommand[2] or self.profile.config.persistLCD;
    self:finishInit()
end

function LoggingMacro:execute()
    local config, msg, options = self.profile.config, self.command, self.options
    tl:put("putting shit")
    tl.lcd:displayOnLCD(msg)
    -- if msg == nil then error("No Message to Display") end
    -- local persist = config.persistLCD
    -- local stay = options.persist
    -- if options.debug then return OutputDebugMessage(msg) end
    -- if options.noLCD == 1 then tl.logitech:putNoLCD(msg)
    -- else
    --     config.persistLCD = stay
    --     tl:put(msg)
    --     config.persistLCD = persist
    -- end
end

return LoggingMacro