--Default values for the options specified in in the logitech bindings, as a fallback
local tl ={}
tl.options = ...
-- Path Configuration
tl.options = tl.options.options or tl.options
for k,v in pairs(tl) do if k ~= "options" then  tl.options[k] = v tl[k] = nil end end
tl.defaultOptions = {
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
  PollInterval = 10,
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
local empties={"lintErrors","profileBuffer","stateVars","TaskList","virtualDesktop","archivedLCD","state","unname",'macroStats',"downs","mouseHistory","toggled","stable","unstable","cList","assign","roDown","squ","dynamicTables","arn","lastKeysDown","extendList"}
local nulls = {"namedTables","currentBuffer","mouseCount","modeUsed","tabNum","maxMode","maxKeys","sKey","but","dir","pMod","lastModC","exitus","keyCount","currentSample","cachedString","paginatorState"}

for k,v in pairs(tl.defaultOptions) do 
  tl[k] = tl.options[k]
  if tl[k] == nil then tl[k] = v end 
end

for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
if tl.defaultModeTarget == "self" then  tl.defaultModeTarget = nil end
tl.setKeys = tl.options.setKeys
tl.options.setKeys = nil
tl.version = "2.2"
tl.modeRide = false;
tl.lPath = tl.path.."/libraries/"
tl.mPath = tl.path.."/modules/"
tl.findEx="Running on internal configs"
tl.press = false
tl.mods= ""
tl.macPlay = false
tl.docMode = false
tl.mainPos = 1
tl.macroStats.null={check={}}
tl.pprint = dofile(tl.lPath..'/inspect.lua')
loadfile(tl.path..'/configs/'..tl.keyFile)(tl)
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

tl.defaultFuncs={ -- tabs[def](cmd,mDir,mouse,virtu,fam,simfam,originator,pDir); tl.normKey(tg,dir,relmod,vir,bid)
  mt    = function(f,_,_,_,z,w) tl.togMode(f,w or tl.defaultModeTarget or z) end,
  c     = function(f,g,b,v,z,_,y) tl.agnostiCycle(f,g,v,y,z,b) end,
  s     = function(f,g,b,v,z,_,_,h) tl.quiKey(f,f.name or f.pID,g,h,b,v,z) end,
  h     = function(f,g,b,_,z) tl.stagger(f,g,z,b) end,
  n     = function(f,g,b,v,z) tl.normKey(f,g,0,v,f.pID,_,_,z,b) end,
  d     = function(f,g,b,v,z) tl.normKey(f,g,1,v,f.pID,_,_,z,b) end,
  dr    = function(f,g,b,v,z) tl.normKey(f,g,4,v,f.pID,_,_,z,b) end,
  u     = function(f,g,b,v,z) tl.normKey(f,g,2,v,f.pID,_,_,z,b) end,
  et    = function(f,g) tl.togMac(f,g) end,
  p     = function(f,g) tl.mouseMove(f,g) end,
  pr    = function() tl.put('Monitor '..tl._getMonitor(),'Coordinates '..GetMousePosition()) end,
  eh    = function(f) tl.togMac(f) end,
  vb    = function(f) tl.setVar(f) end
}

tl.upDownFuncs={
  b     = function(f,_,_,_,z,w) tl.backLighter(f,w or z) end,
  mn    = function(f,_,_,_,z,w) tl.tempMode(f,w or tl.defaultModeTarget or z) end,
  m     = function(f,_,_,_,z,w) tl.molect(f,w or tl.defaultModeTarget or z) end,
  t     = function(f,g,b,_,z) tl.timerKey(f,g,z,b) end,
  nt    = function(f,g,b,v,z) tl.normKey(f,g,3,v,f.pID,_,_,z,b) end,
  bf    = function(f,_,b,_,z)tl.addBuffer(f[1],z,b) end,
  hc    = function(f,g) tl.lcancel(f,g) end,
  dh    = function(f,g) tl.histoRase(f[1],g) end,
  e     = function(f) tl.PlayMac(f) end,
  w     = function(f) MoveMouseWheel(f) end,
  sa    = function(f) tl.multiAbort(f) end,
  fn    = function(f) tl.executor(f) end,
  cr    = function(f) tl.cycleReset(f) end,
  sp    = function(f) tl.tPause(f) end,
  sr    = function(f) tl.tRes(f) end,
  o     = function(f) tl.outputWrapper(f) end,
  ea    = function() AbortMacro() end,
  v     = function(f) tl.setVar(f) end,
  doc   = function() tl.docSwitch() end
}

tl.sequenceInheritor = {"gshift","mode","mkey","unlock"}
tl.upFuncs = {}
tl.macFuncs = {}

--->>> Libraries from around the net ===============================================================================
loadfile(tl.lPath.."helperFunctions.lua")(tl)
loadfile(tl.mPath.."pollingTaskModule.lua")(tl)
loadfile(tl.mPath.."keyOutputModule.lua")(tl)
--->>> code written by myself ===============================================================================
loadfile(tl.mPath.."logitechInterfaceModule.lua")(tl)
loadfile(tl.mPath.."mouseCoordinatesModule.lua")(tl)
loadfile(tl.mPath.."bindingStructureModule.lua")(tl)
loadfile(tl.mPath.."profileCompilerModule.lua")(tl)
loadfile(tl.mPath.."stringUtilitiesModule.lua")(tl)
loadfile(tl.mPath.."macroExecutionModule.lua")(tl)
loadfile(tl.mPath.."tableUtilitiesModule.lua")(tl)
loadfile(tl.mPath.."eventHandlerModule.lua")(tl)
loadfile(tl.mPath.."coroutineModule.lua")(tl)
loadfile(tl.mPath.."lintingModule.lua")(tl)

return tl