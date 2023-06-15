local rv = ... ---@type Revenant
local match, gmatch, concat, type, pairs, next = string.match, string.gmatch, table.concat, type, pairs, next

--[[=============================================================]] --
---@class LintEntry #An object containing type information used for linting
---@field type l<LuaType> #one or more valid lua types
---@field range {[1]?:number, [2]?:number} #for numeric types, the first position is the minimum and the second the maximum value
---@field tableKeys l<LuaType> #the type every key in the table has to fit
---@field tableTypes l<LuaType> #one or more types that every single value in a table has to fit
---@field tableVals l<string> #an enumeration of possible values
---@field test fun(val:any,errTable:string[],term:string):any #a custom test function to apply to the object
---@field noEscape boolean #if true we accept any kind of string value
---@field minLength integer #minimum length of an array
---@field maxLength integer #maximum length of an array
---@field acceptFloat boolean #if false only integers are valid
---@field acceptPercentage boolean #if true a string consisting of numbers followed by "%" is valid as a number
---@field values any[] #an enumeration of possible values of the field
--[[=============================================================]] --
---@alias OptionsLintPreset table<string,LintEntry> | {__all:boolean}
---@alias LuaType "nil"| "number"| "string"| "boolean"| "table"| "function"| "thread"| "userdata"
--[[=============================================================]] --
---Functions for Revenant specific linting
---@class LintingModule
---@field configLintErrors string[] #Linting errors that occurred when linting a configuration
---@field lintErrors string[] #Linting errors that occurred while linting mactos
---@field optionsDefinitions OptionsLintPreset #Lint presets for all user options
---@field genericMacroProperties OptionsLintPreset #Lint presets for the properties available on all macros
local LintingModule = rv.baseClass:new()

---convert an array of strings into a string, if it isn'T already one
---@param val l<string> #string or array of strings
---@param sep? string #the separator to use for concatenating
---@return string #the final combined string
local function _con(val, sep) return type(val) == "table" and concat(val, sep or " ,") or val --[[@as string]] end

---a list of all imported macros
local macTypes = {} ---@type string[]
for k in pairs(rv.importer.classMap) do macTypes[#macTypes + 1] = k end
LintingModule.lintErrors = {}
LintingModule.configLintErrors = {}
local logicValues = {"and", "or", "nor", "nand", "xor", "xnor"}

---checks if a modifier check is a valid modifier code.
---@param val string #the modifier string to check
---@param errTable string[] #target table for error messages
---@param term string #additional information to append to the error message
local function _validMod(val, errTable, term)
   for i in gmatch(val, "%a%a") do -- checking if each value of two letters corresponds to a known modifier code
      if match(i, "[grl][cas]") == nil and match(i, "[cs]l") == nil then errTable[#errTable + 1] = "'" .. i .. "' is not a valid modifier code" .. term .. "." end
   end
end

---checks if a condition is valid
---@param val Condition #the value of a macro condition
---@param errTable string[] #target table for error messages
---@param term string #additional information to append to the error message
local function _validCondition(val, errTable, term)
   local t = type(val)
   if t == "number" and val > rv.profile.globalState.maxKeys then -- if there's not enough buttons on any device
      errTable[#errTable + 1] = "'Error in Condition: a key with the number " .. val .. " does not exist."
   elseif t == "table" then ---@cast val _ConditionOptions
      local log = val.logic or val.l
      if log then
         local logicFound = false -- value needs to be a valid logic value
         for i = 1, #logicValues do
            if log == logicValues[i] then
               logicFound = true
               break
            end
         end
         if not logicFound then errTable[#errTable + 1] = "'Error in Condition: invalid logic mode '" .. log .. "'. valid logic modes are: " .. concat(logicValues, ", ") .. "." end
      end -- condition needs to have some content
      if #val == 0 then
         errTable[#errTable + 1] = "'Error in Condition: Condition or sub-condition is empty."
      else
         for i = 1, #val do _validCondition(val[i], errTable, term) end
      end -- recursively calling for nested conditions
   elseif t ~= "number" and t ~= "string" and t ~= "function" then
      errTable[#errTable + 1] = "'Error in Condition: condition of invalid type '" .. val .. "'."
   end
end

---@private
---the main linting function for properties and their contents
---@param table any[] #The command section of a macro
---@param preset LintEntry #the lint command property of the macro
---@param macType string #name of the macro type
---@return string[] #the table of lint errors
function LintingModule:_lintCommands(table, preset, macType)
   local def = preset or self.genericTableContents
   local err = {} ---@type string[]
   local desig = " of macro type " .. macType
   local tabLen = #table -- checking table properties
   if def.minLength ~= nil and tabLen < def.minLength then err[#err + 1] = "The minimum number of entries for the command " .. desig .. " is " .. def.minLength .. ". the current length is " .. tabLen .. "." end
   if def.maxLength ~= nil and tabLen > def.maxLength then err[#err + 1] = "The maximum number of entries for the command " .. desig .. " is " .. def.maxLength .. ". the current length is " .. tabLen .. "." end
   if not tabLen then return err end
   for i = 1, #table do
      local entry = table[i]
      local enType = type(entry)
      if def.type and not rv.tbl:find(def.type, enType) then -- checking table contents
         err[#err + 1] = "Command in position " .. i .. "' of invalid type " .. enType .. ". Accepted values in commands" .. desig .. " are: " .. _con(def.type)
      elseif def.values and enType == "string" then
         if #def.values ~= 0 and not rv.tbl:find(def.values, entry) then err[#err + 1] = "'" .. entry .. "' in position " .. i .. " is not a valid value for entries on commands" .. desig .. ". Accepted values are: '" .. _con(def.values) .. "'" end
      end
   end
   return err
end

---the main linting function for properties and their contents
---@private
---@param table table #the macro properties to check
---@param lintingProfile OptionsLintPreset
---@param options boolean
---@param shorthands table<string,string>
---@param macType? string
---@return string[] #the list of linting errors
function LintingModule:_lintOptions(table, options, lintingProfile, shorthands, macType)
   if type(table) ~= "table" then return {} end
   local hasProfile = next(lintingProfile)
   local desigTerm = macType and " for macro type " .. macType or ""
   local err = {} ---@type string[]
   lintingProfile = (options and lintingProfile) or rv.tbl:intersectSimple(self.genericMacroProperties, lintingProfile, true) -- setting up final linting rules
   local def ---@type LintEntry|true
   local tableType = table.type or "key" -- key macros are the default
   for k, v in pairs(table) do -- iterating over all properties
      if type(k) == "string" then
         if (options or hasProfile) and (not (lintingProfile[k] or (shorthands[k] and lintingProfile[shorthands[k]]))) and not lintingProfile.__all then
            err[#err + 1] = "Unknown option '" .. k .. "'" .. desigTerm -- checking if every key is valid for the macro
         else
            def = lintingProfile[k] or (shorthands[k] and lintingProfile[shorthands[k]]) or {} -- getting linting definitions for a single property
            local defType = type(v) ---saving the data type for multiple tests
            if def.type and (not rv.tbl:find(def.type, defType)) and not (defType == "string" and def.acceptPercentage) then -- disqualifying invalid types
               err[#err + 1] = "option '" .. k .. "' of invalid type " .. defType .. " accepted types" .. desigTerm .. " are: " .. _con(def.type)
            elseif def.values and defType == "string" then
               if (not tableType) or not def.values[tableType] then -- checking value enumeration for table contents
                  if #def.values ~= 0 and not rv.tbl:find(def.values, v) then err[#err + 1] = "'" .. v .. "' is not a valid value for option '" .. k .. "'. Accepted values" .. desigTerm .. " are: '" .. _con(def.values) .. "'" end
               elseif def.values[tableType] then -- checking value enumeration for regular contents
                  if not rv.tbl:find(def.values[tableType], v) then err[#err + 1] = "'" .. v .. "' is not a valid value for option '" .. k .. "' " .. desigTerm .. ". Accepted values are: '" .. _con(def.values[tableType]) .. "'" end
               end
            end
            if defType == "string" and not def.noEscape then -- not letting strings start with special characters
               local illegalStart = match(v, "^[%!%^%°%:%~%#%/\\%@%-]")
               if illegalStart then err[#err + 1] = "Found string value starting with illegal character '" .. illegalStart .. "' on option '" .. k .. "'" .. desigTerm .. "." end
            elseif defType == "number" and v % 1 ~= 0 and not def.acceptFloat then -- integer restriction
               err[#err + 1] = "Value '" .. v .. "' is invalid, only integers are accepted for option '" .. k .. "'" .. desigTerm .. "."
            elseif defType == "number" and def.range and ((def.range[1] and v < def.range[1]) or (def.range[2] and v > def.range[2])) then
               err[#err + 1] = "Value '" .. v .. "' is out of range for option '" .. k .. "'" .. desigTerm .. "." -- restricting range
            elseif defType == "table" and (def.tableKeys or def.tableVals or def.tableTypes) then
               for i, c in pairs(v) do
                  if not rv.tbl:find(rv.presets.stringPresets.internalPropsName, i) then -- excluding internal properties
                     if def.tableKeys and not rv.tbl:find(def.tableKeys, type(i)) then
                        err[#err + 1] = "Table on option '" .. k .. "' contains key of invalid type " .. type(i) .. ". Accepted values " .. desigTerm .. "are:" .. _con(def.tableKeys)
                     elseif def.tableTypes and not rv.tbl:find(def.tableTypes, type(c)) then
                        err[#err + 1] = "Table on option '" .. k .. "' contains value of invalid type " .. type(i) ". Accepted values " .. desigTerm .. "are:" .. _con(def.tableTypes)
                     elseif def.tableVals and not rv.tbl:find(def.tableVals, c) then
                        err[#err + 1] = "'" .. c .. "' is not a valid value for entries on option '" .. k .. "'. Accepted values" .. desigTerm .. " are: '" .. _con(def.tableVals) .. "'"
                     end -- checking value enumerations
                  end
               end
            end
            if def.test then def.test(v, err, desigTerm) end
         end
      end
   end
   return err
end

---Wrapper function for executing and outputting lint results for macro options
---@param table table #the options portion of a macro
---@param macType string #the type of macro that is being checked
---@param lintPreset OptionsLintPreset #Linting preset for this macro type
---@param macroTerm string #The macro's name or id
---@param isName boolean #does the macro have a name?
---@return boolean #true if there were no errors during linting
function LintingModule:keyOptionsLinter(table, macType, lintPreset, shorthands, macroTerm, isName)
   local messages = self:_lintOptions(table, false, lintPreset, shorthands, macType)
   for i = 1, #messages do
      local err = messages[i] -- outputting errors
      self.lintErrors[#self.lintErrors + 1] = "LINT ERROR: " .. err .. " [On " .. ((isName and " Macro " or " Macro:\n") .. macroTerm) .. "]"
   end
   return #messages == 0
end

---Wrapper function for executing and outputting lint results for macro commands
---@param table table #the macro command table to lint
---@param preset l<LintEntry> #one or more lint entries applied to the macro command
---@param macType string #the type of macro being checked
---@param macroTerm string #The macro's name or id
---@param isName boolean #does the macro have a name?
---@return boolean #true if there were no errors during linting
function LintingModule:keyCommandLinter(table, preset, macType, macroTerm, isName)
   local messages = self:_lintCommands(table, preset, macType)
   for i = 1, #messages do
      local err = messages[i] -- outputting errors
      self.lintErrors[#self.lintErrors + 1] = "LINT ERROR: " .. err .. "\non " .. ((isName and " Macro " or " Macro:\n") .. macroTerm) .. "'"
   end
   return #messages == 0
end

---Lint the current configuration
---@param table OptionsCollection
---@return boolean #true if there were no errors during linting
function LintingModule:configLinter(table)
   local messages = self:_lintOptions(table, true, self.optionsDefinitions, {})
   for i = 1, #messages do
      local err = messages[i] -- outputting errors
      self.configLintErrors[#self.configLintErrors + 1] = "CONFIGURATION ERROR: " .. err
   end
   return #messages == 0
end

LintingModule.optionsDefinitions = { ---Type definitions for all Revenant options
   modeSort = {type = {"string", "table"}, values = {"reverse", "standard"}, tableKeys = "number", tableTypes = {"string", "number"}},
   shiftSort = {type = {"string", "table"}, values = {"reverse", "standard"}, tableKeys = "number", tableTypes = "number"},
   keyboardModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   mouseModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   lhcModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   defaultKeys = {type = "table", tableKeys = "string", tableTypes = {"string", "table"}},
   extends = {type = {"table", "string"}, tableKeys = "number", tableTypes = "string"},
   devices = {type = {"string", "table"}, tableKeys = "number", tableTypes = "string"},
   preventInheritance = {type = "table", tableKeys = "number", tableTypes = "string"},
   debounceSettings = {type = "table", tableKeys = "string", tableTypes = "table"},
   keyboardLocale = {type = "string", values = {"de-DE", "en-US", "en-GB"}},
   customSort = {type = "table", tableKeys = "number", tableTypes = "string"},
   rename = {type = "table", tableKeys = "string", tableTypes = "string"},
   defaultModeTarget = {type = {"number", "string"}, range = {0}},
   pollFamily = {type = "string", values = {"lhc", "kb", "mouse"}},
   customStack = {type = "string", values = {"prepend", "append"}},
   shiftStack = {type = "string", values = {"prepend", "append"}},
   modeStack = {type = "string", values = {"prepend", "append"}},
   maxMovementLagSamples = {type = "number", range = {2}},
   lagPositionThreshold = {type = "number", range = {0}},
   keyboardButtonCount = {type = "number", range = {0}},
   LCDMessageDuration = {type = "number", range = {-1}},
   LCDHidePrimaryMode = {type = {"boolean", "string"}},
   globalModes = {type = "table", tableKeys = "number"},
   defaultStacking = {type = "number", range = {0, 2}},
   keyboardModeCount = {type = "number", range = {0}},
   mouseButtonCount = {type = "number", range = {0}},
   waitLagThreshold = {type = "number", range = {1}},
   keyboardShiftKey = {ype = "number", range = {0}},
   defaultShift = {type = "number", range = {0, 2}},
   lhcButtonCount = {type = "number", range = {0}},
   mouseModeCount = {type = "number", range = {0}},
   actionVariance = {type = "number", range = {0}},
   multiClickTime = {type = "number", range = {0}},
   externalConfigs = {type = {"string", "table"}},
   mouseInterval = {type = "number", range = {1}},
   maxLagSamples = {type = "number", range = {2}},
   mouseShiftKey = {type = "number", range = {0}},
   LCDLineLength = {type = "number", range = {0}},
   LCDSeparator = {type = {"boolean", "string"}},
   pollInterval = {type = "number", range = {1}},
   fileLocation = {type = "number", range = {0}},
   historyDepth = {type = "number", range = {0}},
   lhcModeCount = {type = "number", range = {0}},
   keyboardBindHardwareModes = {type = "boolean"},
   keyVariance = {type = "number", range = {0}},
   defaultMode = {type = "number", range = {0}},
   actionDelay = {type = "number", range = {0}},
   defaultHold = {type = "number", range = {0}},
   lhcShiftKey = {type = "number", range = {0}},
   mouseBindHardwareModes = {type = "boolean"},
   keyDelay = {type = "number", range = {0}},
   LCDLines = {type = "number", range = {0}},
   preventOptionOverride = {type = "boolean"},
   LCDLastLinePagination = {type = "boolean"},
   lhcBindHardwareModes = {type = "boolean"},
   separateDeviceCycles = {type = "boolean"},
   restrictToMainScreen = {type = "boolean"},
   LCDPersistentProfile = {type = "boolean"},
   mergeScopeDefaults = {type = "boolean"},
   mergeDocumentation = {type = "boolean"},
   preventDocOverride = {type = "boolean"},
   offsetMovementLag = {type = "boolean"},
   abortOnLintError = {type = "boolean"},
   stackAutoReverse = {type = "boolean"},
   LCDClearLastLine = {type = "boolean"},
   globalModeFamily = {type = "string"},
   strictModifiers = {type = "boolean"},
   enableDebounce = {type = "boolean"},
   primaryButtons = {type = "boolean"},
   enableLinting = {type = "boolean"},
   pollMKeysOnly = {type = "boolean"},
   keepNameOnLCD = {type = "boolean"},
   offsetWaitLag = {type = "boolean"},
   showCompiled = {type = "boolean"},
   globalGShift = {type = "boolean"},
   logDebounce = {type = "boolean"},
   description = {type = "string"},
   logEvents = {type = "boolean"},
   logMemory = {type = "boolean"},
   modeReset = {type = "boolean"},
   outputLCD = {type = "boolean"},
   clearLog = {type = "boolean"},
   stackOrder = {type = "table"},
   monitors = {type = "table"},
   path = {type = "string"}
}

LintingModule.genericMacroProperties = { ---Properties available on all macros
   unlock = {type = {"string", "table"}, tableKeys = "number", tableTypes = "string", values = {"shift", "mode", "mkeys", "area", "condition"}},
   direction = {type = "string", values = {"up", "normal"}},
   condition = {noEscape = true, test = _validCondition},
   logic = {type = "string", values = logicValues},
   mode = {type = {"number", "table", "string"}},
   gshift = {type = "number", range = {0, 2}},
   type = {type = "string", values = macTypes},
   mkey = {type = "string", test = _validMod},
   documentation = {type = "string"},
   __inherited = {type = "boolean"},
   __autoName = {type = "boolean"},
   blocking = {type = "boolean"},
   process = {type = "function"},
   name = {type = "string"},
   area = {type = "table"},
   doc = {type = "string"},
   _inherit = {},
   pID = {}
}

LintingModule.genericTableContents = {type = {"string", "table", "number"}}

return LintingModule
