local tl = ...---@type MainLibObject
local match, gmatch, concat, type, pairs,next = string.match, string.gmatch, table.concat, type, pairs,next
--=============================================================
local LintingModule = tl.baseClass:new()---@class LintingModule:BaseClass Functions for T-Lib specific linting

local macTypes = {}
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
---@param options boolean
---@return boolean,string
function LintingModule:_lintingProcess(table, options,lintingProfile,shortHands)
  if type(table) ~= "table" then return true,false end
  local propTerm = (options and "option") or "property"
  local hasProfile = next(lintingProfile)
  lintingProfile = (options and lintingProfile) or tl.tbl:intersectSimple(self.genericMacroProperties,lintingProfile,true) 
  local def
  local tableType = table.type or "key"
  for k, v in pairs(table) do
    if type(k) == "string" then
      if ((options or hasProfile) and not lintingProfile[k]) then
        return false, "Found unknown " .. propTerm .. " '" .. k .. "'"
      end
      def = lintingProfile[k] or (shortHands[k] and lintingProfile[shortHands[k]]) or {}
      if tableType and def.propertyOf and not tl.tbl:find(def.propertyOf, tableType) then
        return false, "A macro of type '" .. tableType .. "' has no " .. propTerm .. " '" .. k .. "'"
      end
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
      if type(v) == "string" then
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
---@param macroTerm string
---@param isName boolean
function LintingModule:KeyLinter(table,lintPreset,shortHands,macroTerm,isName)
  local res, mes = self:_lintingProcess(table,false,lintPreset,shortHands)
  if res == false then
    self.lintErrors[#self.lintErrors+1] = "LINT ERROR: " .. mes .. " on " .. ((isName and ' Macro ' or ' Macro:\n')..macroTerm) .. "'"
  end
  return res
end

function LintingModule:configLinter(table)
  local res, mes = self:_lintingProcess(table,true,self.optionsDefinitions,{})
  if res == false then
    self.configLintErrors[#self.configLintErrors+1] = "CONFIGURATION ERROR: " .. mes
  end
  return res
end

LintingModule.optionsDefinitions = {
  profileName = {type = "string"},
  path = {type = "string"},
  extPaths = {type = "table",tableKeys = "number",tableTypes = "string"},
  childPaths = {type = "boolean"},
  fileLocation = {type = "number",range = {0}},
  keyFile = {type = "string"},
  defaultMode = {type = "number",range = {0}},
  defaultShift = {type = "number",range = {0, 2}},
  genericModes = {type = "table",tableKeys = "number"},
  customNames = {type = "boolean"},
  actionDelay = {type = "number",range = {0}},
  keyDelay = {type = "number",range = {0}},
  defaultHold = {type = "number",range = {0}},
  multiClickTime = {type = "number",range = {0}},
  pollInterval = {type = "number",range = {1}},
  pollFamily = {type = "string",values = {"lhc", "kb", "mouse"}},
  actionVariance = {type = "number",range = {0}},
  keyVariance = {type = "number",range = {0}},
  defaultStacking = {type = "number",range = {0, 2}},
  preferShorthand = {type = "boolean"},
  historyDepth = {type = "number",range = {0}},
  mouseInterval = {type = "number",range = {1}},
  mouseHistoryLimit = {type = "number",range = {0}},
  logEvents = {type = "boolean"},
  logMemory = {type = "boolean"},
  externalConfigs = {type="string"},
  logBounce = {type = "boolean"},
  primaryButtons = {type = "boolean"},
  clearLog = {type = "boolean"},
  extends = {type = {"table", "string"},tableKeys = "number",tableTypes = "string"},
  debouncerSettings = {type="table",tableKeys="string",tableTypes="table"},
  enableLinting = {type = "boolean"},
  abortOnLintError = {type = "boolean"},
  enableConfigLinting = {type = "boolean"},
  hubMode = {type = "boolean"},
  resolutions = {type = "table"},
  scaleCoordinates = {type = "boolean"},
  separateDeviceCycles = {type = "boolean"},
  defaultModeTarget = {type = {"number", "string"},range = {0}},
  logLevel = {type = "number",range = {0, 2}},
  mouseButtonCount = {type = "number",range = {0}},
  mouseShiftKey = {type = "number",range = {0}},
  mouseModeCount = {type = "number",range = {0}},
  mouseModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  mouseBindHardwareModes = {type = "boolean"},
  mousePositionCheck = {type = "boolean"},
  keyboardButtonCount = {type = "number",range = {0}},
  keyboardShiftKey = {ype = "number",range = {0}},
  keyboardModeCount = {type = "number",range = {0}},
  keyboardModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  keyboardBindHardwareModes = {type = "boolean"},
  lhcButtonCount = {type = "number",range = {0}},
  lhcShiftKey = {type = "number",range = {0}},
  lhcModeCount = {type = "number",range = {0}},
  lhcModeConfig = {type = "table",tableKeys = "number",tableTypes = {"string", "table"}},
  lhcBindHardwareModes = {type = "boolean"},
  outputLCD = {type = "boolean"},
  clearLCD = {type = "boolean"},
  persistLCD = {type = "number",range = {-1}},
  keepNameOnLCD = {type = "boolean"},
  appendNewLines = {type = "number",range = {0}},
  docModeButtonLock = {type = "boolean"},
  charsPerLine = {type = "number",range = {0}},
  displayLines = {type = "number",range = {0}},
  defaultDocPath = {type = "table",tableKeys = "string"},
  defaultConfigPath = {type = "table",tableKeys = "string"},
  showCompiled = {type = "boolean"},
  modeStack = {type = "string",values = {"prepend", "append"}},
  shiftStack = {type = "string",values = {"prepend", "append"}},
  customStack = {type = "string",values = {"prepend", "append"}},
  modeSort = {type = {"string", "table"},values = {"reverse", "standard"},tableKeys = "number",tableTypes = {"string", "number"}},
  shiftSort = {type = {"string", "table"},values = {"reverse", "standard"},tableKeys = "number",tableTypes = "number"},
  customSort = {type = "table",tableKeys = "number",tableTypes = "string"},
  stackOrder = {type = "table"},
  stackAutoReverse = {type = "boolean"},
  maxInheritanceDepth = {type = "number",range = {0}},
  handleOptionConflicts = {type = {"string", "number"},values = {"replaceDuplicates", "useFirst", "useLast", "discardDuplicates"},range = {0}},
  handleDocumentationConflicts = {type = {"string", "number"},values = {"replaceDuplicates", "useFirst", "useLast", "discardDuplicates"},range = {0}},
  defaultKeys = {type = "table",tableKeys = "string",tableTypes = {"string", "table"}},
  rename = {type = "table",tableKeys = "string",tableTypes = "string"}
}

LintingModule.genericMacroProperties = {
  type = {type = "string",values = macTypes},
  gshift = {type = "number",range = {0, 2}},
  mode = {type = {"number", "table", "string"}},
  mkey = {type = "string",test = _validMod},
  pID = {},
  area = {type = "table"},
  blocking = {type = "number",range = {1, 3}},
  direction = {type = "string",values = {"up", "normal"}},
  condition = {},
  unlock = {type = {"string", "table"},tableKeys = "number",tableTypes = "string",values = {"shift", "mode", "mkeys", "area", "condition"}},
  doc = {type = "string"},
  logic = {type = "string",values = {"and", "or", "nor", "nand", "xor", "xnor"}},
  name = {type = "string"},
  __autoName={type="boolean"}
}

return LintingModule