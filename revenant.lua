---This is the object type Revenant receives during initialization
---@class PathData
---@field profile fun(assign:ProfileTemplate) #The part of the profile executed in the LGS editor
local defaultPaths = {
   profileName = "no_name", ---The name of the current profile (Compile relevant)
   path = "", ---Path to Revenant folder (load relevant)
   profilePath = "profiles", ---an array of locations holding profiles (load relevant)
   externalProfile = false, ---Select which path the current profile is loaded from (load relevant)
   defaultDocPath = {prefix = "", suffix = "_doc"},
   defaultConfigPath = {prefix = "", suffix = "_config"},
   absoluteProfilePaths = false, ---Are the folders for profile groups child folders of the main script folder? (load relevant)
   absoluteConfigPaths = false, -- Are paths in Config files absolute or relative to the current file?
   absoluteDocPaths = false, -- Are paths in Documentation files absolute or relative to the current file?
   absoluteParentPaths = false, ---Are the paths from which parent profiles should be loaded absolute or relative to the current profile?
   configPath = "" ---Path to the general Revenant configuration, Hardware,Keyboard layouts, etc
}

local macroTerms = { ---A list of all available macros with their long and short designations
   {"KeyMacro", "key", "k"}, --
   {"KeyMacro", "keyup", "u"}, --
   {"KeyMacro", "keydown", "d"}, --
   {"GroupMacro", "group", "g"}, --
   {"KeyMacro", "wrapkey", "kw"}, --
   {"KeyMacro", "keytoggle", "kt"}, --
   {"PaginationMacro", "page", "pg"}, --
   {"InstanceMacro", "instance", "i"}, --
   {"ControlMacro", "cyclecontrol", "cc"}, --
   {"ControlMacro", "macrocontrol", "mc"}, --
   {"FlagMacro", "flag", "f"}, --
   {"FlagMacro", "toggleflag", "ft"}, --
   {"LinkMacro", "link", "l"}, --
   {"CycleMacro", "cycle", "c"}, --
   {"LoggingMacro", "log", "o"}, --
   {"DpiMacro", "setdpi", "dpi"}, --
   {"FunctionMacro", "func", "fn"}, --
   {"HoldKeyMacro", "holdkey", "h"}, --
   {"ModeChangeMacro", "mode", "m"}, --
   {"SequenceMacro", "sequence", "s"}, --
   {"ExternalMacro", "externalmacro", "e"}, --
   {"MouseMoveMacro", "mouseposition", "p"}, --
   {"BackLightMacro", "backlight", "b"}, --
   {"KeyBufferMacro", "bufferkey", "kb"}, --
   {"MouseWheelMacro", "mousewheel", "w"}, --
   {"MultiClickMacro", "multiclick", "t"}, --
   {"WipeHistoryMacro", "wipehistory", "wh"}, --
   {"DocToggleMacro", "documentation", "doc"} --
}
---@alias MacroType "key"|"keyup"|"keydown"|"group"|"wrapkey"|"keytoggle"|"page"|"instance"|"cyclecontrol"|"macrocontrol"|"flag"|"toggleflag"|"link"|"cycle"|"log"|"setdpi"|"holdkey"|"mode"|"sequence"|"externalmacro"|"func"|"mouseposition"|"backlight"|"backlight"|"bufferkey"|"mousewheel"|"multiclick"|"wipehistory"|"documentation"
---@alias MacroShortType "k"|"u"|"d"|"g"|"kw"|"kt"|"pg"|"i"|"cc"|"mc"|"f"|"ft"|"l"|"c"|"o"|"dpi"|"fn"|"h"|"m"|"s"|"e"|"p"|"b"|"kb"|"w"|"t"|"wh"|"doc"
---@class OptionsCollection #Holds all options that can be set by the user
---@field mouseButtonCount? integer
---@field mouseModeConfig? ModeDefinition
---@field mouseModeCount? integer
---@field mouseShiftKey? integer
---@field mouseBindHardwareModes? boolean
---@field keyboardButtonCount? integer
---@field keyboardModeConfig? ModeDefinition
---@field keyboardModeCount? integer
---@field keyboardShiftKey? integer
---@field keyboardBindHardwareModes? boolean
---@field lhcButtonCount? integer
---@field lhcModeConfig? ModeDefinition
---@field lhcModeCount? integer
---@field lhcShiftKey? integer
---@field lhcBindHardwareModes? boolean
local defaultConfiguration = { ---Default values for the options specified in the logitech bindings, as a fallback
   stackOrder = {"custom", "mode", "shift"}, ---Determines in which order macros will be sorted into a group if they were originally defined in different places
   logPrimaryButtonState = true, ---Log primary mouse buttons, even when they are not triggering events.
   separateDeviceCycles = false, ---Determines if button presses on a device will impact the state of cycle macros on another device
   LCDPersistentProfile = false, ---Should the Profile information page be kept on the LCD display at all times? (This will interfere with other LCD apps)
   restrictToMainScreen = false, ---Ignore all screens besides the primary screen when it comes to mouse movement
   preventOptionOverride = true, ---Don't let subsequently loaded configurations override options defined in the current configuration
   LCDLastLinePagination = true, ---Reserve the last line on multi-page text displays for pagination
   lagPositionThreshold = 1000, ---Discrepancy in mouse position (in Logitech units) that will trigger lag countermeasures
   maxMovementLagSamples = 100, ---How many samples of mouse coordinates should be used to offset potential lag
   LCDHidePrimaryMode = false, ---@type boolean|"unnamed" #Don't show the designation of the primary mouse mode in the LCD profile header. set to "unnamed" to only hide it if it does not have a defined name.
   maxResolveIterations = 500,
   mergeDocumentation = true, ---Should profiles merge their documentation with that of their parent profiles?
   mergeScopeDefaults = true, ---Should profiles merge their scope defaults with that of their parent profiles?
   preventDocOverride = true, ---Don't let the contents of internal documentation definitions overwrite imported documentation
   LCDMessageDuration = 3000, ---How long to show messages on the LCD display by default (in milliseconds)
   offsetMovementLag = true, ---Should Revenant attempt to compensate for performance based lag in mouse movement macros?
   newLineAfterName = false, ---When documenting a key insert a newline between name and key description
   keyboardLocale = "de-DE", ---@type "de-DE"|"en-US"|"en-GB" #The Layout of your keyboard. currently supported are "de-DE", "en-US" and "en-GB"
   noMacroExtension = true, ---If there are any keybindings on a button, never merge them with parent bindings.
   monitors = {1920, 1080}, ---@type l<{[1]:integer,[2]:integer, main?:boolean}>|DeskoptDefinition|{[1]:integer,[2]:integer, main?:boolean}[] #Define the resolution and position of one or more monitors
   preventInheritance = {}, ---@type string[] #A list of macro names that can't be inherited by other macros
   abortOnLintError = true, ---Prevent Revenant from initializing profiles and macros if the linter detects problems with their configuration
   stackAutoReverse = true, ---Attempt to retain logical macro order in some questionable stack orders
   defaultModeTarget = nil, ---@type "join"|"self"? #Define if the globally defined modes will be applied to all devices
   LCDClearLastLine = true, ---Don't show text in the last line of the LCD display (to avoid the blue background)
   globalModeFamily = "kb", ---@type HardwareFamily #Set which family's M-key state should be used to track the global mode ("kb", "mouse" or "lhc")
   primaryButtons = false, ---Enable binding to mouse buttons 1 and 2 (unstable and not recommended)
   strictModifiers = true, ---exhaustive key checks, for example a macro that needs the shift key pressed will not activate if the control key is also pressed.
   enableDebounce = false, ---Attempt to identify and block suspiciously fast manual button presses (not really reliable)
   shiftSort = "standard", ---@type SortMode #The order in which macros grouped in shift states are sorted into a single group
   customStack = "append", ---@type StackMode #The direction in which macros defined in custom groups are stacked
   modeSort = "standard", ---@type  SortMode #The order in which macros grouped by modes are sorted into a single group
   shiftStack = "append", ---@type StackMode #The direction in which macros defined in shift based groups are stacked
   externalConfigs = {}, ---@type string|(string|OptionsCollection)[]? #define a path of an external configuration file, or an array of multiple paths, loaded in order.
   waitLagThreshold = 50, ---Minimum duration in milliseconds of a timing value to be relevant for  lag compensation
   offsetWaitLag = true, ---Attempt to compensate for performance caused lag when pausing between actions
   modeStack = "append", ---@type StackMode #The direction in which macros defined in mode based groups are stacked
   globalGShift = false, ---Count G-shift on one device as G-shift for all other devices as well
   keepNameOnLCD = true, ---Always show the profile header in the first line of the LCD display when text is displayed
   enableLinting = true, ---Always check if macros and configurations have the correct properties with the correct types for each property
   pollMKeysOnly = true, ---Reserve M keys for polling
   multiClickTime = 200, ---The standard interval used by multi click buttons to determine whether something is  a multi press
   maxLagSamples = 100, ---The maximum number of timing samples used to determine lag offset
   LCDSeparator = true, ---@type string|boolean #Define a separator to divide the LCD display between header line and text content. set to false to disable the separator, true to fill the line with "=" or provide a custom string to fill the line with.
   showCompiled = true, ---Log statistics about the profile into the LGS console after compiling
   defaultStacking = 1, ---The default stacking behavior of sequence macros when triggered multiple times. Set to 1 to cancel the current instance and start over, or 2 restart it after the instance has finished
   actionVariance = 0, ---randomize the timing between actions within a defined range of milliseconds.
   logDebounce = false, ---output a log message whenever Revenant has debounced a button
   LCDLineLength = 76, ---Unitless measurement of how much text fits into the LCD display. In the case of the LGS LCD emulator this amount depends on screen resolution and scaling setting, adjust if text overflows or cuts off to early.
   useHIDKeys = false,
   externalDocs = nil, ---@type l<string>? #Set a path to an external documentation file, or provide an array of multiple paths wich will be loaded in order
   fixedWaitLag = 0.0,
   pollFamily = "lhc", ---@type HardwareFamily #Define a device family used for polling. If pollMKeysOnly is set to "false", macros bound to the device will be ignored.
   defaultHold = 500, ---The default duration a holdKey macro needs to be held down to switch to the next action, in milliseconds
   logEvents = false, ---Log each key event that Revenant receives
   logMemory = false, ---Append a section showing memory usage to each event log entry
   pollInterval = 10, ---The number of milliseconds the script will wait between checking the state of new events and paused coroutines. Lower values make Revenant more responsive and action timings more precise, but are potentially more taxing performance wise.
   modeReset = true, ---Reset the mode all devices to 1, when a profile is loaded. Highly recommended.
   clearLog = false, ---Clear the LGS log output every time a new profile is loaded.
   devices = "G600", ---@type l<string|HardwareDefinition>? #The Name of your Logitech device as defined in HardwareDefinitions.lua, an array of names if multiple devices are used.
   description = "", ---A custom description of the profile which will be shown on the LCD display.
   outputLCD = true, ---Utilize the LCD display on a compatible logitech keyboard or the LGS LCD emulator
   globalModes = {}, ---@type ModeDefinition #Define a number of global modes for your profile. You can provide an array of numbers, strings acting as names of the different modes, or arrays in which the first element is the mode name and the second is a color value used for the device backlight. Compile relevant
   actionDelay = 10, ---The default duration of milliseconds to wait between subsequent action in sequence macros
   defaultShift = 2, -- The default G-shift condition in which macros will trigger. 0 means g-shift needs be inactive, 1 means only when active and 2 means macros will trigger regardless of g-shift. compile Relevant
   historyDepth = 2, ---How many past button presses should be kept in memory? Higher values are necessary for more complex "past button" conditions.
   keyVariance = 0, ---randomize the timing between pressing and releasing keys within a defined range of milliseconds.
   customSort = {}, ---@type string[] #If you have defined your bindings in custom groups, you can optionally control the order in which their macros will be parsed and executed by listing their names in your chosen order.
   defaultMode = 0, ---@type l<integer> #define in which mode macros will trigger by default. 1 for the first mode 2 for the second mode ... etc. Set to 0 to enable them in all modes. You can also provide an array of number to set a default trigger in multiple modes.
   LCDLines = 10, ---The number of lines your LCD display is capable of displaying at once.
   keyDelay = 10, ---The default duration to wait between pressing and releasing a key
   extends = "", ---@type l<string>? #Set a path to another external profile file that will be used as basis of the current profile. All macros on the parent profile will be retained except for the ones overwritten by the assignments of this profile. You can also provide an array of multiple paths wich will be loaded and combined in order. compile relevant
   rename = {}, ---@type table<string,string> #Remap key names to custom names, standard key names are m, k and l for mouse, keyboard and lhc respectively followed by their number according to LGS
   defaultKeys = { -- These keys, corresponding the windows default mouse bindings, will be mapped by default on every profile.
      m1 = {"/1", m = 0, g = 2, n = "m1"},
      m2 = {"/2", m = 0, g = 2, n = "m2"},
      m3 = {"/3", m = 0, g = 2, n = "m3"},
      m4 = {"/4", m = 0, g = 2},
      m5 = {"/5", m = 0, g = 2}
   },
   debounceSettings = {mouse = {{1, 30, "up"}, {2, 30, "up"}}} ---@type table<HardwareFamily,{[1]:number,[2]:number,[3]:"up"|"down"}[]> #Define debounce values for buttons of specific devices. The first entry in the array if the number of the key, the second a number of milliseconds and the third defines if "up" or "down" events should be monitored. Events that happen faster than the millisecond value won't trigger macros.
}

-- END OF USER CONFIG! DON'T MESS WITH THE INTERNAL LOGIC UNLESS YOU REALLY KNOW WHAT YOU'RE DOING!

local loadfile, xpcall, setmetatable, match, error, concat, pairs, ClearLCD, OutputLCDMessage = loadfile, xpcall, setmetatable, string.match, error, table.concat, pairs, ClearLCD, OutputLCDMessage
---@alias ClassName "MacroDefinition"|"KeyMacro"|"ProfileDefinition"|"MonitorDefinition"|"SimpleKeyMacro"

---The main class for the framework, exposing all modules and functions.
---@class Revenant
---@field profile ProfileDefinition
---@field put fun(...) #[Debug] Output one or more messages to the Logitech lua console.
---@field pipe fun(...:any):any #[Debug] output a value to console and then pipe it back out.
local rv = {
   states = {
      keyStates = {
         lastKeysDown = {}, ---@type (EventInfo[] | {family:string}) #list of last pressed keys
         keysDown = {}, ---@type EventInfo[] #list of currently pressed keys
         primaryButtonsDown = {}, ---@type table<string,boolean> #string indexed version of `stringPresets.LogitechKeyNames`
         logiKeys = {}, ---@type table<string,true> #mapping button names to their original names
         unRename = {}, ---@type table<string,string> #keys pressed during tasks
         taskDown = {} ---@type table<string,KeyObject[]>
      },
      scriptStates = { ---Basic Data about the script status
         locationIndicator = "Running on internal configs", ---Profile configuration status
         exitingScript = false, ---Is Revenant currently exiting?
         currentButton = 0, ---numeric ID of the currently pressed button
         version = "2.6b", ---version of Revenant
         docMode = false, ---Script currently in Documentation mode?
         keyCount = 0, ---Keeping track of how many buttons have been pressed
         errors = {}, ---@type string[] #Errors that have occurred during loading
         flags = {}, ---@type table<string,boolean|string> #Flags defined and toggled by Flag Macros
         mods = {} ---@type table<string,true> #Currently pressed modifier keys
      }
   },
   ---@class PresetCollection
   ---@field defaultConfig OptionsCollection
   presets = {
      stringPresets = { -- various string variables used across the framework
         determinants = {"gshift", "mode", "mkey", "condition", "area"}, -- trigger relevant macro properties
         internalPropsName = {"_scope", "pID", "name", "doc", "_meta"}, -- same as internalProps but includes "name"
         internalProps = {"_scope", "pID", "doc", "_meta"}, -- property names of metadata that won't be shown to the user
         families = {"mouse", "kb", "lhc"}, -- device families supported by LGS
         shortMapper = {}, ---@type table<string,string> #easier access to shorthand values via indexing
         optionDefaults = { -- Option fields mapped to macro defaults
            mode = "defaultMode",
            gshift = "defaultShift"
         },
         shorthands = { ---Shorthands for standard Macro property shorthands
            t = "type",
            m = "mode",
            n = "name",
            mk = "mkey",
            g = "gshift",
            b = "blocking",
            c = "condition",
            dir = "direction",
            doc = "documentation"
         }, ---all keys that can be pressed by LGS
         logitechKeyNames = {"tilde", "minus", "equal", "lbracket", "rbracket", "backslash", "capslock", "semicolon", "quote", "comma", "period", "slash", "escape", "enter", "tab", "spacebar", "up", "left", "down", "right", "backspace", "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24", "delete", "home", "insert", "pause", "pagedown", "pageup", "printscreen", "scrolllock", "appkey", "non_us_slash", "numlock", "end", "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7", "num8", "num9", "numslash", "numminus", "numplus", "numenter", "numperiod"},
         modKeys = {["*"] = "lctrl", ["|"] = "lgui", ["~"] = "lshift", ["#"] = "lalt"} ---single string shorthands for modifier keys in text
      }
   }
}

---@private
---Initialize the Revenant framework
---@param ... PathData
function rv:new(...)
   local o = {} ---@type Revenant
   self.__index = self ---@private
   setmetatable(o, self)
   o:constructor(...)
   return o
end

---Crash and display an error message
---@param msg? string #The message to output
function rv:crash(msg)
   local dummy = function() end ---dummy
   OnEvent = dummy
   ClearLCD()
   OutputLCDMessage("Revenant ERROR\ncheck scripting console.", -1)
   OutputLCDMessage("", -1) ---@type true[], string[]
   local test, res, errs = {}, {}, self.states.scriptStates.errors
   for i = 1, #errs do
      local err = errs[i]
      if not test[err] then res[#res + 1] = err end
      test[err] = true
   end
   error(((msg and msg .. "\n") or "") .. concat(res, "\n"), 10)
end

---Add an import error to the error array
---@param e string
---@param path string
local function _handleImportErrors(e, path) rv.states.scriptStates.errors[#rv.states.scriptStates.errors + 1] = "could not load file from path '" .. path .. ", Error:\n  \"" .. e .. "\"" end

---Utilities for importing files and classes
---@class ImportModule
---@field private rv Revenant
local ImportModule = {}
---@private
---Initialize the Import Mocule
---@param rev Revenant
function ImportModule:new(rev)
   local o = {} ---@type ImportModule
   self.__index = self ---@private
   setmetatable(o, self)
   o:constructor(rev)
   return o
end
---@protected
---@param rev Revenant
function ImportModule:constructor(rev)
   self.rv = rev
   self.macroImports = {} ---@type table<string,true>
   self.classMap = {} ---@type table<string, {[1]:string, [2]:string}>
   for i = 1, #macroTerms do
      local el = macroTerms[i]
      self.classMap[el[2]] = {el[1], el[2]}
      self.classMap[el[3]] = {el[1], el[2]}
   end -- dynamically initializing shorthand options
end

---Storing loaded classes to prevent double imports
local fileCache = {} ---@type table<string,{new:fun():any}>
---safely load an external lua file
---@param path string
---@param handler? fun(arg1:string,arg2:string)
---@return unknown? #Whatever comes back from the targeted file
function ImportModule:loadFile(path, handler)
   local code, ret = xpcall(function() return (loadfile(path) or error("No File/Syntax Error", 2))(self.rv) end, function(err) (handler or _handleImportErrors)(err, path) end) ---@type boolean,any
   if code then
      fileCache[path] = ret
      return ret
   end
end

---import and cache a class from an external lua file
---@param path string #The location of the file, relative to revenant directory
---@param handler? fun(str:string,str:string) #Custom Error handler
---@return any #the loaded class
function ImportModule:import(path, handler)
   local p = path:gsub("%.lua$", ""):gsub("$", ".lua")
   return fileCache[p] or self:loadFile(p, handler)
end

---import a class
---@generic T
---@param name `T` The name of the class
---@return T #The new instance
function ImportModule:classImport(name)
   local isMacro = match(name, "Macro$")
   if isMacro and name ~= "GroupMacro" then self.macroImports[name] = true end
   return self:import(self.rv.paths.path .. "/src/classes/" .. ((isMacro and "macros/") or "") .. name)
end

---@private
---The initializer function called in the LGS profile
---@param pathConfig PathData #Base configuration, see the example LGS template.
function rv:constructor(pathConfig)
   ClearLCD()
   self.presets.defaultConfig = defaultConfiguration
   self.paths = pathConfig
   ---table containing all imported classes
   for k, v in pairs(self.presets.stringPresets.shorthands) do self.presets.stringPresets.shortMapper[v] = k end
   local libPath = self.paths.path .. "/src/libraries/"
   local modulePath = self.paths.path .. "/src/modules/"
   self.importer = ImportModule:new(self)
   self.baseClass = self.importer:classImport("BaseClass")
   ---Load a class and immediately instantiate it.
   ---@generic T
   ---@param path string #Path to load the class from
   ---@param class `T` The name of the class
   ---@return T #The new instance
   local function instance(path, class) return (self.importer:import(path .. class) or {new = function() end}):new() end

   -- Here all Libraries and Modules are imported.
   -- >>> Libraries from around the net ===============================================================================--[[]]--

   self.utils = instance(libPath, "UtilityModule")
   self.threading = instance(modulePath, "ThreadingModule")
   self.tbl = instance(modulePath, "TableUtilitiesModule")
   -- >>> Other modules ===============================================================================

   self.utf8 = self.importer:import(libPath .. "utf8") ---@type UnicodeFunctions
   self.paths = self.tbl:intersectSimple(defaultPaths, self.paths, true)
   self.keys = instance(modulePath, "KeyOutputModule")
   self.utils.pprint = self.importer:import(libPath .. "inspect")
   self.mouseMonitorUtils = instance(modulePath, "MouseCoordinatesModule")
   self.logitech = instance(modulePath, "LogitechInterfaceModule")
   self.lcd = instance(modulePath, "DisplayStateModule")
   self.validator = instance(modulePath, "MacroValidatorModule")
   self.eventHandler = instance(modulePath, "EventHandlerModule")
   self.str = instance(modulePath, "StringUtilitiesModule")
   self.hardware = instance(modulePath, "HardwareModule")
   self.lint = instance(modulePath, "LintingModule")
   self.debouncer = instance(modulePath, "DebounceModule")
   if #self.states.scriptStates.errors ~= 0 then self:crash() end
end
return rv
