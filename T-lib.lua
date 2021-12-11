
local defaultPaths = {
  profileName = "no_name", --Compile relevant
  path = "", --load relevant
  extPaths = {"profiles/ext_lua", "profiles/ext_work"}, --load relevant
  childPaths = true, --load relevant
  fileLocation = 0, --load relevant
  defaultDocPath = {path = "", prefix = "", suffix = "_doc", name = ""},
  defaultConfigPath = {path = "conf", prefix = "", suffix = "_config", name = ""},
  keyFile = "T-lib_keySetup.lua"
}

local macroTerms = {
  {"KeyMacro","key","k"},
  {"KeyMacro","keyup","u"},
  {"KeyMacro","keydown","d"},
  {"GroupMacro","group","g"},
  {"KeyMacro","wrapkey","kw"},
  {"KeyMacro","keytoggle","kt"},
  {"InstanceMacro","instance","i"},
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
  handleOptionConflicts = "replaceDuplicates",
  stackOrder = {"custom", "mode", "shift"},
  keyboardBindHardwareModes = true,
  mouseBindHardwareModes = true,
  lhcBindHardwareModes = false,
  separateDeviceCycles = false,
  mousePositionCheck = false,
  restrictToMainScreen=false,
  enableConfigLinting = true,
  resolutions = {1920, 1080},
  maxInheritanceDepth = 20,
  scaleCoordinates = false,
  docModeButtonLock = true,
  keyboardModeConfig = {},
  preferShorthand = false,
  abortOnLintError = true,
  stackAutoReverse = true,
  defaultModeTarget = nil, --Compile relevant
  mouseHistoryLimit = 100,
  keyboardButtonCount = 6,
  primaryButtons = false,
  shiftSort = "standard",
  customStack = "append",
  modeSort = "standard",
  shiftStack = "append",
  mouseButtonCount = 20, --Compile relevant
  keyboardModeCount = 0,
  modeStack = "append",
  keepNameOnLCD = true,
  enableLinting = true,
  multiClickTime = 200,
  keyboardShiftKey = 6,
  showCompiled = true, --except this one
  externalConfigs=nil,
  defaultStacking = 1,
  actionVariance = 0,
  pollFamily = "lhc",
  lhcModeConfig = {},
  mouseModeCount = 3, --Compile relevant
  appendNewLines = 1,
  customNames = true,
  lhcButtonCount = 1,
  defaultHold = 500,
  genericModes = {}, --Compile relevant
  logEvents = false,
  logMemory = false,
  charsPerLine = 30,
  pollInterval = 10,
  mouseShiftKey = 6, --Compile relevant
  mouseInterval = 5,
  outputLCD = true,
  externalDocs=nil,
  actionDelay = 10,
  displayLines = 6,
  defaultShift = 2, --compile Relevant
  historyDepth = 2,
  lhcModeCount = 1,
  keyVariance = 0,
  customSort = {},
  hubMode = false,
  clearLog = true,
  clearLCD = true,
  lhcShiftKey = 0,
  defaultMode = 0, -- General Profile configuration
  persistLCD = -1,
  logBounce=true,
  keyDelay = 10,
  extends = "", --Compile relevant
  logLevel = 0,
  defaultKeys = {
    m1 = {"/1", m = 0, g = 2},
    m2 = {"/2", m = 0, g = 2},
    m3 = {"/3", m = 0, g = 2},
    m4 = {"/4", m = 0, g = 2},
    m5 = {"/5", m = 0, g = 2}
  },
  debouncerSettings = {
    mouse={
      {1,30,'up'},
      {2,30,'up'}
    }
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

local loadfile, OutputLogMessage, xpcall, setmetatable,type,randomseed,match,error,concat,ClearLCD,OutputLCDMessage,ClearLog, pairs =
  loadfile, OutputLogMessage, xpcall, setmetatable,type,math.randomseed,string.match,error,table.concat,ClearLCD,OutputLCDMessage,ClearLog, pairs
---@alias ClassName "MacroDefinition"|"KeyMacro"|'"ProfileDefinition"'|'"MonitorDefinition"'|'"SimpleKeyMacro"'

---@class MainLibBase
local tl = {
  keyStates = {roDown={},keysDown={},logiKeys={},lastKeysDown={},unRename={}},
  scriptStates = {
    locationIndicator = "Running on internal configs",
    exitingScript = false,
    currentButton = 0,
    version = "2.5b",
    docMode = false,
    warnings = {},
    keyCount = 0,
    modeUsed = 0,
    mainPos = 1,
    errors = {},
    mods = "",
    flags={}
  },
  stringPresets = {
    internalPropsName = {"_scope", "pID", "_isCont", "name", "doc", "_meta"},
    internalProps = {"_scope", "pID", "_isCont", "doc", "_meta"},
    determinants= {"gshift","mode","mkey","condition","area"},
    families = {"mouse", "keyboard", "lhc"},
    shortMapper={},
    optionDefaults = {
      mode="defaultMode",
      gshift="defaultShift"
    },
    shortHands = {
      t= "type",
      m= "mode",
      n= "name",
      mk= "mkey",
      g= "gshift",
      b= "blocking",
      c= "condition",
      kd= "keyDelay",
      dir= "direction",
      kv= "keyVariance"
    },
    flexConfigNames = {
      "stackAutoReverse",
      "showCompiled",
      "customStack",
      "shiftStack",
      "customSort",
      "stackOrder",
      "stackDepth",
      "modeStack",
      "shiftSort",
      "modeSort"
    }
  }
}

---@class MainLibObject:MainLibBase
---@private
function tl:new(...)
  local o = {}---@type any
  self.__index = self---@private
  setmetatable(o, self)
  o:constructor(...)
  return o
end

local function _handleImportErrors(e, path)
  tl.scriptStates.errors[#tl.scriptStates.errors + 1] = "could not load file from path '" .. path .. ", Error:\n  \"" .. e..'"'
end

local fileCache = {}
function tl:loadFile(path,handler)
  local code, ret =xpcall(function()return(loadfile(path) or error("No File/Syntax Error",2))(self)end,function(err)(handler or _handleImportErrors)(err, path)end)if code then fileCache[path] = ret return ret end
end
function tl:import(path,handler)
  local p = path:gsub("%.lua$",""):gsub("$",".lua")
  return fileCache[p] or self:loadFile(p,handler)
end

function tl:crash(msg)
  OnEvent = function()end
  ClearLCD()
  OutputLCDMessage("T-Lib ERROR\ncheck scripting console.",-1)
  OutputLCDMessage("",-1)
  local test,res,errs = {},{},self.scriptStates.errors
  for i = 1, #errs do local err = errs[i] if not test[err] then res[#res+1] = err end test[err]=true end
  error(((msg and msg.."\n") or "")..concat(res,"\n"),10)
end

function tl:classImport(name)
  local isMacro = match(name,'Macro$')
  if isMacro and name ~= "GroupMacro" then self.macroImports[name]=true end
  return self:import(self.paths.path .. "/src/classes/"..((isMacro and "macros/")or"")..name)
end

---@private
function tl:constructor(pathConfig)
  self.defaultConfig = defaultConfiguration
  self.paths = pathConfig
  self.macroImports={}
  self.classMap = {}
  for i = 1, #macroTerms do local el = macroTerms[i]
    self.classMap[el[2]] = {el[1],el[2]}
    self.classMap[el[3]] = {el[1],el[2]}
  end
  for k,v in pairs(self.stringPresets.shortHands) do self.stringPresets.shortMapper[#self.stringPresets.shortMapper+1]= {k,v}  end
  local lPath = self.paths.path .. "/src/libraries/"
  local mPath = self.paths.path .. "/src/modules/"
  local sPath = self.paths.path .. "/configs/"
  self.baseClass = self:classImport("BaseClass")---@type BaseClass
  local function instance(path) return (self:import(path) or {new=function()end}):new() end
  self.helperUtils = instance(lPath .. "helperFunctions") ---@type UtilityModule
  -->>> Libraries from around the net ===============================================================================
  self.polling = instance(mPath .. "PollingTaskModule") ---@type PollingModule
  self.keys = instance(mPath .. "KeyOutputModule") ---@type KeyOutputModule
  self.utf8 = self:import(lPath .. "utf8") ---@type UnicodeFunctions
  self.helperUtils.pprint = self:import(lPath .. "inspect")
  -->>> code written by myself ===============================================================================
  self.mouseMonitorUtils = instance(mPath .. "MouseCoordinatesModule") ---@type MouseCoordinatesModule
  self.logitech = instance(mPath .. "LogitechInterfaceModule") ---@type LogitechInterfaceModule
  self.lcd = instance(mPath .. "DisplayStateModule") ---@type DisplayStateModule
  self.validator = instance(mPath .. "MacroValidatorModule") ---@type MacroValidatorModule
  self.eventHandler =instance(mPath .. "EventHandlerModule") ---@type EventHandlerModule
  self.coroutines = instance(mPath .. "CoroutineModule") ---@type CoroutineModule
  self.str =instance(mPath .. "StringUtilitiesModule") ---@type StringUtilitiesModule
  self.tbl = instance(mPath .. "TableUtilitiesModule") ---@type TableUtilitiesModule
  self.lint = instance(mPath .. "LintingModule") ---@type LintingModule
  self.debouncer = instance(mPath .. "DebounceModule") ---@type DebounceModule
  self.paths = self.tbl:intersectSimple(defaultPaths,self.paths,true)
  loadfile(sPath .. self.paths.keyFile)(self)
  if #self.scriptStates.errors ~= 0 then self:crash() end
end

return tl