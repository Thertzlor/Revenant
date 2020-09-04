--Default values for the options specified in the logitech bindings, as a fallback
---@class OptionsCollection
local defaultConfiguration = {
  profileName = "no_name", --Compile relevant
  path = "", --load relevant
  extPaths = {"ext_lua", "ext_work"}, --load relevant
  childPaths = true, --load relevant
  fileLocation = 0, --load relevant
  -- additional files
  docFile = {path = "", prefix = "", suffix = "_doc", name = ""},
  configFile = {path = "", prefix = "", suffix = "_config", name = ""},
  keyFile = "T-lib_keySetup.lua",
  -- General Profile configuration
  defaultMode = 0,
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
  historyDepth = 2,
  mouseInterval = 5,
  mouseHistoryLimit = 100,
  keyNamesAreMacroNames = true, --Compile relevant
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

---@class MainLibObject
---@field assign AssignmentTable
local tl = {
  assign={}
}

---Dynamic button states, currently pressed, key history, etc.
tl.keyStates = {
  roDown={},
  keysDown={},
  logiKeys={},
  lastKeysDown={},
  unRename={}
}
---General statistics about script and runtime
tl.scriptStates = {
  version = "2.4b",
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
}

tl.stringPresets = {
    shortHands = {
        {"t", "type"},
        {"g", "gshift"},
        {"m", "mode"},
        {"mk", "mkey"},
        {"c", "consume"},
        {"l", "loop"},
        {"p", "play"},
        {"dir", "direction"},
        {"ad", "actionDelay"},
        {"kd", "keyDelay"},
        {"cn", "cancel"},
        {"n", "name"},
        {"u", "update"}
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
}

tl.wrapperFunctions = {
  defaultFuncs = {
    -- tabs[def](cmd,mDir,mouse,virtu,fam,simfam,originator,pDir,dirMatch); tl.normKey(tg,dir,relmod,vir,bid)
    m = {name = "mode",macro = function(f, g, b, v, z, w, y, h, r)tl.logitech:modeWrapper(f, f[2], w or tl.config.defaultModeTarget or z, r)end},
    s = {name = "sequence",macro = function(f, g, b, v, z, w, y, h)tl.macros:keySequence(f, f.name or f.pID, g, h, b, v, z)end},
    kw = {name = "wrapkey",macro = function(f, g, b, v, z)tl.macros:simpleKey(f, g, 4, v, f.pID, _, _, z, b)end},
    d = {name = "keydown",macro = function(f, g, b, v, z)tl.macros:simpleKey(f, g, 1, v, f.pID, _, _, z, b)end},
    e = {name = "playmacro",macro = function(f, g, b, v, z, w, y, h, r)tl.logitech:externalMacroWrapper(f, g, r)end},
    u = {name = "keyup",macro = function(f, g, b, v, z)tl.macros:simpleKey(f, g, 2, v, f.pID, _, _, z, b) end },
    c = { name = "cycle", macro = function(f, g, b, v, z, w, y) tl.macros:keyCycle(f, g, v, y, z, b) end},
    k = {name = "key", macro = function(f, g, b, v, z) tl.macros:simpleKey(f, g, 0, v, f.pID, _, _, z, b) end},
    h = {name = "holdkey",macro = function(f, g, b, v, z)tl.macros:staggeredKey(f, g, z, b)end},
    p = {name = "mousemove",macro = function(f, g)tl.mouseMonitorUtils:mouseMove(f, g)end},
    ft = {name = "toggleflag", macro = function(f)tl.macros:setFlag(f)end},
    pr = {name = "test",macro = function()end}
  },
  upDownFuncs = {
    kt = {name = "keytoggle",macro = function(f, g, b, v, z)tl.macros:simpleKey(f[1], g, 3, v, f.pID, _, _, z, b)end},
    b = {name = "backlight",macro = function(f, g, b, v, z, w)tl.logitech:backLightControl(f, w or z)end},
    t = {name = "multiclick",macro = function(f, g, b, v, z)tl.macros:timerKey(f, z, b)end},
    kb = {name = "bufferkey",macro = function(f, g, b, v, z)tl.str:addStringBuffer(f[1], z, b)end},
    dh = {name = "wiphehistory",macro = function(f)tl.macros:clearHistory(f[1])end},
    w = {name = "mousewheel",macro = function(f)MoveMouseWheel(f)end},
    hc = {name = "holdcancel",macro = function(f, g)tl.macros:staggerCancel(f, g)end},
    cc = {name = "cyclecontrol",macro = function(f, g, b, v, z)tl.macros:cycleControl(f[1],f[2],f[3],z)end},
    doc = {name = "documentation",macro = function()tl.macros:toggleDocs()end},
    o = {name = "log",macro = function(f)tl.macros:outputWrapper(f)end},
    fn = {name = "function",macro = function(f)tl.macros:executeFunction(f)end},
    sc = {name = "sequencecontrol",macro = function(f)tl.macros:sequenceControl(f[1],f[2])end},
    f = {name = "flag",macro = function(f)tl.macros:setFlag(f)end},
    ms = {name = "monitorchange",macro = function(f)tl.mouseMonitorUtils.switchMonitor(f)end},
    sr = {name = "resume",macro = function(f)tl.coroutines:tRes(f)end}
  }
}
---@type OptionsCollection
---: your mom.
tl.config = ...

---@type UtilityFunctions
---: Generic Helper Functions

local  dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable =
   dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable

local function _handleImportErrors(e, path)
  --  ClearLog()
  local errString = "could not load file from path '" .. path .. "', Error: " .. e
  OutputLogMessage(errString)
    tl.scriptStates.errors[#tl.scriptStates.errors + 1] = errString
end

---@class BaseClass
local BaseClass = {}
function BaseClass:constructor(...)end
function BaseClass:new(...)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:constructor(...)
    return o
end

local function _import(path)local code, ret =xpcall(function()return loadfile(path .. ".lua")(tl, BaseClass)end,function(err)_handleImportErrors(err, path .. ".lua")end)if code then return ret end end

for k, v in pairs(defaultConfiguration) do if tl.config[k] == nil then tl.config[k] = v end end
local lPath = tl.config.path .. "/libraries/"
local mpath = tl.config.path .. "/modules/"
if tl.config.defaultModeTarget == "self" then tl.config.defaultModeTarget = nil end
tl.helperUtils = _import(lPath .. "helperFunctions"):new() ---@type UtilityModule
---Storage for compiled macro functions across all Devices.
tl.macroIndex = tl.helperUtils.newIndexTable()

---@type table<string,HardwareDefinition>
tl.deviceState = {}


for k, v in pairs(tl.wrapperFunctions.defaultFuncs) do tl.stringPresets.rawFuncTerms[#tl.stringPresets.rawFuncTerms + 1] = {k, v.name}end
for k, v in pairs(tl.wrapperFunctions.upDownFuncs) do tl.stringPresets.rawFuncTerms[#tl.stringPresets.rawFuncTerms + 1] = {k, v.name}end
for _, v in pairs(tl.stringPresets.rawFuncTerms) do tl.stringPresets.funcMapper[v[2]] = v[1]end
for k, v in pairs(tl.stringPresets.rawFuncTerms) do tl.stringPresets.rawFuncTerms[k] = v[1]end

--->>> Libraries from around the net ===============================================================================

tl.polling = _import(mpath .. "pollingTaskModule"):new() ---@type PollingModule
tl.keys = _import(mpath .. "keyOutputModule"):new() ---@type KeyOutputModule
tl.utf8 = _import(lPath .. "utf8") ---@type UnicodeFunctions
tl.helperUtils.pprint = _import(lPath .. "inspect")

--->>> code written by myself ===============================================================================

tl.mouseMonitorUtils = _import(mpath .. "mouseCoordinatesModule"):new() ---@type MouseCoordinatesModule
tl.profileCompiler = _import(mpath .. "profileCompilerModule"):new() ---@type ProfileCompilerModule
tl.logitech = _import(mpath .. "logitechInterfaceModule"):new() ---@type LogitechInterfaceModule
tl.bindings = _import(mpath .. "bindingStructureModule"):new() ---@type BindingStructureModule
tl.eventHandler =_import(mpath .. "eventHandlerModule"):new() ---@type EventHandlerModule
tl.macros = _import(mpath .. "macroExecutionModule"):new() ---@type MacroExecutionModule
tl.str =_import(mpath .. "stringUtilitiesModule"):new() ---@type StringUtilitiesModule
tl.tbl = _import(mpath .. "tableUtilitiesModule"):new() ---@type TableUtilitiesModule
tl.coroutines = _import(mpath .. "coroutineModule"):new() ---@type CoroutineModule
tl.lint = _import(mpath .. "lintingModule"):new() ---@type LintingModule

loadfile(tl.config.path .. "/configs/" .. tl.config.keyFile)(tl)
math.randomseed(GetRunningTime())
if #tl.scriptStates.errors ~= 0 then 
  OnEvent = function()end
  for i = 1, #tl.scriptStates.errors do OutputLogMessage(tl.scriptStates.errors[i] .. "\n")end
end
