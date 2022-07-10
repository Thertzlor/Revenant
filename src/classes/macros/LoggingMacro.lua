local rv = ... ---@type Revenant
local type, OutputDebugMessage, rep = type, OutputDebugMessage, string.rep

--[[=============================================================]] --
---@class _LoggingOptions:MacroOptions
---@field noLCD boolean
---@field debug boolean  I am not a rtutle
---@field persist number Wango says hi.
---@field keepIndent boolean
--[[=============================================================]] --
---Assign a macro that logs text either in the console or the LCD screen.
---@alias AssignLogging _LoggingOptions | MacroInitDefinition | mt<"log"|"o">
--[[=============================================================]] --
---A macro that logs text either in the console or the LCD screen.
---@class LoggingMacro:MacroDefinition
---@field command TextDisplay|string
---@field options _LoggingOptions
---@field rawCommand {[1]:string, [2]:number}
local LoggingMacro = rv:classImport('MacroDefinition'):new()
LoggingMacro.lintProperties = { noLCD = { type = "boolean" }, debug = { type = "boolean" }, keepIndent = { type = "boolean" } }
LoggingMacro.singleTrigger = true

---@protected
function LoggingMacro:parseInstructions()
    local options = self.options
    local logCont = self.rawCommand[1]
    if type(logCont) == "table" then logCont = rv.utils.pprint(logCont) end
    self.command = logCont
    rv.lcd:parseToTextDisplay(logCont, self.pID, nil, nil, options.keepIndent)
    options.persist = self.rawCommand[2] or rv.profile.config.LCDMessageDuration;
    self:finishInit()
end

function LoggingMacro:execute()
    local msg, options = self.command, self.options
    if options.noLCD then rv:put(msg)
    else rv.lcd:displayOnLCD(self.pID, nil, self.options.persist) end
    if self.options.debug then OutputDebugMessage(msg) end
end

---@param depth? integer
function LoggingMacro:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. "Log a Message"
end

return LoggingMacro
