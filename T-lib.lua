
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
  {"SequenceMacro","sequence","s"},
  {"ModeChangeMacro","mode","m"},
  {"WrapKeyMacro","wrapkey","kw"},
  {"DownKeyMacro","keydown","d"},
  {"ExternalMacro","playmacro","e"},
  {"CycleMacro","cycle","c"},
  {"CycleControlMacro","cyclecontrol","cc"},
  {"MouseWheelMacro","mousewheel","w"},
  {"KeyUpMacro","keyup","u"},
  {"BaseKeyMacro","key","k"},
  {"MouseMoveMacro","mousemove","p"},
  {"HoldKeyMacro","holdkey","h"},
  {"FlagToggleMacro","toggleFlag","ft"},
  {"ToggleKeyMacro","keytoggle","kt"},
  {"BackLightMacro","backlight","b"},
  {"MultiClickMacro","multiclick","t"},
  {"KeyBufferMacro","bufferkey","kb"},
  {"ClearHistoryMacro","wipehistory","dh"},
  {"HoldCancelMacro","holdcancel","hc"},
  {"DocToggleMacro","documentation","doc"},
  {"LoggingMacro","log","o"},
  {"FunctionMacro","function","fn"},
  {"SequenceControlMacro","sequencecontrol","sc"},
  {"FlagMacro","flag","f"},
  {"MonitorMacro","monitorchange","ms"},
  {"SequenceResumeMacro","resume","sr"}}
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

local  dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable,MoveMouseWheel,type,randomseed =
   dofile, loadfile, pairs, OutputLogMessage, xpcall, setmetatable,MoveMouseWheel,type,math.randomseed

local totalMacros = 0

---@alias ClassName '"BaseMacro"'|'"BaseKeyMacro"'|'"ProfileDefinition"'|'"MonitorDefinition"'|'"SimpleKeyMacro"'
---@class BaseClass
local BaseClass = {}
---@protected
function BaseClass:constructor(baseObject)
  if type(baseObject) ~= "table" then return end
  for k, v in pairs(baseObj) do self[k]=v end
end

function BaseClass:genId()
  self.pID = 'c'..totalMacros
  totalMacros = totalMacros+1
  return self.pID
end

function BaseClass:new(...)
    local o = {}
    ---@private
    self.__index = self
    ---@private
    self.__eq = function(a,b)return a.pID == b.pID end
    setmetatable(o, self)
    o:constructor(...)
    return o
end

---@protected
---@param fn string Function name
---@param strTab string|table Argument
function BaseClass:multiArg(fn,strTab)
  local tab = type(strTab) == 'table'
  if tab then
    for i = 1, #strTab do local el = strTab[i]
      self[fn](self,el)
    end
  end
  return tab
end
local yield,create,resume,running = coroutine.yield,coroutine.create,coroutine.resume,coroutine.running

local function put(msg)
  OutputLogMessage(tostring(msg)..'\n')
end

local finStore = {fipina=400}
local yieldStore = {}

local CoTest = BaseClass:new()
function CoTest:constructor(name,req)
  self.name = name
  self.init = false
  self.req = req
  self.vals = {}
  self.valNum = 0
  if #req == 0 then self:finalize() else
    for i = 1, #req do local r = req[i]
      local selfy = create(self.import)
      local b,e = resume(selfy,self,r)
      if not b then put(e) end
    end
  end
end

function CoTest:finalize()
  self.init = true
  put(self.name..' is initialized')
  finStore[self.name]=self.name
  if yieldStore[self.name] then
    for i = 1, #yieldStore[self.name].queue do local q = yieldStore[self.name].queue[i]
      local b,e = resume(q,self.name)
      if not b then put(e) end
    end
  end
end

function CoTest:circular(term,stack)
  local stack = stack or {}
  if not yieldStore[term] then return end
  local store = yieldStore[term].waiting
  for i = 1, #store do local waiter = store[i]
    for m = 1, #stack do
      
      if waiter == stack[m] then 
        stack[#stack+1]=waiter
      error('circulöar requirement detected: '..table.concat(stack,'->'))
    end

    end
    stack[#stack+1]= term
    self:circular(waiter,stack)
  end
end
function CoTest:import(what)
  put(self.name..' launching import for '..what)
  if finStore[what] then 
    self.vals[what]=finStore[what]
    put('found value for '..what..' in store')
  else
    if yieldStore[what] then
      yieldStore[what].queue[#yieldStore[what].queue+1] = running()
      yieldStore[what].waiting[#yieldStore[what].waiting+1] = self.name
    else 
      yieldStore[what] = {queue ={running()},waiting={self.name}}
    end
    put(what.." doesn't exist yet, adding to queue")
    self:circular(what)
    self.vals[what] = yield()
  end
  self.valNum = self.valNum+1
  put(self.name.." finished import of "..what..' with value '..self.vals[what]..', '..self.valNum..' of '..#self.req)

  if self.valNum == #self.req then
    self:finalize()
  else
  end
end
local coExec = CoTest:new("foputa",{"faputa","fepeta"})
local coExec2 = CoTest:new("faputa",{"fepeto"})
local coExec2 = CoTest:new("fepeto",{"fepeta","fapino"})
local coExec2 = CoTest:new("fapino",{"foputa"})
local coExec3 = CoTest:new("fepeta",{"fipina"})

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

---@type table<string,HardwareDefinition>
tl.deviceState = {}

randomseed(GetRunningTime())
local function _handleImportErrors(e, path)
    --  ClearLog()
    local errString = "could not load file from path '" .. path .. "', Error: " .. e
    OutputLogMessage(errString)
      tl.scriptStates.errors[#tl.scriptStates.errors + 1] = errString
  end

local fileCache = {}
function tl:countMacros() return totalMacros end
function tl:loadFile(path)
  local code, ret =xpcall(function()return loadfile(path .. ".lua")(self, BaseClass)end,function(err)_handleImportErrors(err, path .. ".lua")end)if code then fileCache[path] = ret return ret end 
end
function tl:import(path)return fileCache[path] or self:loadFile(path)end
function tl:profileImport(path,assignTable)xpcall(function()return loadfile(path .. ".lua")(assignTable)end,function(err)_handleImportErrors(err, path .. ".lua")end) end
function tl:constructor(pathConfig)
  self.paths = pathConfig
  self.config = defaultConfiguration
  self.defaultConfig = defaultConfiguration
  self.totalMacros = 0
  for k, v in pairs(defaultConfiguration) do self.config[k] = self.config[k] or v end
  local lPath = self.paths.path .. "/src/libraries/"
  local mPath = self.paths.path .. "/src/modules/"
  local cPath = self.paths.path .. "/src/classes/"
  ---@param name ClassName
  function tl:classImport(name) return self:import(cPath..name) end
  local function instance(path) return self:import(path):new() end
  self.helperUtils = instance(lPath .. "helperFunctions") ---@type UtilityModule
  --->>> Libraries from around the net ===============================================================================
  self.polling = instance(mPath .. "PollingTaskModule") ---@type PollingModule
  self.keys = instance(mPath .. "KeyOutputModule") ---@type KeyOutputModule
  self.utf8 = self:import(lPath .. "utf8") ---@type UnicodeFunctions
  self.helperUtils.pprint = self:import(lPath .. "inspect")
  --->>> code written by myself ===============================================================================

  self.mouseMonitorUtils = instance(mPath .. "MouseCoordinatesModule") ---@type MouseCoordinatesModule
  self.profileCompiler = instance(mPath .. "ProfileCompilerModule") ---@type ProfileCompilerModule
  self.logitech = instance(mPath .. "LogitechInterfaceModule") ---@type LogitechInterfaceModule
  self.bindings = instance(mPath .. "BindingStructureModule") ---@type BindingStructureModule
  self.eventHandler =instance(mPath .. "EventHandlerModule") ---@type EventHandlerModule
  self.macros = instance(mPath .. "MacroExecutionModule") ---@type MacroExecutionModule
  self.str =instance(mPath .. "StringUtilitiesModule") ---@type StringUtilitiesModule
  self.tbl = instance(mPath .. "TableUtilitiesModule") ---@type TableUtilitiesModule
  self.coroutines = instance(mPath .. "CoroutineModule") ---@type CoroutineModule
  self.lint = instance(mPath .. "LintingModule") ---@type LintingModule
  loadfile(self.paths.path .. "/configs/" .. self.config.keyFile)(self)
  self.macroIndex = self.helperUtils.newIndexTable()
  self.paths = self.tbl:intersectSimple(self.paths,defaultPaths,true)
  self.classMap = {}
  for i = 1, #macroTerms do local el = macroTerms[i]
    self.classMap[el[2]] = el[1]
    self.classMap[el[3]] = el[1]
  end
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