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
   configPath = "@rv/configs" ---Path to the general Revenant configuration, Hardware,Keyboard layouts, etc
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
   {"LinkMacro", "link", "l"}, --
   {"CycleMacro", "cycle", "c"}, --
   {"LogMacro", "log", "o"}, --
   {"DpiMacro", "setdpi", "dpi"}, --
   {"FunctionMacro", "func", "fn"}, --
   {"HoldKeyMacro", "holdkey", "h"}, --
   {"ModeChangeMacro", "mode", "m"}, --
   {"SequenceMacro", "sequence", "s"}, --
   {"ExternalMacro", "externalmacro", "e"}, --
   {"MousePositionMacro", "mouseposition", "p"}, --
   {"BackLightMacro", "backlight", "b"}, --
   {"KeyBufferMacro", "keybuffer", "kb"}, --
   {"MouseWheelMacro", "mousewheel", "w"}, --
   {"MultiClickMacro", "multiclick", "t"}, --
   {"WipeHistoryMacro", "wipehistory", "wh"}, --
   {"DocToggleMacro", "documentation", "doc"} --
}
---All macros currently supported by Revenant.
---@alias MacroType
---|"key" # Direct key binding, press the key(s) when the button is pressed, release when it's released
---|"keyup" # Release one or more keys
---|"keydown" # Press one or more keys without releasing them.
---|"sequence" # Run a string of key presses or other macros
---|"keytoggle" # Press one or more keys when this button is pressed, release them when it's pressed again.
---|"instance"
---|"cyclecontrol" # Set the position or cycle number of a cycle macro
---|"macrocontrol"
---|"flag" # Set or toggle an internal flag for use in macro conditions.
--- Run another macro by referencing it by name.
---
--- Example:
---```lua
--- --Linked button
--- b.m5 = {"A key", type="link"}
---
--- -- target macro which will run when the link is triggered
--- b.m3 = {"a", t="k", name="A key"}
---
---```
---<br>
---|"link"
---|"wrapkey" # Assign a key that will be held down together with the next key that is pressed
---|"cycle" # cycle between multiple keys or macros.
---|"log" # Log a message to the console and LCD screen (if available)
---Set the DPI table of your mouse.
---
---Example:
---```lua
--- -- Set the DPI setting to the second position of your profile's current DPI table.
--- k.m3 = { 2, type="setdpi" }
---
--- -- Set a new DPI table for the current profile, set index to the second position
--- k.m4 = { {500,1000,2000}, 2,  type="setdpi" }
---
--- -- Set the DPI of your mouse directly to 3000 DPI.
--- -- This will disable previously set DPI tables, so it's advised to either only use direct assignments or only table/index assignments.
--- k.m5 = { 3000, type="setdpi", direct= true }
--- ```
---|"setdpi"
---|"holdkey" # Play a different key or macro depending on how long you hold down the button
---|"mode" # Set your mouse to a specific mode
---|"externalmacro" #Play a macro defined in the LGS GUI
---|"func" #Execute a lua function
---|"mouseposition"# Change the position of your mouse, instantly or over time
---|"backlight" # Change the backlight color of your device
---|"keybuffer" #Add a string to a buffer that will be typed out before the next proper key press
---|"mousewheel"
---|"multiclick"
---|"wipehistory" # Erase the history of pressed buttons fully or partially.
---|"documentation" # Enter the documentation mode which outputs information about this profile's macros on the lua console and your LCD screen, if available.
---|"page" # Control which page is displayed on your LCD display.
---|"group" # Designate a group of macros. Groups are also defined implicitly, you probably won't need this type.
---@alias MacroShortType "k"|"u"|"d"|"g"|"kw"|"kt"|"pg"|"i"|"cc"|"mc"|"f"|"ft"|"l"|"c"|"o"|"dpi"|"fn"|"h"|"m"|"s"|"e"|"p"|"b"|"kb"|"w"|"t"|"wh"|"doc"
---@type InternalOptions
local defaultConfiguration = { ---Default values for the options specified in the logitech bindings, as a fallback
   stackOrder = {"custom", "mode", "shift"}, ---Determines in which order macros will be sorted into a group if they were originally defined in different places
   separateDeviceThreads = false, ---Determines if button presses on a device will impact the state of continuous macros on another device
   defaultThreadInterrupt = true, ---Determines if starting a continuous macro cancels other playing continuous macros by default
   movementLagStepThreshold = 20, ---Minimum number of movement steps required to make a mouse movement relevant for lag offset calculations.
   logPrimaryButtonState = true, ---Log primary mouse buttons, even when they are not triggering events.
   separateDeviceCycles = false, ---Determines if button presses on a device will impact the state of cycle macros on another device
   LCDPersistentProfile = false, ---Should the Profile information page be kept on the LCD display at all times? (This will interfere with other LCD apps)
   preventOptionOverride = true, ---Don't let subsequently loaded configurations override options defined in the current configuration
   LCDLastLinePagination = true, ---Reserve the last line on multi-page text displays for pagination
   lagPositionThreshold = 1000, ---Discrepancy in mouse position (in Logitech units) that will trigger lag countermeasures
   maxMovementLagSamples = 100, ---How many samples of mouse coordinates should be used to offset potential lag
   restrictToMainScreen = true, ---Ignore all screens besides the primary screen when it comes to mouse movement
   defaultThreadCancel = true, ---Determines if Sequences are cancelled when another button is pressed by default
   LCDHidePrimaryMode = false, ---@type boolean|"unnamed" #Don't show the designation of the primary mouse mode in the LCD profile header. set to "unnamed" to only hide it if it does not have a defined name.
   maxResolveIterations = 500,
   preventDocOverride = false, ---Don't let the contents of internal documentation definitions overwrite imported documentation
   mergeDocumentation = true, ---Should profiles merge their documentation with that of their parent profiles?
   mergeScopeDefaults = true, ---Should profiles merge their scope defaults with that of their parent profiles?
   LCDMessageDuration = 3000, ---How long to show messages on the LCD display by default (in milliseconds)
   reverseRelativeAxis = true, --- Reverse the Y axis of relative movement, so that 400px means 400px upwards and "-10%" means 10% down.
   offsetMovementLag = true, ---Should Revenant attempt to compensate for performance based lag in mouse movement macros?
   newLineAfterName = false, ---When documenting a key insert a newline between name and key description
   keyboardLocale = "de-DE", ---@type "de-DE"|"en-US"|"en-GB" #The Layout of your keyboard. currently supported are "de-DE", "en-US" and "en-GB"
   noMacroExtension = true, ---If there are any keybindings on a button, never merge them with parent bindings.
   monitors = {1920, 1080}, ---Define the resolution and position of one or more monitors
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
   defaultLagFactor = 1, ---The Lag factor to assume as a default when loading a profile.
   LCDSeparator = true, ---@type string|boolean #Define a separator to divide the LCD display between header line and text content. set to false to disable the separator, true to fill the line with "=" or provide a custom string to fill the line with.
   showCompiled = true, ---Log statistics about the profile into the LGS console after compiling
   defaultStacking = 1, ---The default stacking behavior of sequence macros when triggered multiple times. Set to 1 to cancel the current instance and start over, or 2 restart it after the instance has finished
   actionVariance = 0, ---randomize the timing between actions within a defined range of milliseconds.
   logDebounce = false, ---output a log message whenever Revenant has debounced a button
   LCDLineLength = 76, ---Unitless measurement of how much text fits into the LCD display. In the case of the LGS LCD emulator this amount depends on screen resolution and scaling setting, adjust if text overflows or cuts off to early.
   useHIDKeys = false,
   externalDocs = nil, ---Set a path to an external documentation file, or provide an array of multiple paths wich will be loaded in order
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
   globalModes = {}, ---Define a number of global modes for your profile. You can provide an array of numbers, strings acting as names of the different modes, or arrays in which the first element is the mode name and the second is a color value used for the device backlight. Compile relevant
   actionDelay = 10, ---The default duration of milliseconds to wait between subsequent action in sequence macros
   defaultShift = 2, -- The default G-shift condition in which macros will trigger. 0 means g-shift needs be inactive, 1 means only when active and 2 means macros will trigger regardless of g-shift. compile Relevant
   historyDepth = 5, ---How many past button presses should be kept in memory? Higher values are necessary for more complex "past button" conditions.
   keyVariance = 0, ---randomize the timing between pressing and releasing keys within a defined range of milliseconds.
   customSort = {}, ---@type string[] #If you have defined your bindings in custom groups, you can optionally control the order in which their macros will be parsed and executed by listing their names in your chosen order.
   defaultMode = 0, ---@type l<integer> #define in which mode macros will trigger by default. 1 for the first mode 2 for the second mode ... etc. Set to 0 to enable them in all modes. You can also provide an array of number to set a default trigger in multiple modes.
   LCDLines = 10, ---The number of lines your LCD display is capable of displaying at once.
   keyDelay = 10, ---The default duration to wait between pressing and releasing a key
   extends = "", ---Set a path to another external profile file that will be used as basis of the current profile. All macros on the parent profile will be retained except for the ones overwritten by the assignments of this profile. You can also provide an array of multiple paths wich will be loaded and combined in order. compile relevant
   rename = {}, ---@type table<string,string> #Remap key names to custom names, standard key names are m, k and l for mouse, keyboard and lhc respectively followed by their number according to LGS
   defaultKeys = { -- These keys, corresponding the windows default mouse bindings, will be mapped by default on every profile.
      m1 = {"/1", m = 0, g = 2, n = "m1"},
      m2 = {"/2", m = 0, g = 2, n = "m2"},
      m3 = {"/3", m = 0, g = 2, n = "m3"},
      m4 = {"/4", m = 0, g = 2},
      m5 = {"/5", m = 0, g = 2}
   },
   debounceSettings = {mouse = {{1, 30, "up"}, {2, 30, "up"}}} ---@type table<HardwareFamily,{[1]:integer,[2]:integer,[3]:"up"|"down"}[]> #Define debounce values for buttons of specific devices. The first entry in the array if the number of the key, the second a number of milliseconds and the third defines if "up" or "down" events should be monitored. Events that happen faster than the millisecond value won't trigger macros.
}

-- END OF USER CONFIG! DON'T MESS WITH THE INTERNAL LOGIC UNLESS YOU REALLY KNOW WHAT YOU'RE DOING!

local loadfile, xpcall, setmetatable, error, concat, pairs, ClearLCD, OutputLCDMessage = loadfile, xpcall, setmetatable, error, table.concat, pairs, ClearLCD, OutputLCDMessage
---@alias ClassName "MacroDefinition"|"KeyMacro"|"ProfileDefinition"|"MonitorDefinition"|"SimpleKeyMacro"

---The main class for the framework, exposing all modules and functions.
---@class (exact)Revenant
---@field presets PresetCollection
---@field profile ProfileDefinition
---@field states StateCollection
---@field paths PathData
---@field importer ImportModule
---@field private __index any
---@field tbl TableUtilitiesModule
---@field baseClass BaseClass
---@field threading ThreadingModule
---@field utils UtilityModule
---@field utf8 UnicodeFunctions
---@field keys KeyOutputModule
---@field mouseMonitorUtils MouseCoordinatesModule
---@field logitech LogitechInterfaceModule
---@field lcd DisplayStateModule
---@field lint LintingModule
---@field validator MacroValidatorModule
---@field str StringUtilitiesModule
---@field hardware HardwareModule
---@field debouncer DebounceModule
---@field eventHandler EventHandlerModule
---@field put fun(...) #[Debug] Output one or more messages to the Logitech lua console.
---@field pipe fun(...:any):any #[Debug] output a value to console and then pipe it back out.
local rv = {
   ---@class StateCollection
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
   ---@field defaultConfig InternalOptions
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
         macroTerms = macroTerms, ---@type {[1]:string,[2]:string,[3]:string}[]
         logitechKeyNames = {"tilde", "minus", "equal", "lbracket", "rbracket", "backslash", "capslock", "semicolon", "quote", "comma", "period", "slash", "escape", "enter", "tab", "spacebar", "up", "left", "down", "right", "backspace", "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24", "delete", "home", "insert", "pause", "pagedown", "pageup", "printscreen", "scrolllock", "appkey", "non_us_slash", "numlock", "end", "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7", "num8", "num9", "numslash", "numminus", "numplus", "numenter", "numperiod"},
         ---A list of special key names supported by logitech.
         ---@alias LogiKeyName "tilde"|"minus"|"equal"|"lbracket"|"rbracket"|"backslash"|"capslock"|"semicolon"|"quote"|"comma"|"period"|"slash"|"escape"|"enter"|"tab"|"spacebar"|"up"|"left"|"down"|"right"|"backspace"|"lshift"|"rshift"|"lctrl"|"rctrl"|"lalt"|"ralt"|"lgui"|"rgui"|"f1"|"f2"|"f3"|"f4"|"f5"|"f6"|"f7"|"f8"|"f9"|"f10"|"f11"|"f12"|"f13"|"f14"|"f15"|"f16"|"f17"|"f18"|"f19"|"f20"|"f21"|"f22"|"f23"|"f24"|"delete"|"home"|"insert"|"pause"|"pagedown"|"pageup"|"printscreen"|"scrolllock"|"appkey"|"non_us_slash"|"numlock"|"end"|"num0"|"num1"|"num2"|"num3"|"num4"|"num5"|"num6"|"num7"|"num8"|"num9"|"numslash"|"numminus"|"numplus"|"numenter"|"numperiod"
         modKeys = {["*"] = "lctrl", ["|"] = "lgui", ["~"] = "lshift", ["#"] = "lalt"} ---single string shorthands for modifier keys in text
      }
   }
}

---@private
---Initialize the Revenant framework
---@param paths PathData
function rv:new(paths)
   ---@diagnostic disable-next-line: missing-fields
   local o = ({} --[[@as Revenant]] )
   self.__index = self ---@private
   setmetatable(o, self)
   o:constructor(paths)
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

---@private
---The initializer function called in the LGS profile
---@param pathConfig PathData #Base configuration, see the example LGS template.
function rv:constructor(pathConfig)
   ClearLCD()
   self.presets.defaultConfig = defaultConfiguration
   self.paths = pathConfig
   ---table containing all imported classes
   for k, v in pairs(self.presets.stringPresets.shorthands) do self.presets.stringPresets.shortMapper[v] = k end
   local libPath = "@rv/src/libraries/"
   local modulePath = "@rv/src/modules/"
   local _, metaImport = xpcall(loadfile(self.paths.path .. "/src/modules/ImportModule.lua") --[[@as fun():ImportModule]] , function() error("Could not import the import module. While ironic, this means something is very wrong your Revenant setup.") end)
   self.importer = metaImport:new(self)
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
