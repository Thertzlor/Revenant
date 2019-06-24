--Default values for the options specified in in the logitech bindings, as a fallback
local tl = ...
-- Framework Configuration
tl.profileName = tl.profileName or "no_name"
tl.extPaths = tl.extPaths or {"ext_lua","ext_work"}
tl.childPaths = tl.childPaths or 1
tl.fileLocation = tl.fileLocation or 0
tl.keyFile = tl.keyFile or "T-lib_keySetup.lua"
tl.defaultMode = tl.defaultMode or 0
tl.defaultShift = tl.defaultShift or 2
tl.genericModes = tl.genericModes or {}
tl.actionDelay = tl.actionDelay or 10
tl.keyDelay = tl.keyDelay or 10
tl.defaultHold = tl.defaultHold or 500
tl.multiClickTime = tl.multiClickTime or 200
tl.PollInterval = tl.PollInterval or 10
tl.randomActionDeviation = tl.randomActionDeviation or 0
tl.randomKeyDeviation = tl.randomKeyDeviation or 0
tl.customNames = tl.customNames or 1
tl.defaultStacking = tl.defaultStacking or 1
tl.preferShorthand = tl.preferShorthand or 0
tl.cacheLinks = tl.cacheLinks or 1
tl.historyDepth = tl.historyDepth  or 2
tl.mouseInterval = tl.mouseInterval or 3
tl.extends = tl.extends or ""

--LCD Configuration
tl.outputLCD = tl.outputLCD or 1
tl.clearLCD = tl.clearLCD or 1
tl.persistLCD = tl.persistLCD or -1
tl.keepNameOnLCD = tl.keepNameOnLCD or 1
tl.appendNewLines = tl.appendNewLines or 1

-- Hardware Configuration
tl.resolutions = tl.resolutions or {1920,1080}
tl.separateDeviceCycles = tl.separateDeviceCycles or 0
tl.defaultModeTarget = tl.defaultModeTarget or nil
if tl.defaultModeTarget == "self" then  tl.defaultModeTarget = nil end

tl.mouseButtonCount = tl.mouseButtonCount or 20
tl.mouseShiftKey = tl.mouseShiftKey or 6
tl.mouseModeCount = tl.mouseModeCount or 3
tl.mouseModeConfig = tl.mouseModeConfig or {"mode 1","mode 2"}
tl.mouseBindHardwareModes = tl.mouseBindHardwareModes or 1
tl.mousePositionCheck = tl.mousePositionCheck or 0

tl.keyboardButtonCount = tl.keyboardButtonCount or 6
tl.keyboardShiftKey = tl.keyboardShiftKey or 6
tl.keyboardModeCount = tl.keyboardModeCount or 0
tl.keyboardModeConfig = tl.keyboardModeConfig or {}
tl.keyboardBindHardwareModes = tl.keyboardBindHardwareModes or 1

tl.audioButtonCount = tl.audioButtonCount or 1
tl.audioShiftKey = tl.audioShiftKey or 0
tl.audioModeCount = tl.audioModeCount or 0
tl.audioModeConfig = tl.audioModeConfig or {}
tl.audioBindHardwareModes = tl.audioBindHardwareModes or 1

tl.lhcButtonCount = tl.lhcButtonCount or 1
tl.lhcShiftKey = tl.lhcShiftKey or 0
tl.lhcModeCount = tl.lhcModeCount or 1
tl.lhcModeConfig = tl.lhcModeConfig or {}
tl.lhcBindHardwareModes = tl.lhcBindHardwareModes or 1
tl.logLevel = tl.logLevel or 0

-- Flex Syntax Configuration
tl.showCompiled = tl.showCompiled or 1
tl.modeStack = tl.modeStack or"append"
tl.shiftStack = tl.shiftStack or"append"
tl.customStack = tl.customStack or"append"
tl.modeSort = tl.modeSort or"standard"
tl.shiftSort = tl.shiftSort or"standard"
tl.customSort = tl.customSort or{}
tl.stackOrder = tl.stackOrder or{"custom","mode","shift"}
tl.stackAutoReverse = tl.stackAutoReverse or 1
tl.stackDepth = tl.stackDepth or 1
tl.singleType = tl.singleType or 0

tl.defaultKeys={
  m3={"/3",m=0,s=0},
  m4={"/4",m=0,s=0},
  m5={"/5",m=0,s=0}
}

tl.rename={
  m1="m1",
  m2="m2",
  m3="m3",
  m4="m7",
  m5="m8",
  m6="m6",
  m7="m5",
  m8="m4",
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

local empties={"archivedLCD","state","unname",'macroStats',"downs","toggled","stable","unstable","cList","assign","roDown","squ","dynamicTables","arn","lastKeysDown","extendList"}
local nulls = {"mouseCount","modeUsed","tabNum","maxMode","maxKeys","sKey","but","dir","pMod","lastModC","exitus","keyCount"}
for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
tl.version = "1.9"
tl.modeRide = false;
tl.findEx="Running on internal configs"
tl.press = false
tl.mods= ""
tl.macPlay = false
tl.pprint = dofile(table.concat({tl.path,'libraries','inspect.lua'},"/"))
loadfile(table.concat({tl.path,'configs',tl.keyFile},"/"))(tl)

tl.families={"mouse","keyboard","audio","lhc"}
tl.unToken={m="Mouse",k="Keyboard",a="Audio",l="LHC"}
tl.unLogiToken={m="mouse",k="kb",a="audio",l="lhc"}

if tl.customNames == 0 then tl.rename={} end

tl.shortHands={
  {"t","type"},
  {"g","gshift"},
  {"m","mode"},
  {"mk","mkey"},
  {"c","consume"},
  {"l","loop"},
  {"p","play"},
  {"dir","direction"},
  {"ad","delay"},
  {"kd","keyDelay"},
  {"n","name"},
  {"u","update"}
}
--tl.normKey(tg,dir,relmod,vir,bid)
--tabs[def](cmd,mDir,pDir,mouse,virtu,virp,fam)
tl.defaultFuncs={
  c     = function(f,g,_,_,v,y,z) tl.agnostiCycle(f,g,v,y,z) end,
  n     = function(f,g,_,_,v) tl.normKey(f,g,0,v,f.pID) end,
  d     = function(f,g,_,_,v) tl.normKey(f,g,1,v,f.pID) end,
  u     = function(f,g,_,_,v) tl.normKey(f,g,2,v,f.pID) end,
  s     = function(f,g,h,b,v,_,z)  tl.quiKey(f,f.name or f.pID,g,h,b,v,z) end,
  h     = function(f,g,_,_,_,_,z) tl.stagger(f,g,z) end,
  eh    = function(f) tl.togMac(f) end,
  et    = function(f,g) tl.togMac(f,g) end,
  mt    = function(f,_,_,_,_,_,z,w) tl.togMode(f,w or tl.defaultModeTarget or z) end,
  p     = function(f,g)  tl.mouseMove(f,nil,g) end,
  pr    = function(f,g) tl.mouseMove(f,true,g) end
}

tl.upDownFuncs={
  nt    = function(f,g,_,_,v) tl.normKey(f,g,3,v,f.pID) end,
  hc    = function(f,g) tl.lcancel(f,g) end,
  mn    = function(f,_,_,_,_,_,z,w) tl.tempMode(f,w or tl.defaultModeTarget or z) end,
  e     = function(f) tl.PlayMac(f) end,
  ea    = function() AbortMacro() end,
  m     = function(f,_,_,_,_,_,z,w) tl.molect(f,w or tl.defaultModeTarget or z) end,
  w     = function(f) MoveMouseWheel(f) end,
  sa    = function(f) tl.multiAbort(f) end,
  fn    = function(f) tl.executor(f) end,
  cr    = function(f) tl.cycleReset(f) end,
  sp    = function(f) tl.tPause(f) end,
  sr    = function(f) tl.tRes(f) end,
  dh    = function(f,g) tl.histoRase(f[1],g) end,
  t     = function(f,g,_,_,_,_,z) tl.timerKey(f,g,z) end,
  b     = function(f,_,_,_,_,_,z,w) tl.backLighter(f,w or z) end,
  o     = function(f) tl.outputWrapper(f) end
}

tl.sequenceInheritor = {"gshift","mode","mkey","unlock"}
tl.upFuncs = {}
tl.macFuncs = {}
--->>> Libraries from around the net ===============================================================================
loadfile(table.concat({tl.path,"libraries","helperFunctions.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","keyOutputModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","pollingTaskModule.lua"},"/"))(tl)
--->>> code written by myself ===============================================================================
loadfile(table.concat({tl.path,"modules","logitechInterfaceModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","coroutineModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","mouseCoordinatesModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","macroExecutionModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","tableHelperModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","stringHelperModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","bindingStructureModule.lua"},"/"))(tl)
loadfile(table.concat({tl.path,"modules","eventHandlerModule.lua"},"/"))(tl)

return tl