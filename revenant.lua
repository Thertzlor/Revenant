---@class PathData
---@field profile fun(assign:MacroAssignment)
local defaultPaths = {
    profileName = "no_name", --Compile relevant
    path = "", --load relevant
    profilePaths = { "profiles/ext_lua", "profiles/ext_work" }, --load relevant
    fileLocation = 0, --load relevant
    defaultDocPath = { prefix = "", suffix = "_doc" },
    defaultConfigPath = { prefix = "", suffix = "_config" },
    absoluteProfilePaths = false, --load relevant
    absoluteConfigPaths = false,
    absoluteDocPaths = false,
    absoluteParentPaths = false,
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
    { "ControlMacro", "cyclecontrol", "cc" },
    { "ControlMacro", "macrocontrol", "mc" },
    { "FlagMacro", "flag", "f" },
    { "FlagMacro", "toggleflag", "ft" },
    { "LinkMacro", "link", "l" },
    { "CycleMacro", "cycle", "c" },
    { "LoggingMacro", "log", "o" },
    { "DpiMacro", "setdpi", "dpi" },
    { "FunctionMacro", "func", "fn" },
    { "HoldKeyMacro", "holdkey", "h" },
    { "ModeChangeMacro", "mode", "m" },
    { "SequenceMacro", "sequence", "s" },
    { "ExternalMacro", "externalmacro", "e" },
    { "MouseMoveMacro", "mouseposition", "p" },
    { "BackLightMacro", "backlight", "b" },
    { "KeyBufferMacro", "bufferkey", "kb" },
    { "MouseWheelMacro", "mousewheel", "w" },
    { "MultiClickMacro", "multiclick", "t" },
    { "ClearHistoryMacro", "wipehistory", "wh" },
    { "DocToggleMacro", "documentation", "doc" }
}
---@alias MacroType '"key"'|'"keyup"'|'"keydown"'|'"group"'|'"wrapkey"'|'"keytoggle"'|'"page"'|'"instance"'|'"cyclecontrol"'|'"macrocontrol"'|'"flag"'|'"toggleflag"'|'"link"'|'"cycle"'|'"log"'|'"setdpi"'|'"holdkey"'|'"mode"'|'"sequence"'|'"externalmacro"'|'"func"'|'"mouseposition"'|'"backlight"'|'"backlight"'|'"bufferkey"'|'"mousewheel"'|'"multiclick"'|'"wipehistory"'|'"documentation"'

--Default values for the options specified in the logitech bindings, as a fallback
---@class OptionsCollection
local defaultConfiguration = {
    stackOrder = { "custom", "mode", "shift" },
    separateDeviceCycles = false,
    LCDPersistentProfile = false,
    restrictToMainScreen = false,
    preventOptionOverride = true,
    LCDLastLinePagination = true,
    lagPositionThreshold = 1000,
    maxMovementLagSamples = 100,
    LCDHidePrimaryMode = false,
    mousePositionCheck = false,
    enableConfigLinting = true,
    mergeDocumentation = true,
    mergeScopeDefaults = true,
    preventDocOverride = true,
    monitors = { 1920, 1080 }, ---@type {[1]:number,[2]:number}|DeskoptDefinition
    LCDMessageDuration = 3000,
    keyboardLocale = "de-DE",
    offsetMovementLag = true,
    preventInheritance = {}, ---@type string[]
    abortOnLintError = true,
    stackAutoReverse = true,
    defaultModeTarget = nil, --Compile relevant
    mouseHistoryLimit = 100,
    LCDClearLastLine = true,
    globalModeFamily = "kb",
    primaryButtons = false,
    enableDebounce = false,
    shiftSort = "standard",
    customStack = "append",
    modeSort = "standard",
    shiftStack = "append",
    externalConfigs = nil,
    waitLagThreshold = 50,
    offsetWaitLag = true,
    modeStack = "append",
    globalGShift = false,
    keepNameOnLCD = true,
    enableLinting = true,
    pollMKeysOnly = true,
    multiClickTime = 200,
    maxLagSamples = 100,
    LCDSeparator = true, ---@type boolean|string
    showCompiled = true, --except this one
    defaultStacking = 1,
    actionVariance = 0,
    logDebounce = true,
    externalDocs = nil,
    LCDLineLength = 76,
    pollFamily = "lhc",
    defaultHold = 500,
    logEvents = false,
    logMemory = false,
    pollInterval = 10,
    modeReset = true,
    clearLog = false,
    devices = "G600",
    description = "",
    outputLCD = true,
    globalModes = {},
    actionDelay = 10,
    defaultShift = 2, --compile Relevant
    historyDepth = 2,
    keyVariance = 0,
    customSort = {},
    defaultMode = 0, -- General Profile configuration
    LCDLines = 10,
    keyDelay = 10,
    extends = "", --Compile relevant
    logLevel = 0,
    rename = {}, ---@type table<string,string>
    defaultKeys = {
        m1 = { "/1", m = 0, g = 2 },
        m2 = { "/2", m = 0, g = 2 },
        m3 = { "/3", m = 0, g = 2 },
        m4 = { "/4", m = 0, g = 2 },
        m5 = { "/5", m = 0, g = 2 }
    },
    debounceSettings = {
        mouse = {
            { 1, 30, 'up' },
            { 2, 30, 'up' }
        }
    }
}

local loadfile, xpcall, setmetatable, match, error, concat, pairs, ClearLCD, OutputLCDMessage = loadfile, xpcall, setmetatable, string.match, error, table.concat, pairs, ClearLCD, OutputLCDMessage
---@alias ClassName "MacroDefinition"|"KeyMacro"|'"ProfileDefinition"'|'"MonitorDefinition"'|'"SimpleKeyMacro"'
---@class Revenant
---@field profile ProfileDefinition
---@field put fun(...)
local rv = {
    keyStates = {
        lastKeysDown = {}, ---@type (EventInfo[] | {family:string})
        keysDown = {}, ---@type EventInfo[]
        logiKeys = {}, ---@type table<string,true>
        unRename = {}, ---@type table<string,string>
        roDown = {} ---@type table<string,KeyDefinition[]>
    },
    scriptStates = {
        locationIndicator = "Running on internal configs",
        exitingScript = false,
        currentButton = 0,
        version = "2.5b",
        docMode = false,
        keyCount = 0,
        errors = {}, ---@type string[]
        flags = {}, ---@type table<string,boolean|string>
        mods = '', ---@type string|number
    },
    stringPresets = {
        determinants = { "gshift", "mode", "mkey", "condition", "area" },
        internalPropsName = { "_scope", "pID", "name", "doc", "_meta" },
        internalProps = { "_scope", "pID", "doc", "_meta" },
        families = { "mouse", "keyboard", "lhc" },
        shortMapper = {}, ---@type table<string,string>
        optionDefaults = {
            mode = "defaultMode",
            gshift = "defaultShift"
        },
        shorthands = {
            t = "type",
            m = "mode",
            n = "name",
            mk = "mkey",
            g = "gshift",
            b = "blocking",
            c = "condition",
            dir = "direction",
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
        logitechKeyNames = { "tilde", "minus", "equal", "lbracket", "rbracket", "backslash", "capslock", "semicolon", "quote", "comma", "period", "slash", "escape", "enter", "tab", "spacebar", "up", "left", "down", "right", "backspace", "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24", "delete", "home", "insert", "pause", "pagedown", "pageup", "printscreen", "scrolllock", "appkey", "non_us_slash", "numlock", "end", "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7", "num8", "num9", "numslash", "numminus", "numplus", "numenter", "numperiod" },

        modKeys = {
            ["*"] = "lctrl", ["|"] = "lgui", ["~"] = "lshift", ["#"] = "lalt"
        }
    }
}

---@private
function rv:new(...)
    local o = {} ---@type any
    self.__index = self ---@private
    setmetatable(o, self)
    o:constructor(...)
    return o
end

local function _handleImportErrors(e, path)
    rv.scriptStates.errors[#rv.scriptStates.errors + 1] = "could not load file from path '" .. path .. ", Error:\n  \"" .. e .. '"'
end

local fileCache = {}
function rv:loadFile(path, handler)
    local code, ret = xpcall(function() return (loadfile(path) or error("No File/Syntax Error", 2))(self) end, function(err) (handler or _handleImportErrors)(err, path) end)
    if code then fileCache[path] = ret return ret end
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
    for k, v in pairs(self.stringPresets.shorthands) do self.stringPresets.shortMapper[v] = k end
    local lPath = self.paths.path .. "/src/libraries/"
    local mPath = self.paths.path .. "/src/modules/"
    self.baseClass = self:classImport("BaseClass") ---@type BaseClass
    local function instance(path) return (self:import(path) or { new = function() end }):new() end

    self.utils = instance(lPath .. "helperFunctions") ---@type UtilityModule
    -->>> Libraries from around the net ===============================================================================
    self.threading = instance(mPath .. "ThreadingModule") ---@type ThreadingModule
    self.keys = instance(mPath .. "KeyOutputModule") ---@type KeyOutputModule
    self.utf8 = self:import(lPath .. "utf8") ---@type UnicodeFunctions
    self.utils.pprint = self:import(lPath .. "inspect")
    -->>> code written by myself ===============================================================================
    self.mouseMonitorUtils = instance(mPath .. "MouseCoordinatesModule") ---@type MouseCoordinatesModule
    self.logitech = instance(mPath .. "LogitechInterfaceModule") ---@type LogitechInterfaceModule
    self.lcd = instance(mPath .. "DisplayStateModule") ---@type DisplayStateModule
    self.validator = instance(mPath .. "MacroValidatorModule") ---@type MacroValidatorModule
    self.eventHandler = instance(mPath .. "EventHandlerModule") ---@type EventHandlerModule
    self.str = instance(mPath .. "StringUtilitiesModule") ---@type StringUtilitiesModule
    self.tbl = instance(mPath .. "TableUtilitiesModule") ---@type TableUtilitiesModule
    self.hardware = instance(mPath .. "HardwareModule") ---@type HardwareModule
    self.lint = instance(mPath .. "LintingModule") ---@type LintingModule
    self.debouncer = instance(mPath .. "DebounceModule") ---@type DebounceModule
    self.paths = self.tbl:intersectSimple(defaultPaths, self.paths, true) ---@type PathData
    if #self.scriptStates.errors ~= 0 then self:crash() end
end

return rv
