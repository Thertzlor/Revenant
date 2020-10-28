
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
  profileName = "no_name", --Compile relevant
  path = "", --load relevant
  extPaths = {"ext_lua", "ext_work"}, --load relevant
  childPaths = true, --load relevant
  fileLocation = 0, --load relevant
  -- additional files
  defaultDocPath = {path = "", prefix = "", suffix = "_doc", name = ""},
  defaultConfigPath = {path = "", prefix = "", suffix = "_config", name = ""}, 
  defaultMode = 0, -- General Profile configuration
  defaultShift = 2,
  genericModes = {}, --Compile relevant
  customNames = true,
  actionDelay = 10,
  keyDelay = 10,
  defaultHold = 500,
  multiClickTime = 200,
  pollInterval = 10,
  pollFamily = "lhc",
  randomActionDeviation = 0,
  randomKeyDeviation = 0,
  defaultStacking = 1,
  preferShorthand = false,
  cacheLinks = true,
  externalConfigs=nil,
  externalDocs=nil,
  historyDepth = 2,
  mouseInterval = 5,
  mouseHistoryLimit = 100,
  globalScopeKeys = false, --Compile relevant
  logEvents = false,
  logMemory = false,
  clearLog = true,
  extends = "", --Compile relevant
  automaticTypeDetection = true,
  enableLinting = true,
  abortOnLintError = true,
  enableConfigLinting = true,
  hubMode = false,
  -- Hardware Configuration
  resolutions = {1920, 1080},
  startDisplay = 1,
  scaleCoordinates = false,
  separateDeviceCycles = false,
  defaultModeTarget = nil, --Compile relevant
  logLevel = 0,
  mouseButtonCount = 20, --Compile relevant
  mouseShiftKey = 6, --Compile relevant
  mouseModeCount = 3, --Compile relevant
  mouseModeConfig = {"mode 1", "mode 2", "mode 3"}, --Compile relevant
  mouseBindHardwareModes = true,
  mousePositionCheck = false,
  keyboardButtonCount = 6,
  keyboardShiftKey = 6,
  keyboardModeCount = 0,
  keyboardModeConfig = {},
  keyboardBindHardwareModes = true,
  audioButtonCount = 1,
  audioShiftKey = 0,
  audioModeCount = 0,
  audioModeConfig = {},
  audioBindHardwareModes = false,
  lhcButtonCount = 1,
  lhcShiftKey = 0,
  lhcModeCount = 1,
  lhcModeConfig = {},
  lhcBindHardwareModes = false,
  --LCD Configuration
  outputLCD = true,
  clearLCD = true,
  persistLCD = -1,
  keepNameOnLCD = true,
  appendNewLines = 1,
  docModeButtonLock = true,
  charsPerLine = 30,
  displayLines = 6,
  -- Flex Syntax Configuration (obviously all compile relevant)
  showCompiled = true, --except this one
  modeStack = "append",
  shiftStack = "append",
  customStack = "append",
  modeSort = "standard",
  shiftSort = "standard",
  customSort = {},
  stackOrder = {"custom", "mode", "shift"},
  stackAutoReverse = true,
  singleType = false,
  -- Profile Inheritance Configuration
  maxInheritanceDepth = 20,
  handleKeyConflicts = "append",
  handleOptionConflicts = "replaceDuplicates",
  handleDocumentationConflicts = "replaceDuplicates",
  handleLibraryConflicts = "replaceDuplicates",
  preferLibraryMacros = false,
  lockFlexCompilationSettings = true,
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
  },
  customProperties = {}
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
    version = "2.5b",
    locationIndicator = "Running on internal configs",
    mods = "",
    flags={},
    exitingScript = false,
    currentButton = 0,
    modeUsed = 0,
    keyCount = 0,
    namedTables = 0,
    mainPos = 1,
    docMode = false,
    errors = {}
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
        "showCompiled",
        "modeStack",
        "shiftStack",
        "customStack",
        "modeSort",
        "shiftSort",
        "customSort",
        "stackOrder",
        "stackAutoReverse",
        "stackDepth",
        "singleType"
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
  self.macroImports={}
  self.paths = pathConfig
  self.defaultConfig = defaultConfiguration
  self.totalMacros = 0
  self.classMap = {}
  for i = 1, #macroTerms do local el = macroTerms[i]
    self.classMap[el[2]] = {el[1],el[2]}
    self.classMap[el[3]] = {el[1],el[2]}
  end
  local lPath = self.paths.path .. "/src/libraries/"
  local cPath = self.paths.path .. "/src/classes/"
  local mPath = self.paths.path .. "/src/modules/"
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
  loadfile(self.paths.path .. "/configs/" .. self.paths.keyFile)(self)
  self.paths = self.tbl:intersectSimple(defaultPaths,self.paths,true)
  if #self.scriptStates.errors ~= 0 then 
    OnEvent = function()end
    for i = 1, #self.scriptStates.errors do OutputLogMessage(self.scriptStates.errors[i] .. "\n")end
  end
end

return tl