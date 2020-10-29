
local defaultPaths = {
  profileName = "no_name", --Compile relevant
  path = "", --load relevant
  extPaths = {"profiles/ext_lua", "profiles/ext_work"}, --load relevant
  childPaths = true, --load relevant
  fileLocation = 0, --load relevant
  -- additional files
  defaultDocPath = {path = "", prefix = "", suffix = "_doc", name = ""},
  defaultConfigPath = {path = "", prefix = "", suffix = "_config", name = ""},
  keyFile = "T-lib_keySetup.lua"
}

local macroTerms = {
  {"KeyMacro","key","k"},
  {"KeyMacro","keyup","u"},
  {"KeyMacro","keydown","d"},
  {"GroupMacro","group","g"},
  {"KeyMacro","wrapkey","kw"},
  {"KeyMacro","keytoggle","kt"},
  {"ControlMacro","holdcancel","hc"},
  {"ControlMacro","cyclecontrol","cc"},
  {"ControlMacro","sequencecontrol","sc"},
  {"FlagMacro","flag","f"},
  {"FlagMacro","toggleflag","ft"},
  {"LinkMacro","link","l"},
  {"CycleMacro","cycle","c"},
  {"LoggingMacro","log","o"},
  {"HoldKeyMacro","holdkey","h"}, 
  {"ModeChangeMacro","mode","m"},
  {"SequenceMacro","sequence","s"},
  {"ExternalMacro","playmacro","e"},
  {"FunctionMacro","function","fn"},
  {"MouseMoveMacro","mousemove","p"}, 
  {"BackLightMacro","backlight","b"},
  {"KeyBufferMacro","bufferkey","kb"},
  {"MouseWheelMacro","mousewheel","w"},
  {"MultiClickMacro","multiclick","t"},
  {"MonitorMacro","monitorchange","ms"},
  {"ClearHistoryMacro","wipehistory","dh"},
  {"DocToggleMacro","documentation","doc"}}
  --Default values for the options specified in the logitech bindings, as a fallback
  ---@class OptionsCollection
  local defaultConfiguration = {
  defaultConfigPath = {path = "", prefix = "", suffix = "_config", name = ""}, 
  defaultDocPath = {path = "", prefix = "", suffix = "_doc", name = ""},
  handleDocumentationConflicts = "replaceDuplicates",
  mouseModeConfig = {"mode 1", "mode 2", "mode 3"}, --Compile relevant
  handleLibraryConflicts = "replaceDuplicates",
  handleOptionConflicts = "replaceDuplicates",
  stackOrder = {"custom", "mode", "shift"},
  lockFlexCompilationSettings = true,
  keyboardBindHardwareModes = true,
  audioBindHardwareModes = false,
  handleKeyConflicts = "append",
  automaticTypeDetection = true,
  mouseBindHardwareModes = true,
  lhcBindHardwareModes = false,
  separateDeviceCycles = false,
  preferLibraryMacros = false,
  enableConfigLinting = true,
  mousePositionCheck = false,
  resolutions = {1920, 1080},
  randomActionDeviation = 0,
  maxInheritanceDepth = 20,
  scaleCoordinates = false,
  docModeButtonLock = true,
  keyboardModeConfig = {},
  preferShorthand = false,
  globalScopeKeys = false, --Compile relevant
  abortOnLintError = true,
  stackAutoReverse = true,
  defaultModeTarget = nil, --Compile relevant
  mouseHistoryLimit = 100,
  keyboardButtonCount = 6,
  shiftSort = "standard",
  customStack = "append",
  randomKeyDeviation = 0,
  modeSort = "standard",
  shiftStack = "append",
  mouseButtonCount = 20, --Compile relevant
  keyboardModeCount = 0,
  audioModeConfig = {},
  modeStack = "append",
  keepNameOnLCD = true,
  enableLinting = true,
  multiClickTime = 200,
  keyboardShiftKey = 6,
  audioButtonCount = 1,
  showCompiled = true, --except this one
  externalConfigs=nil,
  defaultStacking = 1,
  pollFamily = "lhc",
  customNames = true,
  lhcModeConfig = {},
  singleType = false,
  mouseModeCount = 3, --Compile relevant
  appendNewLines = 1,
  lhcButtonCount = 1,
  audioModeCount = 0,
  defaultHold = 500,
  genericModes = {}, --Compile relevant
  logEvents = false,
  logMemory = false,
  cacheLinks = true,
  charsPerLine = 30,
  pollInterval = 10,
  mouseShiftKey = 6, --Compile relevant
  mouseInterval = 5,
  audioShiftKey = 0,
  outputLCD = true,
  externalDocs=nil,
  actionDelay = 10,
  displayLines = 6,
  defaultShift = 2,
  historyDepth = 2,
  startDisplay = 1,
  lhcModeCount = 1,
  customSort = {},
  hubMode = false,
  clearLog = true,
  clearLCD = true,
  lhcShiftKey = 0,
  defaultMode = 0, -- General Profile configuration
  persistLCD = -1,
  keyDelay = 10,
  extends = "", --Compile relevant
  logLevel = 0,
  defaultKeys = {
    m3 = {"/3", m = 0, g = 2},
    m4 = {"/4", m = 0, g = 2},
    m5 = {"/5", m = 0, g = 2}
  },
  rename = {
    m4 = "m8",
    m5 = "m7",
    m9 = "g1",
    m10 = "g2",
    m11 = "g3",
    m12 = "g4",
    m13 = "g5",
    m14 = "g6",
    m15 = "g7",
    m16 = "g8",
    m17 = "g9",
    m18 = "g10",
    m19 = "g11",
    m20 = "g12"
  }
}

local   loadfile, OutputLogMessage, xpcall, setmetatable,type,randomseed,match =
  loadfile, OutputLogMessage, xpcall, setmetatable,type,math.randomseed,string.match

---@alias ClassName '"MacroDefinition"'|'"KeyMacro"'|'"ProfileDefinition"'|'"MonitorDefinition"'|'"SimpleKeyMacro"'

---@class MainLibBase
local tl = {
  assign = {},
  key = {},
  keyStates = {roDown={},keysDown={},logiKeys={},lastKeysDown={},unRename={}},
  scriptStates = {
    locationIndicator = "Running on internal configs",
    exitingScript = false,
    currentButton = 0,
    version = "2.5b",
    namedTables = 0,
    docMode = false,
    keyCount = 0,
    modeUsed = 0,
    mainPos = 1,
    errors = {},
    mods = "",
    flags={}
  },
  stringPresets = {
    shortHands = {
      {"t", "type"},
      {"p", "play"},
      {"m", "mode"},
      {"l", "loop"},
      {"n", "name"},
      {"mk", "mkey"},
      {"g", "gshift"},
      {"u", "update"},
      {"cn", "cancel"},
      {"c", "consume"},
      {"kd", "keyDelay"},
      {"dir", "direction"},
      {"ad", "actionDelay"},
      {"rk","randomKeyDeviation"},
      {"ra","randomActionDeviation"}
    },
    internalProps = {"_scope", "pID", "_isCont", "doc", "_meta"},
    internalPropsName = {"_scope", "pID", "_isCont", "name", "doc", "_meta"},
    flexConfigNames = {
      "stackAutoReverse",
      "showCompiled",
      "customStack",
      "shiftStack",
      "customSort",
      "stackOrder",
      "singleType",
      "stackDepth",
      "modeStack",
      "shiftSort",
      "modeSort"
    },
    families = {"mouse", "keyboard", "audio", "lhc"},
    rawFuncTerms = {{"l", "link"}},
    funcMapper = {}
  },
  deviceState = {}---@type table<string,HardwareDefinition>
}

---@class MainLibObject:MainLibBase
---@field assign AssignmentTable
function tl:new(...)
  local o = {}
  self.__index = self---@private
  setmetatable(o, self)
  o:constructor(...)
  return o
end

randomseed(GetRunningTime())
local function _handleImportErrors(e, path)
  local errString = "could not load file from path '" .. path .. ", Error:\n  \"" .. e..'"'
  OutputLogMessage(errString.."\n")
  tl.scriptStates.errors[#tl.scriptStates.errors + 1] = errString
end

local fileCache = {}
function tl:loadFile(path,handler)
  local code, ret =xpcall(function()return loadfile(path)(self)end,function(err)(handler or _handleImportErrors)(err, path)end)if code then fileCache[path] = ret return ret end 
end
function tl:import(path,handler)
  local p = path:gsub("%.lua$",""):gsub("$",".lua")
  return fileCache[p] or self:loadFile(p,handler)
end

function tl:constructor(pathConfig)
  self.defaultConfig = defaultConfiguration
  self.paths = pathConfig
  self.totalMacros = 0
  self.macroImports={}
  self.classMap = {}
  for i = 1, #macroTerms do local el = macroTerms[i]
    self.classMap[el[2]] = {el[1],el[2]}
    self.classMap[el[3]] = {el[1],el[2]}
  end
  local lPath = self.paths.path .. "/src/libraries/"
  local cPath = self.paths.path .. "/src/classes/"
  local mPath = self.paths.path .. "/src/modules/"
  local sPath = self.paths.path .. "/configs/"
  ---@param name ClassName
  function tl:classImport(name)
    local isMacro = match(name,'Macro$')
    if isMacro and name ~= "GroupMacro" then self.macroImports[name]=true end
    return self:import(cPath..((isMacro and "macros/")or"")..name) 
  end
  self.baseClass = self:classImport("BaseClass")---@type BaseClass
  local function instance(path) return self:import(path):new() end
  self.helperUtils = instance(lPath .. "helperFunctions") ---@type UtilityModule
  -->>> Libraries from around the net ===============================================================================
  self.polling = instance(mPath .. "PollingTaskModule") ---@type PollingModule
  self.keys = instance(mPath .. "KeyOutputModule") ---@type KeyOutputModule
  self.utf8 = self:import(lPath .. "utf8") ---@type UnicodeFunctions
  self.helperUtils.pprint = self:import(lPath .. "inspect")
  -->>> code written by myself ===============================================================================
  self.mouseMonitorUtils = instance(mPath .. "MouseCoordinatesModule") ---@type MouseCoordinatesModule
  self.logitech = instance(mPath .. "LogitechInterfaceModule") ---@type LogitechInterfaceModule
  self.validator = instance(mPath .. "MacroValidatorModule") ---@type MacroValidatorModule
  self.eventHandler =instance(mPath .. "EventHandlerModule") ---@type EventHandlerModule
  self.coroutines = instance(mPath .. "CoroutineModule") ---@type CoroutineModule
  self.str =instance(mPath .. "StringUtilitiesModule") ---@type StringUtilitiesModule
  self.tbl = instance(mPath .. "TableUtilitiesModule") ---@type TableUtilitiesModule
  self.lint = instance(mPath .. "LintingModule") ---@type LintingModule
  self.paths = self.tbl:intersectSimple(defaultPaths,self.paths,true)
  loadfile(sPath .. self.paths.keyFile)(self)
  if #self.scriptStates.errors ~= 0 then 
    OnEvent = function()end
    for i = 1, #self.scriptStates.errors do OutputLogMessage(self.scriptStates.errors[i] .. "\n")end
  end
end

return tl