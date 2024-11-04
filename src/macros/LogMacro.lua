local rv = ... ---@type Revenant
local type, OutputDebugMessage, super = type, OutputDebugMessage, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _LogOptions:MacroOptions
---@field noLCD? boolean #Don't show the text on the LCD display
---@field debug? boolean #output text content to windows debug
---@field persist? integer #The duration the text will stay on the display
---@field keepIndent? boolean #respect the indentation of the text, don't trim whitespace after newline
--[[=============================================================]] --
---Assign a macro that logs text either in the console or the LCD screen.
---@alias AssignLog MacroInitDefinition<"log","o",_LogOptions,(string|table)[]>
--[[=============================================================]] --
---A macro that logs text either in the console or the LCD screen.
---@class (exact) LogMacro:MacroDefinition
---@field command TextDisplay|string
---@field options _LogOptions
---@field private rawCommand {[1]:string, [2]:integer}
local LogMacro = super:new()
LogMacro.type = "log"
LogMacro.lintProperties = { --
   noLCD = {type = "boolean"},
   debug = {type = "boolean"},
   persist = {type = "number"},
   keepIndent = {type = "boolean"}
}
LogMacro.lintCommand = {type = {"string", "table"}, maxLength = 1, tableKeys = "number"}
LogMacro.singleTrigger = true

---@protected
---@async
function LogMacro:parseInstructions()
   local options = self.options
   local logContent = self.rawCommand[1]
   if type(logContent) == "table" then logContent = rv.utils.pprint(logContent) end
   self.command = logContent -- any table will be prettified for logging
   rv.lcd:parseToTextDisplay(logContent, self.pID, nil, nil, options.keepIndent)
   options.persist = self.options.persist or rv.profile.config.LCDMessageDuration;
   self:finishInit()
end

---@async
function LogMacro:execute()
   local msg, options = self.command, self.options
   if options.noLCD then
      rv:put(msg) -- only outputting to console
   else
      rv.lcd:displayOnLCD(self.pID, nil, self.options.persist)
   end -- the lcd always outputs to the console as well
   if self.options.debug then OutputDebugMessage((type(msg) == "string" and msg) or msg.text) end -- using the raw LGS function
end

---@param depth? integer
function LogMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Log a Message" end

return LogMacro
