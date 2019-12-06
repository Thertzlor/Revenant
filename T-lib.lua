--Default values for the options specified in in the logitech bindings, as a fallback
---@class MainLibObject
local tl ={}
---@type OptionsCollection
tl.config = ...
tl.config = tl.config.config or tl.config
for k,v in pairs(tl) do if k ~= "config" then  tl.config[k] = v tl[k] = nil end end
---@class OptionsCollection
tl.defaultConfig = {
  profileName = "no_name", --Compile relevant
  path = "", --load relevant
  extPaths = {"ext_lua","ext_work"}, --load relevant
  childPaths = true, --load relevant
  fileLocation = 0, --load relevant
  keyFile = "T-lib_keySetup.lua",
  -- General Profile configuration
  defaultMode = 0,
  defaultShift = 2,
  genericModes = {},  --Compile relevant
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

  -- Hardware Configuration
  resolutions = {1920,1080},
  startDisplay = 1,
  scaleCoordinates = false,
  separateDeviceCycles = false,
  defaultModeTarget = nil, --Compile relevant
  logLevel = 0,

  mouseButtonCount = 20, --Compile relevant
  mouseShiftKey = 6, --Compile relevant
  mouseModeCount = 3, --Compile relevant
  mouseModeConfig = {"mode 1","mode 2","mode 3"}, --Compile relevant
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
  docFile = 0, --load relevant
  docPath = "", --load relevant
  docSuffix = "_doc", --load relevant
  docName = 0, --load relevant

  -- Flex Syntax Configuration (obviously all compile relevant)
  showCompiled = true, --except this one
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
  lockFlexCompilationSettings = true,

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
local empties={"funcMapper","lintErrors","logiKeys","profileBuffer","oldConfig","flags","taskList","virtualDesktop","state","unname","keysDown","toggled","stable","unstable","assign","roDown","squ","dynamicTables","lastKeysDown"}
local nulls = {"namedTables","currentBuffer","modeUsed","tabNum","maxMode","maxKeys","sKey","currentButton","dir","lastModC","exitingScript","keyCount"}
local falsies = {"macPlay","docMode","pressed"}
for k,v in pairs(tl.defaultConfig) do if tl.config[k] == nil then tl.config[k] = v end end
for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
for i=1,#falsies do tl[falsies[i]] = false end
if tl.config.defaultModeTarget == "self" then  tl.config.defaultModeTarget = nil end
tl.setKeys = tl.config.setKeys
tl.config.setKeys = nil
tl.version = "2.4b"
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
  m     = {name = "mode", macro = function(f,_,_,_,z,w,_,_,r) tl.modeWrapper(f,f[2],w or tl.config.defaultModeTarget or z,r) end},
  s     = {name = "sequence", macro = function(f,g,b,v,z,_,_,h) tl.quiKey(f,f.name or f.pID,g,h,b,v,z) end},
  dr    = {name = "wrapkey", macro = function(f,g,b,v,z) tl.normKey(f,g,4,v,f.pID,_,_,z,b) end},
  d     = {name = "keydown", macro = function(f,g,b,v,z) tl.normKey(f,g,1,v,f.pID,_,_,z,b) end},
  e     = {name = "playmacro", macro = function(f,g,_,_,_,_,_,_,r) tl.handleMacros(f,g,r) end},
  u     = {name = "keyup", macro = function(f,g,b,v,z) tl.normKey(f,g,2,v,f.pID,_,_,z,b) end},
  c     = {name = "cycle", macro = function(f,g,b,v,z,_,y) tl.agnostiCycle(f,g,v,y,z,b) end},
  n     = {name = "key", macro = function(f,g,b,v,z) tl.normKey(f,g,0,v,f.pID,_,_,z,b) end},
  h     = {name = "holdkey", macro = function(f,g,b,_,z) tl.stagger(f,g,z,b) end},
  p     = {name = "mousemove", macro = function(f,g) tl.mouseMove(f,g) end},
  ft    = {name = "toggleflag", macro = function(f) tl.setFlag(f) end},
  pr    = {name = "test", macro = function()  end}
}

tl.upDownFuncs={
  nt    = {name = "keytoggle", macro = function(f,g,b,v,z) tl.normKey(f,g,3,v,f.pID,_,_,z,b) end},
  b     = {name = "backlight", macro = function(f,_,_,_,z,w) tl.backLighter(f,w or z) end},
  t     = {name = "multiclick", macro = function(f,_,b,_,z) tl.timerKey(f,z,b) end},
  bf    = {name = "buffer", macro = function(f,_,b,_,z)tl.addBuffer(f[1],z,b) end},
  dh    = {name = "wiphehistory", macro = function(f) tl.histoRase(f[1]) end},
  w     = {name = "mousewheel", macro = function(f) MoveMouseWheel(f) end},
  hc    = {name = "holdcancel", macro = function(f,g) tl.lcancel(f,g) end},
  cr    = {name = "cyclereset", macro = function(f) tl.cycleReset(f) end},
  doc   = {name = "documentation", macro = function() tl.docSwitch() end},
  o     = {name = "log", macro = function(f) tl.outputWrapper(f) end},
  fn    = {name = "function", macro = function(f) tl.executor(f) end},
  sa    = {name = "abort", macro = function(f) tl.multiAbort(f) end},
  ea    = {name = "abortmacro", macro = function() AbortMacro() end},
  sp    = {name = "pause", macro = function(f) tl.tPause(f) end},
  f     = {name = "flag", macro = function(f) tl.setFlag(f) end},
  sr    = {name = "resume", macro = function(f) tl.tRes(f) end}
}

tl.rawFuncTerms = {{"l","link"}}
for k, v in pairs(tl.defaultFuncs) do tl.rawFuncTerms[#tl.rawFuncTerms+1] = {k,v.name} end
for k, v in pairs(tl.upDownFuncs) do tl.rawFuncTerms[#tl.rawFuncTerms+1] = {k,v.name} end
for _, v in pairs(tl.rawFuncTerms) do tl.funcMapper[v[2]] = v[1] end
for k, v in pairs(tl.rawFuncTerms) do tl.rawFuncTerms[k] = v[1] end

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