local rv = ...---@type Revenant
local match, gmatch, concat, type, pairs, next = string.match, string.gmatch, table.concat, type, pairs, next
--=============================================================
---@class LintEntry
---@field type string|string[]
---@field range number[]
---@field tableKeys string
---@field tableTypes string|string[]
---@field tableVals string|string[]
---@field test fun(val:any,errTable:string[],term:string):any 
---@field noEscape boolean
---@field minLength number
---@field acceptFloat boolean
---@field values any
---@field maxLength number
--=============================================================
---@alias OptionsLintPreset table<string,LintEntry>
--=============================================================
---@class LintingModule:BaseClass Functions for Revenant specific linting
---@field configLintErrors string[]
---@field lintErrors string[]
---@field optionsDefinitions OptionsLintPreset
---@field genericMacroProperties OptionsLintPreset
local LintingModule = rv.baseClass:new()

---@param val any|any[]
---@param sep string
local function _con(val, sep) return concat(type(val) == "table" and val or { val }, sep or ' ,') end

local macTypes = {}---@type string[]
for k in pairs(rv.classMap) do macTypes[#macTypes + 1] = k end
LintingModule.lintErrors = {}
LintingModule.configLintErrors = {}
local logicValues = { "and", "or", "nor", "nand", "xor", "xnor" }

---checks if a modifier check is a valid modifier code.
---@param val string
---@param errTable string[]
---@param term string
local function _validMod(val, errTable, term)
    for i in gmatch(val, "%a%a") do
        if match(i, "[grl][cas]") == nil and match(i, "[cs]l") == nil then errTable[#errTable + 1] = "'" .. i .. "' is not a valid modifier code" .. term .. "." end
    end
end

---checks if a condition is valid
---@param val Condition
---@param errTable string[]
---@param term string
local function _validCondition(val, errTable, term)
    local t = type(val)
    if t == "number" and val > rv.profile.globalState.maxKeys then
        errTable[#errTable + 1] = "'Error in Condition: a key with the number " .. val .. " does not exist."
    elseif t == "table" then
        local log = val.logic or val.l
        if log then
            local logicFound = false
            for i = 1, #logicValues do
                if log == logicValues[i] then
                    logicFound = true
                    break
                end
            end
            if not logicFound then
                errTable[#errTable + 1] = "'Error in Condition: invalid logic mode '" .. log .. "'. valid logic modes are: " .. concat(logicValues, ', ') .. '.'
            end
        end
        if #val == 0 then
            errTable[#errTable + 1] = "'Error in Condition: Condition or sub-condition is empty."
        else for i = 1, #val do _validCondition(val[i], errTable, term) end end
    elseif t ~= "number" and t ~= "string" and t ~= "function" then
        errTable[#errTable + 1] = "'Error in Condition: condition of invalid type '" .. val .. "'."
    end
end

---the main linting function for properties and their contents
---@private
---@param table any[]
---@param  preset LintEntry
---@param  macType string
---@return string[]
function LintingModule:_lintCommands(table, preset, macType)
    local def = preset or self.genericTableContents
    local err = {} ---@type string[]
    local desig = " of macro type " .. macType
    local tabLen = #table
    if def.minLength ~= nil and tabLen > def.minLength then err[#err + 1] = "The minimum number of entries for the command " .. desig .. " is " .. def.minLength .. ". the current length is " .. tabLen .. "." end
    if def.maxLength ~= nil and tabLen < def.maxLength then err[#err + 1] = "The maximum number of entries for the command " .. desig .. " is " .. def.maxLength .. ". the current length is " .. tabLen .. "." end
    if not tabLen then return err end
    for i = 1, #table do local entry = table[i]
        local enType = type(entry)
        if def.type and not rv.tbl:find(def.type, enType) then
            err[#err + 1] = "Command in position " .. i .. "' of invalid type " .. enType .. ". Accepted values in commands" .. desig .. ' are: ' .. _con(def.type)
        elseif def.values and enType == "string" then
            if #def.values ~= 0 and not rv.tbl:find(def.values, entry) then
                err[#err + 1] = "'" .. entry .. "' in position " .. i .. " is not a valid value for entries on commands" .. desig .. ". Accepted values are: '" .. _con(def.values) .. "'"
            end
        end
    end
    return err
end

---the main linting function for properties and their contents
---@private
---@param table table
---@param lintingProfile OptionsLintPreset
---@param options boolean
---@param shortHands table<string,string>
---@param macType string
---@return string[]
function LintingModule:_lintOptions(table, options, lintingProfile, shortHands, macType)
    if type(table) ~= "table" then return {} end
    local hasProfile = next(lintingProfile)
    local desigTerm = macType and ' for macro type ' .. macType or ''
    local err = {} ---@type string[]
    lintingProfile = (options and lintingProfile) or rv.tbl:intersectSimple(self.genericMacroProperties, lintingProfile, true)
    local def ---@type LintEntry
    local tableType = table.type or "key"
    for k, v in pairs(table) do
        if type(k) == "string" then
            if k == "shonky" then rv:put("ALARM ALARM") end
            if (options or hasProfile) and (not (lintingProfile[k] or (shortHands[k] and lintingProfile[shortHands[k]]))) and not lintingProfile.__all then
                err[#err + 1] = "Unknown option '" .. k .. "'" .. desigTerm
            else
                def = lintingProfile[k] or (shortHands[k] and lintingProfile[shortHands[k]]) or {}
                local defType = type(v)
                if def.type and not rv.tbl:find(def.type, defType) then
                    err[#err + 1] = "option '" .. k .. "' of invalid type " .. defType .. ' accepted types' .. desigTerm .. ' are: ' .. _con(def.type)
                elseif def.values and defType == "string" then
                    if (not tableType) or not def.values[tableType] then
                        if #def.values ~= 0 and not rv.tbl:find(def.values, v) then
                            err[#err + 1] = "'" .. v .. "' is not a valid value for option '" .. k .. "'. Accepted values" .. desigTerm .. " are: '" .. _con(def.values) .. "'"
                        end
                    elseif def.values[tableType] then
                        if not rv.tbl:find(def.values[tableType], v) then
                            err[#err + 1] = "'" .. v .. "' is not a valid value for option '" .. k .. "' " .. desigTerm .. ". Accepted values are: '" .. _con(def.values[tableType]) .. "'"
                        end
                    end
                end
                if defType == "string" and not def.noEscape then
                    local illegalStart = match(v, "^[%!%^%°%:%~%#%/\\%@%-]")
                    if illegalStart then err[#err + 1] = "Found string value starting with illegal character '" .. illegalStart .. "' on option '" .. k .. "'" .. desigTerm .. '.' end
                elseif defType == "number" and v%1 ~= 0 and not def.acceptFloat then
                    err[#err + 1] = "Value '" .. v .. "' is invalid, only integers are accepted for option '" .. k .. "'" .. desigTerm .. '.'
                elseif defType == "number" and def.range and ((def.range[1] and v < def.range[1]) or (def.range[2] and v > def.range[2])) then
                    err[#err + 1] = "Value '" .. v .. "' is out of range for option '" .. k .. "'" .. desigTerm .. '.'
                elseif defType == "table" and (def.tableKeys or def.tableVals or def.tableTypes) then
                    for i, c in pairs(v) do
                        if not rv.tbl:find(rv.stringPresets.internalPropsName, i) then
                            if def.tableKeys and not rv.tbl:find(def.tableKeys, type(i)) then err[#err + 1] = "Table on option '" .. k .. "' contains key of invalid type " .. type(i) .. '. Accepted values ' .. desigTerm .. 'are:' .. _con(def.tableKeys)
                            elseif def.tableTypes and not rv.tbl:find(def.tableTypes, type(c)) then err[#err + 1] = "Table on option '" .. k .. "' contains value of invalid type " .. type(i) '. Accepted values ' .. desigTerm .. 'are:' .. _con(def.tableTypes)
                            elseif def.tableVals and not rv.tbl:find(def.tableVals, c) then err[#err + 1] = "'" .. c .. "' is not a valid value for entries on option '" .. k .. "'. Accepted values" .. desigTerm .. " are: '" .. _con(def.tableVals) .. "'" end
                        end
                    end
                end
                if def.test then def.test(v, err, desigTerm) end
            end
        end
    end
    return err
end

---Wrapper function for executing and outputting lint results
---@param table table
---@param macType string
---@param lintPreset OptionsLintPreset
---@param macroTerm string
---@param isName boolean
function LintingModule:keyOptionsLinter(table, macType, lintPreset, shortHands, macroTerm, isName)
    local mes = self:_lintOptions(table, false, lintPreset, shortHands, macType)
    for i = 1, #mes do local err = mes[i]
        self.lintErrors[#self.lintErrors + 1] = "LINT ERROR: " .. err .. " [On " .. ((isName and ' Macro ' or ' Macro:\n') .. macroTerm) .. "]"
    end
    return #mes == 0
end

---Wrapper function for executing and outputting lint results
---@param table table
---@param preset LintEntry|LintEntry[]
---@param macType string
---@param macroTerm string
---@param isName boolean
function LintingModule:keyCommandLinter(table, preset, macType, macroTerm, isName)
    local mes = self:_lintCommands(table, preset, macType)
    for i = 1, #mes do local err = mes[i]
        self.lintErrors[#self.lintErrors + 1] = "LINT ERROR: " .. err .. "\non " .. ((isName and ' Macro ' or ' Macro:\n') .. macroTerm) .. "'"
    end
    return #mes == 0
end

---@param table OptionsCollection
function LintingModule:configLinter(table)
    local mes = self:_lintOptions(table, true, self.optionsDefinitions, {})
    for i = 1, #mes do local err = mes[i]
        self.configLintErrors[#self.configLintErrors + 1] = "CONFIGURATION ERROR: " .. err
    end
    return #mes == 0
end

LintingModule.optionsDefinitions = {
    modeSort = { type = { "string", "table" }, values = { "reverse", "standard" }, tableKeys = "number", tableTypes = { "string", "number" } },
    shiftSort = { type = { "string", "table" }, values = { "reverse", "standard" }, tableKeys = "number", tableTypes = "number" },
    keyboardModeConfig = { type = "table", tableKeys = "number", tableTypes = { "string", "table" } },
    mouseModeConfig = { type = "table", tableKeys = "number", tableTypes = { "string", "table" } },
    lhcModeConfig = { type = "table", tableKeys = "number", tableTypes = { "string", "table" } },
    defaultKeys = { type = "table", tableKeys = "string", tableTypes = { "string", "table" } },
    extends = { type = { "table", "string" }, tableKeys = "number", tableTypes = "string" },
    devices = { type = { "string", "table" }, tableKeys = "number", tableTypes = "string" },
    preventInheritance = { type = "table", tableKeys = "number", tableTypes = "string" },
    debouncerSettings = { type = "table", tableKeys = "string", tableTypes = "table" },
    keyboardLocale = { type = "string", values = { "de-DE", "en-US", "en-GB" } },
    customSort = { type = "table", tableKeys = "number", tableTypes = "string" },
    rename = { type = "table", tableKeys = "string", tableTypes = "string" },
    defaultModeTarget = { type = { "number", "string" }, range = { 0 } },
    pollFamily = { type = "string", values = { "lhc", "kb", "mouse" } },
    customStack = { type = "string", values = { "prepend", "append" } },
    shiftStack = { type = "string", values = { "prepend", "append" } },
    modeStack = { type = "string", values = { "prepend", "append" } },
    defaultConfigPath = { type = "table", tableKeys = "string" },
    maxMovementLagSamples = { type = "number", range = { 2 } },
    defaultDocPath = { type = "table", tableKeys = "string" },
    lagPositionThreshold = { type = "number", range = { 0 } },
    keyboardButtonCount = { type = "number", range = { 0 } },
    LCDMessageDuration = { type = "number", range = {-1 } },
    LCDHidePrimaryMode = { type = { "boolean", "string" } },
    globalModes = { type = "table", tableKeys = "number" },
    defaultStacking = { type = "number", range = { 0, 2 } },
    keyboardModeCount = { type = "number", range = { 0 } },
    mouseHistoryLimit = { type = "number", range = { 0 } },
    mouseButtonCount = { type = "number", range = { 0 } },
    waitLagThreshold = { type = "number", range = { 1 } },
    keyboardShiftKey = { ype = "number", range = { 0 } },
    defaultShift = { type = "number", range = { 0, 2 } },
    lhcButtonCount = { type = "number", range = { 0 } },
    mouseModeCount = { type = "number", range = { 0 } },
    actionVariance = { type = "number", range = { 0 } },
    multiClickTime = { type = "number", range = { 0 } },
    externalConfigs = { type = { "string", "table" } },
    mouseInterval = { type = "number", range = { 1 } },
    maxLagSamples = { type = "number", range = { 2 } },
    mouseShiftKey = { type = "number", range = { 0 } },
    LCDLineLength = { type = "number", range = { 0 } },
    LCDSeparator = { type = { "boolean", "string" } },
    pollInterval = { type = "number", range = { 1 } },
    fileLocation = { type = "number", range = { 0 } },
    historyDepth = { type = "number", range = { 0 } },
    lhcModeCount = { type = "number", range = { 0 } },
    logLevel = { type = "number", range = { 0, 2 } },
    keyboardBindHardwareModes = { type = "boolean" },
    keyVariance = { type = "number", range = { 0 } },
    defaultMode = { type = "number", range = { 0 } },
    actionDelay = { type = "number", range = { 0 } },
    defaultHold = { type = "number", range = { 0 } },
    lhcShiftKey = { type = "number", range = { 0 } },
    mouseBindHardwareModes = { type = "boolean" },
    keyDelay = { type = "number", range = { 0 } },
    LCDLines = { type = "number", range = { 0 } },
    preventOptionOverride = { type = "boolean" },
    LCDLastLinePagination = { type = "boolean" },
    lhcBindHardwareModes = { type = "boolean" },
    separateDeviceCycles = { type = "boolean" },
    restrictToMainScreen = { type = "boolean" },
    LCDPersistentProfile = { type = "boolean" },
    enableConfigLinting = { type = "boolean" },
    mousePositionCheck = { type = "boolean" },
    preventDocOverride = { type = "boolean" },
    offsetMovementLag = { type = "boolean" },
    abortOnLintError = { type = "boolean" },
    scaleCoordinates = { type = "boolean" },
    stackAutoReverse = { type = "boolean" },
    LCDClearLastLine = { type = "boolean" },
    primaryButtons = { type = "boolean" },
    enableLinting = { type = "boolean" },
    pollMKeysOnly = { type = "boolean" },
    keepNameOnLCD = { type = "boolean" },
    offsetWaitLag = { type = "boolean" },
    showCompiled = { type = "boolean" },
    globalGShift = { type = "boolean" },
    profileName = { type = "string" },
    description = { type = "string" },
    resolutions = { type = "table" },
    logEvents = { type = "boolean" },
    logBounce = { type = "boolean" },
    logMemory = { type = "boolean" },
    outputLCD = { type = "boolean" },
    clearLog = { type = "boolean" },
    clearLCD = { type = "boolean" },
    stackOrder = { type = "table" },
    path = { type = "string" }
}

LintingModule.genericMacroProperties = {
    unlock = { type = { "string", "table" }, tableKeys = "number", tableTypes = "string", values = { "shift", "mode", "mkeys", "area", "condition" } },
    direction = { type = "string", values = { "up", "normal" } },
    logic = { type = "string", values = logicValues },
    mode = { type = { "number", "table", "string" } },
    blocking = { type = "boolean" },
    gshift = { type = "number", range = { 0, 2 } },
    type = { type = "string", values = macTypes },
    mkey = { type = "string", test = _validMod },
    documentation = { type = "string" },
    __autoName = { type = "boolean" },
    __inherited = { type = "boolean" },
    _inherit = {},
    condition = { noEscape = true, test = _validCondition },
    name = { type = "string" },
    area = { type = "table" },
    doc = { type = "string" },
    pID = {}
}

LintingModule.genericTableContents = { type = { "string", "table", "number" } }

return LintingModule