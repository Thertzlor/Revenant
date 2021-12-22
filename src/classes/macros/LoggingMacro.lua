local tl = ...---@type MainLibObject
local type, OutputDebugMessage, error = type, OutputDebugMessage, error
---@class LoggingOptions:MacroOptions
---@field noLCD boolean
---@field debug boolean
---@field persist number
--=============================================================
---@class LoggingMacro:MacroDefinition
---@field command DisplayTextDefinition
---@field options LoggingOptions
local LoggingMacro = tl:classImport('MacroDefinition'):new()
LoggingMacro.lintProperties = { noLCD = { type = "boolean" }, debug = { type = "boolean" } }
LoggingMacro.singleTrigger = true

---@protected
function LoggingMacro:parseInstructions()
    local logCont = self.rawCommand[1] ---@type string
    if type(logCont) == "table" then logCont = tl.helperUtils.pprint(logCont) end
    self.command = logCont
    tl.lcd:parseToDisplayDefinition(logCont, self.pID)
    self.options.persist = self.rawCommand[2] or self.profile.config.persistLCD;
    self:finishInit()
end

function LoggingMacro:execute()
    local config, msg, options = self.profile.config, self.command, self.options
    if options.noLCD then tl:put(msg)
    else tl.lcd:displayOnLCD(self.pID, self.options.persist) end
end

return LoggingMacro