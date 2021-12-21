local tl = ...---@type MainLibObject
local type, OutputDebugMessage, error = type, OutputDebugMessage, error

local PaginationMacro = tl:classImport('MacroDefinition'):new()---@class PaginationMacro:MacroDefinition
PaginationMacro.lintProperties = { __none = {} }
PaginationMacro.singleTrigger = true

---@protected
function PaginationMacro:parseInstructions()
    self.command = self.rawCommand[1]
    if type(self.command) == "table" then self.command = tl.helperUtils.pprint(self.command) end
    self.options.persist = self.rawCommand[2] or self.profile.config.persistLCD;
end

function PaginationMacro:execute()
    local config, msg, options = self.profile.config, self.command, self.options
    if msg == nil then error("No Message to Display") end
    local persist = config.persistLCD
    local stay = options.persist
    if options.debug then return OutputDebugMessage(msg) end
    if options.noLCD == 1 then tl.logitech:putNoLCD(msg)
    else
        config.persistLCD = stay
        tl:put(msg)
        config.persistLCD = persist
    end
end

return PaginationMacro