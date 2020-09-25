--Default values for the options specified in the logitech bindings, as a fallback

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
local tl = BaseClass:new();
tl.assign = {};
tl.keys = {}

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



---@type UtilityFunctions
---: Generic Helper Functions

local  dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable =
   dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable

---Storage for compiled macro functions across all Devices.

---@type table<string,HardwareDefinition>
tl.deviceState = {}


math.randomseed(GetRunningTime())

function tl:constructor(config)
  ---@type OptionsCollection
  self.config = config
  for k, v in pairs(defaultConfiguration) do if self.config[k] == nil then self.config[k] = v end end
  local lPath = self.config.path .. "/libraries/"
  local mpath = self.config.path .. "/modules/"
  if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end

  local function _handleImportErrors(e, path)
    --  ClearLog()
    local errString = "could not load file from path '" .. path .. "', Error: " .. e
    OutputLogMessage(errString)
      tl.scriptStates.errors[#tl.scriptStates.errors + 1] = errString
  end
  
  
   local function import(path)local code, ret =xpcall(function()return loadfile(path .. ".lua")(self, BaseClass)end,function(err)_handleImportErrors(err, path .. ".lua")end)if code then return ret end end

  self.helperUtils = import(lPath .. "helperFunctions"):new() ---@type UtilityModule
  --->>> Libraries from around the net ===============================================================================
  

  self.polling = import(mpath .. "pollingTaskModule"):new() ---@type PollingModule
  self.keys = import(mpath .. "keyOutputModule"):new() ---@type KeyOutputModule
  self.utf8 = import(lPath .. "utf8") ---@type UnicodeFunctions
  self.helperUtils.pprint = import(lPath .. "inspect")
  --->>> code written by myself ===============================================================================

  self.mouseMonitorUtils = import(mpath .. "mouseCoordinatesModule"):new() ---@type MouseCoordinatesModule
  self.profileCompiler = import(mpath .. "profileCompilerModule"):new() ---@type ProfileCompilerModule
  self.logitech = import(mpath .. "logitechInterfaceModule"):new() ---@type LogitechInterfaceModule
  self.bindings = import(mpath .. "bindingStructureModule"):new() ---@type BindingStructureModule
  self.eventHandler =import(mpath .. "eventHandlerModule"):new() ---@type EventHandlerModule
  self.macros = import(mpath .. "macroExecutionModule"):new() ---@type MacroExecutionModule
  self.str =import(mpath .. "stringUtilitiesModule"):new() ---@type StringUtilitiesModule
  self.tbl = import(mpath .. "tableUtilitiesModule"):new() ---@type TableUtilitiesModule
  self.coroutines = import(mpath .. "coroutineModule"):new() ---@type CoroutineModule
  self.lint = import(mpath .. "lintingModule"):new() ---@type LintingModule
  loadfile(self.config.path .. "/configs/" .. self.config.keyFile)(self)
  self.macroIndex = self.helperUtils.newIndexTable()

  self.wrapperFunctions = {
    defaultFuncs = {
      -- tabs[def](cmd,mDir,mouse,virtu,fam,simfam,originator,pDir,dirMatch); self.normKey(tg,dir,relmod,vir,bid)
      m = {name = "mode",macro = function(f, g, b, v, z, w, y, h, r)self.logitech:modeWrapper(f, f[2], w or self.config.defaultModeTarget or z, r)end},
      s = {name = "sequence",macro = function(f, g, b, v, z, w, y, h)self.macros:keySequence(f, f.name or f.pID, g, h, b, v, z)end},
      kw = {name = "wrapkey",macro = function(f, g, b, v, z)self.macros:simpleKey(f, g, 4, v, f.pID, _, _, z, b)end},
      d = {name = "keydown",macro = function(f, g, b, v, z)self.macros:simpleKey(f, g, 1, v, f.pID, _, _, z, b)end},
      e = {name = "playmacro",macro = function(f, g, b, v, z, w, y, h, r)self.logitech:externalMacroWrapper(f, g, r)end},
      u = {name = "keyup",macro = function(f, g, b, v, z)self.macros:simpleKey(f, g, 2, v, f.pID, _, _, z, b) end },
      c = { name = "cycle", macro = function(f, g, b, v, z, w, y) self.macros:keyCycle(f, g, v, y, z, b) end},
      k = {name = "key", macro = function(f, g, b, v, z) self.macros:simpleKey(f, g, 0, v, f.pID, _, _, z, b) end},
      h = {name = "holdkey",macro = function(f, g, b, v, z)self.macros:staggeredKey(f, g, z, b)end},
      p = {name = "mousemove",macro = function(f, g)self.mouseMonitorUtils:mouseMove(f, g)end},
      ft = {name = "toggleflag", macro = function(f)self.macros:setFlag(f)end},
      pr = {name = "test",macro = function()end}
    },
    upDownFuncs = {
      kt = {name = "keytoggle",macro = function(f, g, b, v, z)self.macros:simpleKey(f[1], g, 3, v, f.pID, _, _, z, b)end},
      b = {name = "backlight",macro = function(f, g, b, v, z, w)self.logitech:backLightControl(f, w or z)end},
      t = {name = "multiclick",macro = function(f, g, b, v, z)self.macros:timerKey(f, z, b)end},
      kb = {name = "bufferkey",macro = function(f, g, b, v, z)self.str:addStringBuffer(f[1], z, b)end},
      dh = {name = "wiphehistory",macro = function(f)self.macros:clearHistory(f[1])end},
      w = {name = "mousewheel",macro = function(f)MoveMouseWheel(f)end},
      hc = {name = "holdcancel",macro = function(f, g)self.macros:staggerCancel(f, g)end},
      cc = {name = "cyclecontrol",macro = function(f, g, b, v, z)self.macros:cycleControl(f[1],f[2],f[3],z)end},
      doc = {name = "documentation",macro = function()self.macros:toggleDocs()end},
      o = {name = "log",macro = function(f)self.macros:outputWrapper(f)end},
      fn = {name = "function",macro = function(f)self.macros:executeFunction(f)end},
      sc = {name = "sequencecontrol",macro = function(f)self.macros:sequenceControl(f[1],f[2])end},
      f = {name = "flag",macro = function(f)self.macros:setFlag(f)end},
      ms = {name = "monitorchange",macro = function(f)self.mouseMonitorUtils.switchMonitor(f)end},
      sr = {name = "resume",macro = function(f)self.coroutines:tRes(f)end}
    }
  }

  for k, v in pairs(self.wrapperFunctions.defaultFuncs) do self.stringPresets.rawFuncTerms[#self.stringPresets.rawFuncTerms + 1] = {k, v.name}end
  for k, v in pairs(self.wrapperFunctions.upDownFuncs) do self.stringPresets.rawFuncTerms[#self.stringPresets.rawFuncTerms + 1] = {k, v.name}end
  for _, v in pairs(self.stringPresets.rawFuncTerms) do self.stringPresets.funcMapper[v[2]] = v[1]end
  for k, v in pairs(self.stringPresets.rawFuncTerms) do self.stringPresets.rawFuncTerms[k] = v[1]end

  if #self.scriptStates.errors ~= 0 then 
    OnEvent = function()end
    for i = 1, #self.scriptStates.errors do OutputLogMessage(self.scriptStates.errors[i] .. "\n")end
  end



end


return tl