---@class PathData
local defaultPaths = {
    profileName = "no_name", --Compile relevant
    path = "", --load relevant
    extPaths = { "profiles/ext_lua", "profiles/ext_work" }, --load relevant
    childPaths = true, --load relevant
    fileLocation = 0, --load relevant
    defaultDocPath = { prefix = "", suffix = "_doc" },
    defaultConfigPath = { prefix = "", suffix = "_config" },
    configPath = ""
}

local macroTerms = {
    { "KeyMacro", "key", "k" },
    { "KeyMacro", "keyup", "u" },
    { "KeyMacro", "keydown", "d" },
    { "GroupMacro", "group", "g" },
    { "KeyMacro", "wrapkey", "kw" },
    { "KeyMacro", "keytoggle", "kt" },
    { "PaginationMacro", "page", "pg" },
    { "InstanceMacro", "instance", "i" },
    { "ControlMacro", "holdcancel", "hc" },
    { "ControlMacro", "cyclecontrol", "cc" },
    { "ControlMacro", "sequencecontrol", "sc" },
    { "FlagMacro", "flag", "f" },
    { "FlagMacro", "toggleflag", "ft" },
    { "LinkMacro", "link", "l" },
    { "CycleMacro", "cycle", "c" },
    { "LoggingMacro", "log", "o" },
    { "DpiMacro", "setdpi", "dpi" },
    { "HoldKeyMacro", "holdkey", "h" },
    { "ModeChangeMacro", "mode", "m" },
    { "SequenceMacro", "sequence", "s" },
    { "ExternalMacro", "playmacro", "e" },
    { "FunctionMacro", "function", "fn" },
    { "MouseMoveMacro", "mousemove", "p" },
    { "BackLightMacro", "backlight", "b" },
    { "KeyBufferMacro", "bufferkey", "kb" },
    { "MouseWheelMacro", "mousewheel", "w" },
    { "MultiClickMacro", "multiclick", "t" },
    { "MonitorMacro", "monitorchange", "ms" },
    { "ClearHistoryMacro", "wipehistory", "dh" },
    { "DocToggleMacro", "documentation", "doc" }
}
--Default values for the options specified in the logitech bindings, as a fallback
---@class OptionsCollection
local defaultConfiguration = {
    defaultConfigPath = { path = "", prefix = "", suffix = "_config", name = "" },
    defaultDocPath = { path = "", prefix = "", suffix = "_doc", name = "" },
    handleDocumentationConflicts = "replaceDuplicates",
    resolutions = { { 1920, 1080, main = true } },
    handleOptionConflicts = "replaceDuplicates",
    stackOrder = { "custom", "mode", "shift" },
    LCDLastLinePagination = true,
    separateDeviceCycles = false,
    restrictToMainScreen = false,
    lagPositionThreshold = 1000,
    LCDHidePrimaryMode = false,
    mousePositionCheck = false,
    absoluteConfigPath = false,
    enableConfigLinting = true,
    maxInheritanceDepth = 20,
    scaleCoordinates = false,
    keyboardLocale = "de-DE",
    preferShorthand = false,
    abortOnLintError = true,
    stackAutoReverse = true,
    defaultModeTarget = nil, --Compile relevant
    mouseHistoryLimit = 100,
    LCDClearLastLine = true,
    primaryButtons = false,
    shiftSort = "standard",
    customStack = "append",
    modeSort = "standard",
    lagSampleAmount = 100,
    shiftStack = "append",
    externalConfigs = nil,
    modeStack = "append",
    globalGShift = false,
    keepNameOnLCD = true,
    enableLinting = true,
    pollMKeysOnly = true,
    pollFamily = "mouse",
    multiClickTime = 200,
    LCDSeparator = true,
    showCompiled = true, --except this one
    permissibleLag = 10,
    defaultStacking = 1,
    actionVariance = 0,
    externalDocs = nil,
    LCDLineLength = 76,
    lagSampleSize = 5,
    defaultHold = 500,
    logEvents = false,
    logMemory = false,
    pollInterval = 10,
    mouseInterval = 5,
    devices = "G600",
    description = "",
    outputLCD = true,
    globalModes = {},
    actionDelay = 10,
    defaultShift = 2, --compile Relevant
    historyDepth = 2,
    logBounce = true,
    keyVariance = 0,
    customSort = {},
    clearLog = true,
    clearLCD = true,
    defaultMode = 0, -- General Profile configuration
    persistLCD = -1,
    LCDLines = 10,
    keyDelay = 10,
    extends = "", --Compile relevant
    logLevel = 0,
    defaultKeys = {
        m1 = { "/1", m = 0, g = 2 },
        m2 = { "/2", m = 0, g = 2 },
        m3 = { "/3", m = 0, g = 2 },
        m4 = { "/4", m = 0, g = 2 },
        m5 = { "/5", m = 0, g = 2 }
    },
    debouncerSettings = {
        mouse = {
            { 1, 30, 'up' },
            { 2, 30, 'up' }
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

local loadfile, xpcall, setmetatable, match, error, concat, pairs, ClearLCD, OutputLCDMessage = loadfile, xpcall, setmetatable, string.match, error, table.concat, pairs, ClearLCD, OutputLCDMessage
---@alias ClassName "MacroDefinition"|"KeyMacro"|'"ProfileDefinition"'|'"MonitorDefinition"'|'"SimpleKeyMacro"'
---@class MainLibBase
local rv = {
    keyStates = {
        lastKeysDown = {}, ---@type table<string,number[]>
        keysDown = {},
        logiKeys = {},
        unRename = {},
        roDown = {}
    },
    scriptStates = {
        locationIndicator = "Running on internal configs",
        exitingScript = false,
        currentButton = 0,
        version = "2.5b",
        docMode = false,
        keyCount = 0,
        errors = {},
        flags = {},
        mods = "",
    },
    stringPresets = {
        determinants = { "gshift", "mode", "mkey", "condition", "area" },
        internalPropsName = { "_scope", "pID", "name", "doc", "_meta" },
        internalProps = { "_scope", "pID", "doc", "_meta" },
        families = { "mouse", "keyboard", "lhc" },
        shortMapper = {},
        optionDefaults = {
            mode = "defaultMode",
            gshift = "defaultShift"
        },
        shortHands = {
            t = "type",
            m = "mode",
            n = "name",
            mk = "mkey",
            g = "gshift",
            b = "blocking",
            c = "condition",
            kd = "keyDelay",
            dir = "direction",
            kv = "keyVariance",
            doc = "documentation"
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
        },
        logitechKeyNames = { "tilde", "minus", "equal", "lbracket", "rbracket", "backslash", "capslock", "semicolon", "quote", "comma", "period", "slash", "escape", "enter", "tab", "spacebar", "up", "left", "down", "right", "backspace", "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24", "delete", "home", "insert", "pause", "pagedown", "pageup", "printscreen", "scrolllock", "appkey", "non_us_slash", "numlock", "end", "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7", "num8", "num9", "numslash", "numminus", "numplus", "numenter", "numperiod" }
    }
}

---@class MainLibObject:MainLibBase
---@private
function rv:new(...)
    local o = {}---@type any
    self.__index = self---@private
    setmetatable(o, self)
    o:constructor(...)
    return o
end

local function _handleImportErrors(e, path)
    rv.scriptStates.errors[#rv.scriptStates.errors + 1] = "could not load file from path '" .. path .. ", Error:\n  \"" .. e .. '"'
end

local fileCache = {}
function rv:loadFile(path, handler)
    local code, ret = xpcall(function() return (loadfile(path) or error("No File/Syntax Error", 2))(self) end, function(err)(handler or _handleImportErrors)(err, path) end) if code then fileCache[path] = ret return ret end
end
function rv:import(path, handler)
    local p = path:gsub("%.lua$", ""):gsub("$", ".lua")
    return fileCache[p] or self:loadFile(p, handler)
end

function rv:crash(msg)
    OnEvent = function() end
    ClearLCD()
    OutputLCDMessage("Revenant ERROR\ncheck scripting console.", -1)
    OutputLCDMessage("", -1)
    local test, res, errs = {}, {}, self.scriptStates.errors
    for i = 1, #errs do local err = errs[i] if not test[err] then res[#res + 1] = err end test[err] = true end
    error(((msg and msg .. "\n") or "") .. concat(res, "\n"), 10)
end

function rv:classImport(name)
    local isMacro = match(name, 'Macro$')
    if isMacro and name ~= "GroupMacro" then self.macroImports[name] = true end
    return self:import(self.paths.path .. "/src/classes/" .. ((isMacro and "macros/") or "") .. name)
end

---@private
function rv:constructor(pathConfig)
    ClearLCD()
    self.defaultConfig = defaultConfiguration
    self.paths = pathConfig
    self.macroImports = {}
    self.classMap = {}
    for i = 1, #macroTerms do local el = macroTerms[i]
        self.classMap[el[2]] = { el[1], el[2] }
        self.classMap[el[3]] = { el[1], el[2] }
    end
    for k, v in pairs(self.stringPresets.shortHands) do self.stringPresets.shortMapper[#self.stringPresets.shortMapper + 1] = { k, v } end
    local lPath = self.paths.path .. "/src/libraries/"
    local mPath = self.paths.path .. "/src/modules/"
    self.baseClass = self:classImport("BaseClass")---@type BaseClass
    local function instance(path) return (self:import(path) or { new = function() end }):new() end
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
    self.eventHandler = instance(mPath .. "EventHandlerModule") ---@type EventHandlerModule
    self.coroutines = instance(mPath .. "CoroutineModule") ---@type CoroutineModule
    self.str = instance(mPath .. "StringUtilitiesModule") ---@type StringUtilitiesModule
    self.tbl = instance(mPath .. "TableUtilitiesModule") ---@type TableUtilitiesModule
    self.lint = instance(mPath .. "LintingModule") ---@type LintingModule
    self.debouncer = instance(mPath .. "DebounceModule") ---@type DebounceModule
    self.paths = self.tbl:intersectSimple(defaultPaths, self.paths, true)---@type PathData
    if #self.scriptStates.errors ~= 0 then self:crash() end
end

return rv