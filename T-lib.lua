--Default values for the options specified in in the logitech bindings, as a fallback
local tl ={}
tl.options = ...
-- Path Configuration
tl.options = tl.options.options or tl.options
for k,v in pairs(tl) do if k ~= "options" then  tl.options[k] = v tl[k] = nil end end
tl.defaultOptions = {
  profileName =  "no_name",
  path =  "",
  extPaths =  {"ext_lua","ext_work"},
  childPaths =  1,
  fileLocation =  0,
  keyFile =  "T-lib_keySetup.lua",

  -- General Profile configuration
  defaultMode =  0,
  defaultShift =  2,
  genericModes =  {},
  customNames =  1,
  actionDelay =  10,
  keyDelay =  10,
  defaultHold =  500,
  multiClickTime =  200,
  PollInterval =  10,
  randomActionDeviation =  0,
  randomKeyDeviation =  0,
  defaultStacking =  1,
  preferShorthand =  0,
  cacheLinks =  1,
  historyDepth =  2,
  mouseInterval =  5,
  mouseHistoryLimit =  100,
  logEvents =  0,
  logMemory =  0,
  extends =  "",

  -- Hardware Configuration
  resolutions =  {1920,1080},
  scaleCoordinates =  0,
  separateDeviceCycles =  0,
  defaultModeTarget =  nil,
  logLevel =  0,

  mouseButtonCount =  20,
  mouseShiftKey =  6,
  mouseModeCount =  3,
  mouseModeConfig =  {"mode 1","mode 2","mode 3"},
  mouseBindHardwareModes =  1,
  mousePositionCheck =  0,

  keyboardButtonCount =  6,
  keyboardShiftKey =  6,
  keyboardModeCount =  0,
  keyboardModeConfig =  {},
  keyboardBindHardwareModes =  1,

  audioButtonCount =  1,
  audioShiftKey =  0,
  audioModeCount =  0,
  audioModeConfig =  {},
  audioBindHardwareModes =  0,

  lhcButtonCount =  1,
  lhcShiftKey =  0,
  lhcModeCount =  1,
  lhcModeConfig =  {},
  lhcBindHardwareModes =  0,

  --LCD Configuration
  outputLCD =  1,
  clearLCD =  1,
  persistLCD =  -1,
  keepNameOnLCD =  1,
  appendNewLines =  1,
  docModeButtonLock =  1,
  charsPerLine =  30,
  displayLines =  6,

  -- Documentation Configuration
  docFile =  0,
  docPath =  "",
  docSuffix =  "_doc",
  docName =  0,

  -- Flex Syntax Configuration
  showCompiled =  1,
  modeStack = "append",
  shiftStack = "append",
  customStack = "append",
  modeSort = "standard",
  shiftSort = "standard",
  customSort = {},
  stackOrder = {"custom","mode","shift"},
  stackAutoReverse =  1,
  stackDepth =  1,
  singleType =  0,

  -- Profile Inheritance Configuration
  inheritanceMode =  'replace',  -- Options: replace, append, prepend, ignore
  maxInheritanceDepth =  0,

  defaultKeys={
    m3={"/3",m=0,s=0},
    m4={"/4",m=0,s=0},
    m5={"/5",m=0,s=0}
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
  }
}

local AbortMacro, MoveMouseWheel, dofile, loadfile, pairs = AbortMacro, MoveMouseWheel, dofile, loadfile, pairs
local empties={"profileBuffer","stateVars","TaskList","virtualDesktop","archivedLCD","state","unname",'macroStats',"downs","mouseHistory","toggled","stable","unstable","cList","assign","roDown","squ","dynamicTables","arn","lastKeysDown","extendList"}
local nulls = {"currentBuffer","mouseCount","modeUsed","tabNum","maxMode","maxKeys","sKey","but","dir","pMod","lastModC","exitus","keyCount","currentSample","cachedString","paginatorState"}
for k,v in pairs(tl.defaultOptions) do tl[k] = tl.options[k] or tl.defaultOptions[k] end
for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
if tl.defaultModeTarget == "self" then  tl.defaultModeTarget = nil end
tl.setKeys = tl.options.setKeys
tl.options.setKeys = nil
tl.version = "2.0"
tl.modeRide = false;
tl.findEx="Running on internal configs"
tl.press = false
tl.mods= ""
tl.macPlay = false
tl.docMode = false
tl.mainPos = 1
tl.macroStats.null={}
tl.pprint = dofile(tl.path..'/libraries/inspect.lua')
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
  pr    = function(f,g) tl.put('Monitor '..tl._getMonitor(),'Coordinates '..GetMousePosition()) end,
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
loadfile(tl.path.."/libraries/helperFunctions.lua")(tl)
loadfile(tl.path.."/modules/pollingTaskModule.lua")(tl)
loadfile(tl.path.."/modules/keyOutputModule.lua")(tl)
--->>> code written by myself ===============================================================================
loadfile(tl.path.."/modules/logitechInterfaceModule.lua")(tl)
loadfile(tl.path.."/modules/mouseCoordinatesModule.lua")(tl)
loadfile(tl.path.."/modules/bindingStructureModule.lua")(tl)
loadfile(tl.path.."/modules/profileCompilerModule.lua")(tl)
loadfile(tl.path.."/modules/stringUtilitiesModule.lua")(tl)
loadfile(tl.path.."/modules/macroExecutionModule.lua")(tl)
loadfile(tl.path.."/modules/tableUtilitiesModule.lua")(tl)
loadfile(tl.path.."/modules/eventHandlerModule.lua")(tl)
loadfile(tl.path.."/modules/coroutineModule.lua")(tl)
loadfile(tl.path.."/modules/lintingModule.lua")(tl)

return tl