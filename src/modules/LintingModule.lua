local tl = ...---@type MainLibObject
local match, gmatch, concat, type, pairs,next = string.match, string.gmatch, table.concat, type, pairs,next
--=============================================================

---@class LintEntry
---@field type string|string[]
---@field range number[]
---@field tableKeys string
---@field tableTypes string|string[]
---@field _test fun(any):boolean 
---@field noEscape boolean

---@alias LintPreset table<string,LintEntry>

---@class LintingModule:BaseClass Functions for T-Lib specific linting
---@field configLintErrors string[]
---@field optionsDefinitions LintPreset
---@field genericMacroProperties LintPreset
local LintingModule = tl.baseClass:new()


local macTypes = {}---@type string[]
for k in pairs(tl.classMap) do macTypes[#macTypes+1] = k end
LintingModule.lintErrors = {}
LintingModule.configLintErrors = {}
---checks if a modifier check is a valid modifier code.
---@param val string
---@return boolean,string
local function _validMod(val)
  for i in gmatch(val, "%a%a") do
    if match(i, "[grl][cas]") == nil and match(i, "[cs]l") == nil then
      return false, "'" .. i .. "' is not a valid modifier code"
    end
  end
  return true
end

---the main linting function for properties and their contents
---@private
---@param table table
---@param lintingProfile LintPreset
---@param options boolean
---@return boolean,string
function LintingModule:_lintingProcess(table, options,lintingProfile,shortHands)
  if type(table) ~= "table" then return true,false end
  local propTerm = (options and "option") or "property"
  local hasProfile = next(lintingProfile)
  lintingProfile = (options and lintingProfile) or tl.tbl:intersectSimple(self.genericMacroProperties,lintingProfile,true) 
  local def ---@type LintEntry
  local tableType = table.type or "key"
  for k, v in pairs(table) do
    if type(k) == "string" then
      if (options or hasProfile) and (not (lintingProfile[k] or (shortHands[k] and lintingProfile[shortHands[k]]))) and not lintingProfile.__all  then
        --TODO:Reflect new linting procedures
        return false, "Found unknown " .. propTerm .. " '" .. k .. "'"
      end
      def = lintingProfile[k] or (shortHands[k] and lintingProfile[shortHands[k]]) or {}
      if def.type and not tl.tbl:find(def.type, type(v)) then
        return false, propTerm .. " '" .. k .. "' of invalid type " .. type(v)
      end
      if def.values and type(v) == "string" then
        if (not tableType) or not def.values[tableType] then
          if #def.values ~= 0 and not tl.tbl:find(def.values, v) then
            return false, "'" ..v.."' is not a valid value for " ..propTerm .." '" .. k .. "'. Accepted values are: '" .. concat(def.values, "' ,'") .. "'"
          end
        elseif def.values[tableType] then
          if not tl.tbl:find(def.values[tableType], v) then
            return false, "'" ..v.."' is not a valid value for " ..propTerm.." '" ..k .."' on macro type '"..tableType .."'. Accepted values are: '"..concat(def.values[tableType], "' ,'") .. "'"
          end
        end
      end
      if type(v) == "string" and not def.noEscape then
        local illegalStart = match(v, "^[%!%^%°%:%~%#%/\\%@%-]")
        if illegalStart then
          return false, "Found string value starting with illegal character '" .. illegalStart .. "' on " .. propTerm .. " " .. k
        end
      end
      if def.range and type(v) == "number" and ((def.range[1] and v < def.range[1]) or (def.range[2] and v > def.range[2])) then
        return false, "Value '" .. v .. "' is out of range for " .. propTerm .. " '" .. k .. "'."
      end
      if type(v) == "table" and (def.tableKeys or def.tableVals or def.tableTypes) then
        for i, c in pairs(v) do
          if not tl.tbl:find(tl.stringPresets.internalPropsName, i) then
            if def.tableKeys and not tl.tbl:find(def.tableKeys, type(i)) then
              return false, "Table on " .. propTerm .. " '" .. k .. "' contains key of invalid type " .. type(i)
            end
            if def.tableTypes and not tl.tbl:find(def.tableTypes, type(c)) then
              return false, "Table on " .. propTerm .. " '" .. k .. "' contains value of invalid type " .. type(i)
            end
            if def.tableVals and not tl.tbl:find(def.tableVals, c) then
              return false, "'" ..c .."' is not a valid value for entries on" ..propTerm .." '" ..k .. "'. Accepted values are: '" .. concat(def.tableVals, "' ,'") .. "'"
            end
          end
        end
      end
      if def.test then return def.test(v) end
    end
  end
  return true
end
---Wrapper function for executing and outputting lint results
---@param table table
---@param lintPreset LintPreset
---@param macroTerm string
---@param isName boolean
function LintingModule:KeyLinter(table,lintPreset,shortHands,macroTerm,isName)
  local res, mes = self:_lintingProcess(table,false,lintPreset,shortHands)
  if res == false then
    self.lintErrors[#self.lintErrors+1] = "LINT ERROR: " .. mes .. " on " .. ((isName and ' Macro ' or ' Macro:\n')..macroTerm) .. "'"
  end
  return res
end

---@param table OptionsCollection
function LintingModule:configLinter(table)
  local res, mes = self:_lintingProcess(table,true,self.optionsDefinitions,{})
  if res == false then
    self.configLintErrors[#self.configLintErrors+1] = "CONFIGURATION ERROR: " .. mes
  end
  return res
end

LintingModule.optionsDefinitions = {
  handleDocumentationConflicts = {type = {"string", "number"},values = {"replaceDuplicates", "useFirst", "useLast", "discardDuplicates"},range = {0}},
  handleOptionConflicts = {type = {"string", "number"},values = {"replaceDuplicates", "useFirst", "useLast", "discardDuplicates"},range = {0}},
  modeSort = {type = {"string", "table"},values = {"reverse", "standard"},tableKeys = "number",tableTypes = {"string", "number"}},
  shiftSort = {type = {"string", "table"},values = {"reverse", "standard"},tableKeys = "number",tableTypes = "number"},
  keyboardModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  mouseModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  lhcModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  defaultKeys = {type = "table",tableKeys = "string",tableTypes = {"string", "table"}},
  extends = {type = {"table", "string"},tableKeys = "number",tableTypes = "string"},
  customSort = {type = "table",tableKeys = "number",tableTypes = "string"},
  debouncerSettings = {type="table",tableKeys="string",tableTypes="table"},
  extPaths = {type = "table",tableKeys = "number",tableTypes = "string"},
  rename = {type = "table",tableKeys = "string",tableTypes = "string"},
  pollFamily = {type = "string",values = {"lhc", "kb", "mouse"}},
  customStack = {type = "string",values = {"prepend", "append"}},
  shiftStack = {type = "string",values = {"prepend", "append"}},
  defaultModeTarget = {type = {"number", "string"},range = {0}},
  modeStack = {type = "string",values = {"prepend", "append"}},
  defaultConfigPath = {type = "table",tableKeys = "string"},
  defaultDocPath = {type = "table",tableKeys = "string"},
  genericModes = {type = "table",tableKeys = "number"},
  lagPositionThreshold = {type = "number",range = {0}},
  keyboardButtonCount = {type = "number",range = {0}},
  maxInheritanceDepth = {type = "number",range = {0}},
  defaultStacking = {type = "number",range = {0, 2}},
  keyboardModeCount = {type = "number",range = {0}},
  mouseHistoryLimit = {type = "number",range = {0}},
  mouseButtonCount = {type = "number",range = {0}},
  keyboardShiftKey = {ype = "number",range = {0}},
  defaultShift = {type = "number",range = {0, 2}},
  lagSampleAmount = {type = "number",range = {1}},
  keyboardBindHardwareModes = {type = "boolean"},
  lhcButtonCount = {type = "number",range = {0}},
  mouseModeCount = {type = "number",range = {0}},
  actionVariance = {type = "number",range = {0}},
  multiClickTime = {type = "number",range = {0}},
  appendNewLines = {type = "number",range = {0}},
  permissibleLag = {type = "number",range = {0}},
  mouseInterval = {type = "number",range = {1}},
  mouseShiftKey = {type = "number",range = {0}},
  lagSampleSize = {type = "number",range = {0}},
  pollInterval = {type = "number",range = {1}},
  fileLocation = {type = "number",range = {0}},
  historyDepth = {type = "number",range = {0}},
  displayLines = {type = "number",range = {0}},
  charsPerLine = {type = "number",range = {0}},
  lhcModeCount = {type = "number",range = {0}},
  logLevel = {type = "number",range = {0, 2}},
  mouseBindHardwareModes = {type = "boolean"},
  persistLCD = {type = "number",range = {-1}},
  keyVariance = {type = "number",range = {0}},
  defaultMode = {type = "number",range = {0}},
  actionDelay = {type = "number",range = {0}},
  defaultHold = {type = "number",range = {0}},
  lhcShiftKey = {type = "number",range = {0}},
  lhcBindHardwareModes = {type = "boolean"},
  separateDeviceCycles = {type = "boolean"},
  enableConfigLinting = {type = "boolean"},
  keyDelay = {type = "number",range = {0}},
  restrictToMainScreen = {type="boolean"},
  mousePositionCheck = {type = "boolean"},
  docModeButtonLock = {type = "boolean"},
  abortOnLintError = {type = "boolean"},
  scaleCoordinates = {type = "boolean"},
  stackAutoReverse = {type = "boolean"},
  preferShorthand = {type = "boolean"},
  primaryButtons = {type = "boolean"},
  enableLinting = {type = "boolean"},
  pollMKeysOnly = {type = "boolean"},
  keepNameOnLCD = {type = "boolean"},
  showCompiled = {type = "boolean"},
  externalConfigs = {type="string"},
  customNames = {type = "boolean"},
  profileName = {type = "string"},
  childPaths = {type = "boolean"},
  resolutions = {type = "table"},
  logEvents = {type = "boolean"},
  logBounce = {type = "boolean"},
  logMemory = {type = "boolean"},
  outputLCD = {type = "boolean"},
  clearLog = {type = "boolean"},
  clearLCD = {type = "boolean"},
  stackOrder = {type = "table"},
  hubMode = {type = "boolean"},
  keyFile = {type = "string"},
  path = {type = "string"},
}

LintingModule.genericMacroProperties = {
  unlock = {type = {"string", "table"},tableKeys = "number",tableTypes = "string",values = {"shift", "mode", "mkeys", "area", "condition"}},
  logic = {type = "string",values = {"and", "or", "nor", "nand", "xor", "xnor"}},
  direction = {type = "string",values = {"up", "normal"}},
  mode = {type = {"number", "table", "string"}},
  blocking = {type = "number",range = {1, 3}},
  type = {type = "string",values = macTypes},
  gshift = {type = "number",range = {0, 2}},
  mkey = {type = "string",test = _validMod},
  condition = {noEscape=true},
  __autoName={type="boolean"},
  name = {type = "string"},
  area = {type = "table"},
  doc = {type = "string"},
  pID = {}
}

return LintingModule