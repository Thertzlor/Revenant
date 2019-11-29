--Default values for the options specified in in the logitech bindings, as a fallback
---@class MainLibObject
local tl ={}
---@type OptionsCollection
tl.config = ...
tl.config = tl.config.config or tl.config
for k,v in pairs(tl) do if k ~= "config" then  tl.config[k] = v tl[k] = nil end end
---@class OptionsCollection
tl.defaultConfig = {
  profileName = "no_name",
  path = "",
  extPaths = {"ext_lua","ext_work"},
  childPaths = true,
  fileLocation = 0,
  keyFile = "T-lib_keySetup.lua",
  -- General Profile configuration
  defaultMode = 0,
  defaultShift = 2,
  genericModes = {},
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
  keyNamesAreMacroNames = true,
  globalScopeKeys = false,
  logEvents = false,
  logMemory = false,
  clearLog = true,
  extends = "",
  automaticTypeDetection = true,
  enableLinting = true,
  abortOnLintError = true,

  -- Hardware Configuration
  resolutions = {1920,1080},
  scaleCoordinates = false,
  separateDeviceCycles = false,
  defaultModeTarget = nil,
  logLevel = 0,

  mouseButtonCount = 20,
  mouseShiftKey = 6,
  mouseModeCount = 3,
  mouseModeConfig = {"mode 1","mode 2","mode 3"},
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

  -- Documentation Configuration
  docFile = 0,
  docPath = "",
  docSuffix = "_doc",
  docName = 0,

  -- Flex Syntax Configuration
  showCompiled = true,
  modeStack = "append",
  shiftStack = "append",
  customStack = "append",
  modeSort = "standard",
  shiftSort = "standard",
  customSort = {},
  stackOrder = {"custom","mode","shift"},
  stackAutoReverse = true,
  stackDepth = 1,
  singleType = 0,

  -- Profile Inheritance Configuration
  maxInheritanceDepth = 20,
  handleKeyConflicts = "append",
  handleOptionConflicts = "replaceDuplicates",
  handleDocumentationConflicts = "replaceDuplicates",
  handleLibraryConflicts = "replaceDuplicates",
  preferLibraryMacros = false,
  retainFlexCompilationSettings = true,

  defaultKeys={
    m3={"/3",m=0,g=2},
    m4={"/4",m=0,g=2},
    m5={"/5",m=0,g=2}
  },

  rename={
    m4="m8",
    m5="m7",
    m9="g1",
    m10="g2",
    m11="g3",
    m12="g4",
    m13="g5",
    m14="g6",
    m15="g7",
    m16="g8",
    m17="g9",
    m18="g10",
    m19="g11",
    m20="g12"
  },
  customProperties={}
}

local AbortMacro, MoveMouseWheel, dofile, loadfile, pairs = AbortMacro, MoveMouseWheel, dofile, loadfile, pairs
local empties={"lintErrors","logiKeys","profileBuffer","oldConfig","stateVars","taskList","virtualDesktop","state","unname","keysDown","toggled","stable","unstable","assign","roDown","squ","dynamicTables","lastKeysDown"}
local nulls = {"namedTables","currentBuffer","modeUsed","tabNum","maxMode","maxKeys","sKey","currentButton","dir","lastModC","exitingScript","keyCount"}
local falsies = {"macPlay","docMode","pressed"}
for k,v in pairs(tl.defaultConfig) do if tl.config[k] == nil then tl.config[k] = v end end
for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
for i=1,#falsies do tl[falsies[i]] = false end
if tl.config.defaultModeTarget == "self" then  tl.config.defaultModeTarget = nil end
tl.setKeys = tl.config.setKeys
tl.config.setKeys = nil
tl.version = "2.3"
local lPath = tl.config.path.."/libraries/"
local mpath = tl.config.path.."/modules/"
tl.locationIndicator="Running on internal configs"
tl.mods= ""
tl.mainPos = 1
---@type table<string,HardwareDefinition>
tl.state={}
---@type table<number,ProfileDefinition>
tl.macroStats = {}
---@type MacroStatContainer
tl.macroStats.null={check={}}
tl.pprint = dofile(lPath..'/inspect.lua')
---@type UnicodeFunctions
tl.utf8 = dofile(lPath..'/utf8.lua')
loadfile(tl.config.path..'/configs/'..tl.config.keyFile)(tl)
tl.families={"mouse","keyboard","audio","lhc"}
tl.unToken={m="Mouse",k="Keyboard",a="Audio",l="LHC"}
tl.unLogiToken={m="mouse",k="kb",a="audio",l="lhc"}

tl.shortHands={
  {"t","type"},
  {"g","gshift"},
  {"m","mode"},
  {"mk","mkey"},
  {"c","consume"},
  {"l","loop"},
  {"p","play"},
  {"dir","direction"},
  {"ad","actionDelay"},
  {"kd","keyDelay"},
  {"n","name"},
  {"u","update"}
}
tl.internalProps, tl.internalPropsName= {"_scope","pID","_isCont","doc"}, {"_scope","pID","_isCont","name","doc"}
tl.flexConfigNames={"showCompiled","modeStack","shiftStack","customStack","modeSort","shiftSort","customSort","stackOrder","stackAutoReverse","stackDepth" ,"singleType"}

tl.defaultFuncs={ -- tabs[def](cmd,mDir,mouse,virtu,fam,simfam,originator,pDir,dirMatch); tl.normKey(tg,dir,relmod,vir,bid)
  m     = function(f,_,_,_,z,w,_,_,r) tl.modeWrapper(f,f[2],w or tl.config.defaultModeTarget or z,r) end,
  s     = function(f,g,b,v,z,_,_,h) tl.quiKey(f,f.name or f.pID,g,h,b,v,z) end,
  dr    = function(f,g,b,v,z) tl.normKey(f,g,4,v,f.pID,_,_,z,b) end,
  n     = function(f,g,b,v,z) tl.normKey(f,g,0,v,f.pID,_,_,z,b) end,
  d     = function(f,g,b,v,z) tl.normKey(f,g,1,v,f.pID,_,_,z,b) end,
  u     = function(f,g,b,v,z) tl.normKey(f,g,2,v,f.pID,_,_,z,b) end,
  c     = function(f,g,b,v,z,_,y) tl.agnostiCycle(f,g,v,y,z,b) end,
  e     = function(f,g,_,_,_,_,_,_,r) tl.handleMacros(f,g,r) end,
  h     = function(f,g,b,_,z) tl.stagger(f,g,z,b) end,
  p     = function(f,g) tl.mouseMove(f,g) end,
  vb    = function(f) tl.setVar(f) end,
  pr    = function()  end
}

tl.upDownFuncs={
  nt    = function(f,g,b,v,z) tl.normKey(f,g,3,v,f.pID,_,_,z,b) end,
  b     = function(f,_,_,_,z,w) tl.backLighter(f,w or z) end,
  bf    = function(f,_,b,_,z)tl.addBuffer(f[1],z,b) end,
  t     = function(f,_,b,_,z) tl.timerKey(f,z,b) end,
  dh    = function(f) tl.histoRase(f[1]) end,
  o     = function(f) tl.outputWrapper(f) end,
  w     = function(f) MoveMouseWheel(f) end,
  hc    = function(f,g) tl.lcancel(f,g) end,
  sa    = function(f) tl.multiAbort(f) end,
  cr    = function(f) tl.cycleReset(f) end,
  fn    = function(f) tl.executor(f) end,
  doc   = function() tl.docSwitch() end,
  sp    = function(f) tl.tPause(f) end,
  v     = function(f) tl.setVar(f) end,
  ea    = function() AbortMacro() end,
  sr    = function(f) tl.tRes(f) end
}

tl.upFuncs = {}
tl.macFuncs = {}
math.randomseed(GetRunningTime())

--->>> Libraries from around the net ===============================================================================
loadfile(mpath.."pollingTaskModule.lua")(tl)
loadfile(lPath.."helperFunctions.lua")(tl)
loadfile(mpath.."keyOutputModule.lua")(tl)
--->>> code written by myself ===============================================================================
loadfile(mpath.."logitechInterfaceModule.lua")(tl)
loadfile(mpath.."mouseCoordinatesModule.lua")(tl)
loadfile(mpath.."bindingStructureModule.lua")(tl)
loadfile(mpath.."profileCompilerModule.lua")(tl)
loadfile(mpath.."stringUtilitiesModule.lua")(tl)
loadfile(mpath.."macroExecutionModule.lua")(tl)
loadfile(mpath.."tableUtilitiesModule.lua")(tl)
loadfile(mpath.."eventHandlerModule.lua")(tl)
loadfile(mpath.."coroutineModule.lua")(tl)
loadfile(mpath.."lintingModule.lua")(tl)

return tl