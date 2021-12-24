local tl = ...---@type MainLibObject
local type, OutputDebugMessage, error, rep = type, OutputDebugMessage, error, string.rep
---@class LoggingOptions:MacroOptions
---@field noLCD boolean
---@field debug boolean
---@field persist number
---@field keepIndent boolean
--=============================================================
---@class LoggingMacro:MacroDefinition
---@field command DisplayTextDefinition
---@field options LoggingOptions
local LoggingMacro = tl:classImport('MacroDefinition'):new()
LoggingMacro.lintProperties = { noLCD = { type = "boolean" }, debug = { type = "boolean" }, keepIndent = { type = "boolean" } }
LoggingMacro.singleTrigger = true

---@protected
function LoggingMacro:parseInstructions()
    local options = self.options
    local logCont = self.rawCommand[1] ---@type string
    if type(logCont) == "table" then logCont = tl.helperUtils.pprint(logCont) end
    self.command = logCont
    tl.lcd:parseToDisplayDefinition(logCont, self.pID, nil, nil, options.keepIndent)
    options.persist = self.rawCommand[2] or self.profile.config.persistLCD;
    self:finishInit()
end

function LoggingMacro:execute()
    local config, msg, options = self.profile.config, self.command, self.options
    if options.noLCD then tl:put(msg)
    else tl.lcd:displayOnLCD(self.pID, self.options.persist) end
end

function LoggingMacro:export(depth)
    depth = depth or 0
    local fam = self.options.family
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Log a Message"
end

return LoggingMacro