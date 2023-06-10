local rv = ... ---@type Revenant
local type, OutputDebugMessage, rep = type, OutputDebugMessage, string.rep

--[[=============================================================]] --
---@class _LoggingOptions:MacroOptions
---@field noLCD boolean #Don't show the text on the LCD display
---@field debug boolean #output text content to windows debug
---@field persist integer #The duration the text will stay on the display
---@field keepIndent boolean #respect the indentation of the text, don't trim whitespace after newline
--[[=============================================================]] --
---Assign a macro that logs text either in the console or the LCD screen.
---@alias AssignLogging _LoggingOptions | MacroInitDefinition | mt<"log"|"o">
--[[=============================================================]] --
---A macro that logs text either in the console or the LCD screen.
---@class LoggingMacro:MacroDefinition
---@field command TextDisplay|string
---@field options _LoggingOptions
---@field rawCommand {[1]:string, [2]:integer}
local LoggingMacro = rv.importer:classImport("MacroDefinition"):new()
LoggingMacro.lintProperties = { ---@type OptionsLintPreset
   noLCD = {type = "boolean"},
   debug = {type = "boolean"},
   keepIndent = {type = "boolean"}
}
LoggingMacro.lintCommand = {type = {"string", "table"}, maxLength = 2, tableKeys = "number"}
LoggingMacro.singleTrigger = true

---@protected
function LoggingMacro:parseInstructions()
   local options = self.options
   local logContent = self.rawCommand[1]
   if type(logContent) == "table" then logContent = rv.utils.pprint(logContent) end
   self.command = logContent -- any table will be prettified for logging
   rv.lcd:parseToTextDisplay(logContent, self.pID, nil, nil, options.keepIndent)
   options.persist = self.rawCommand[2] or rv.profile.config.LCDMessageDuration;
   self:finishInit()
end

function LoggingMacro:execute()
   local msg, options = self.command, self.options
   if options.noLCD then
      rv:put(msg) -- only outputting to console
   else
      rv.lcd:displayOnLCD(self.pID, nil, self.options.persist)
   end -- the lcd always outputs to the console as well
   if self.options.debug then OutputDebugMessage((type(msg) == "string" and msg) or msg.text) end -- using the raw LGS function
end

---@param depth? integer
function LoggingMacro:export(depth)
   depth = depth or 0
   local indent = rep("  ", depth) or ""
   return indent .. self.titleExport .. "Log a Message"
end

return LoggingMacro
