--Default values for the options specified in in the logitech bindings, as a fallback
local tl = ...
tl.extPaths = tl.extPaths or {"ext_lua","ext_work"}
tl.childPaths = tl.childPaths or 1
tl.fileLocation = tl.fileLocation or 0
tl.extends = tl.extends or ""
tl.keyFile = tl.keyFile or "T-lib_keySetup.lua"
tl.autoHot = tl.autoHot or 0
tl.modeBound = tl.modeBound or 1
tl.sKey = tl.sKey or 6
tl.maxMode = tl.maxMode or 3
tl.PollInterval = tl.PollInterval or 10
tl.actionDelay = tl.actionDelay or 10
tl.keyDelay = tl.keyDelay or 10
tl.logicalMouse = tl.logicalMouse or 1
tl.defMode = tl.defMode or 0
tl.defG = tl.defG or 2
tl.preferShort = tl.preferShort or 0
tl.defaultHold = tl.defaultHold or 500
tl.historyDepth = tl.historyDepth  or 2
tl.logEmpty = tl.logEmpty or 0
tl.cacheLinks = tl.cacheLinks or 1
tl.resolutions = tl.resolutions or {1920,1080}
tl.multiClickTime = tl.multiClickTime or 200
tl.mouseCheck = tl.mouseCheck or 1
tl.mouseInterval = tl.mouseInterval or 3
tl.randomActionDeviation = tl.randomActionDeviation or 0
tl.randomKeyDeviation = tl.randomKeyDeviation or 0
tl.buttonCount={mouse=20,keyboard=6,lhc=0,audio=3}
tl.separateDeviceCycles = tl.separateDeviceCycles or 0
tl.separateDeviceModes = tl.separateDeviceModes or 1
tl.modes = tl.modes or {}
tl.outputLCD = tl.outputLCD or 1
tl.clearLCD = tl.clearLCD or 1
tl.persistLCD = tl.persistLCD or -1
tl.keepNameOnLCD = tl.keepNameOnLCD or 1   
tl.appendNewLines = tl.appendNewLines or 1


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

tl.defStack = tl.defStack or 1
tl.profileName = tl.profileName or "no_name"
tl.nameIndex = tl.nameIndex or 999

local empties={"archivedLCD","unname","normalizedScreens",'macroStats',"downs","toggled","stable","unstable","cList","assign","roDown","squ","dynamicTables","arn","lastKeysDown","extendList"}
local nulls = {"mouseCount","state","but","dir","pMod","conKey","lastModN","lastModC","lastMod","exitus","keyCount"}
for i=1,#empties do tl[empties[i]] = {} end
for i=1,#nulls do tl[nulls[i]] = 0 end
tl.version = "1.9"
tl.modeRide = false;
tl.modus = 1
tl.shiftor = 0
tl.shiftus = 0
tl.mBeforeG = 1
tl.findEx="Running on internal configs"
tl.press = false
tl.mods= ""
tl.macPlay = false
tl.lastKeysUp={0}
tl.pprint = dofile(table.concat({tl.path,'libraries','inspect.lua'},"/"))
loadfile(table.concat({tl.path,'configs',tl.keyFile},"/"))(tl)

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

tl.defaultKeys={
  m3={"/3",m=0,s=0},
  m4={"/4",m=0,s=0},
  m5={"/5",m=0,s=0}
}

tl.cycleCombi = {"/c","/s","/a","/24"}

tl.families={mouse="m",audio="a",lhc="l",keyboard="k"}

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
--tabs[def](cmd,mDir,pDir,mouse,virtu,virp)
tl.defaultFuncs={
  c     = function(f,g,_,_,v,y) tl.agnostiCycle(f,g,v,y) end,
  n     = function(f,g,_,_,v) tl.normKey(f,g,0,v,f.pID) end,
  d     = function(f,g,_,_,v) tl.normKey(f,g,1,v,f.pID) end,
  u     = function(f,g,_,_,v) tl.normKey(f,g,2,v,f.pID) end,
  s     = function(f,g,h,b,v)  tl.quiKey(f,f.name or f.pID,g,h,b,v) end,
  h     = function(f,g) tl.stagger(f,g) end,
  eh    = function(f) tl.togMac(f) end,
  et    = function(f) tl.togMac(f,tl.dir) end,
  mt    = function(f) tl.togMode(f) end,
}

tl.upDownFuncs={
  nt    = function(f,g,_,_,v) tl.normKey(f,g,3,v,f.pID) end,
  hc    = function(f) tl.lcancel(f,tl.dir) end,
  mn    = function(f) tl.tempMode(f) end,
  pc    = function() tl.profileCycle() end,
  e     = function(f) tl.PlayMac(f) end,
  ea    = function() AbortMacro() end,
  m     = function(f) tl.molect(f) end,
  w     = function(f) MoveMouseWheel(f) end,
  sa    = function(f) tl.multiAbort(f) end,
  fn    = function(f) tl.executor(f) end,
  cr    = function(f) tl.cycleReset(f) end,
  sp    = function(f) tl.tPause(f) end,
  sr    = function(f) tl.tRes(f) end,
  dh    = function(f,g) tl.histoRase(f[1],g) end,
  p    = function(f)  tl.mouseMove(f) end,
  pr    = function(f) tl.mouseMove(f,true) end,
  t     = function(f,g) tl.timerKey(f,g) end
}

tl.upFuncs = {
}

tl.macFuncs = {

}
tl.sequenceInheritor = {"gshift","mode","mkey","mouseLock","keyLock"}

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