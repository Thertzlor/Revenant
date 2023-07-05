---@type OptionsCollection
local config = {

   --[[=============================================================]] --
   -- General Profile Configuration
   --[[=============================================================]] --

   defaultMode = 1, ---define in which mode macros will trigger by default. 1 for the first mode 2 for the second mode ... etc. Set to 0 to enable them in all modes. You can also provide an array of number to set a default trigger in multiple modes.
   defaultShift = 0, -- The default G-shift condition in which macros will trigger. 0 means g-shift needs be inactive, 1 means only when active and 2 means macros will trigger regardless of g-shift.
   globalModes = {}, ---Define a number of global modes for your profile. You can provide an array of numbers, strings acting as names of the different modes, or arrays in which the first element is the mode name and the second is a color value used for the device backlight.
   globalGShift = true, ---count G-shift on one device as G-shift for all other devices as well
   defaultStacking = 1, ---The default stacking behavior of sequence of macros when triggered multiple times. Set to 1 to cancel the macro and start over, or 2 restart it after the it has finished running
   historyDepth = 2, ---How many past button presses should be kept in memory? Higher values are neccessary for more complex "past button" conditions.
   description = "", ---A custom description of the profile which will be shown on the LCD display.
   extends = nil, ---Set a path to another external profile file that will be used as basis of the current profile. All macros on the parent profile will be retained except for the ones overwritten by the assignments of this profile. You can also provide an array of multiple paths wich will be loaded and combined in order.
   externalConfigs = nil, ---define a path of an external configuration file, or an array of multiple paths, loaded and combined in order.
   externalDocs = nil, ---Set a path to an external documentation file, or provide an array of multiple paths

   --[[=============================================================]] --
   -- Timing Configurations
   --[[=============================================================]] --

   actionDelay = 2, ---The default duration of milliseconds to wait between subsequent action in sequence macros
   keyDelay = 2, ---The default duration to wait between pressing and releasing a key
   multiClickTime = 200, ---The standard interval used by multi click buttons to determine whether something is  a multi press
   defaultHold = 500, ---The default duration a holdKey macro needs to be held down to switch to the next action, in milliseconds
   actionVariance = 0, ---randomize the timing between actions within a defined range of milliseconds.
   keyVariance = 0, ---randomize the timing between pressing and releasing keys within a defined range of milliseconds.

   --[[=============================================================]] --
   -- Hardware configuration
   --[[=============================================================]] --

   devices = "G600", ---The Name of your Logitech device as defined in HardwareDefinitions.lua, an array of names if multiple devices are used.
   keyboardLocale = "de-DE", ---The Layout of your keyboard. currently supported are "de-DE", "en-US" and "en-GB"
   separateDeviceCycles = false, ---Determines if button presses on a device will impact the state of cycle macros on another device
   defaultModeTarget = nil, ---Define if the globally defined modes will be applied to all devices "join" or the current device "self"
   defaultKeys = { -- These keys, corresponding the windows default mouse bindings, will be mapped by default on every profile.
      m3 = {"/3", m = 0, g = 2},
      m4 = {"/4", m = 0, g = 2},
      m5 = {"/5", m = 0, g = 2}
   },
   rename = { ---Remap key names to custom names, standard key names are m, k and l for mouse, keyboard and lhc respectively followed by their number according to LGS
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
   globalModeFamily = "kb", ---Set which family's M-key state should be used to track the global mode ("kb", "mouse" or "lhc")
   primaryButtons = false, ---Enable binding to mouse buttons 1 and 2 (unstable and not recommended)
   logPrimaryButtonState = true, ---Log primary mouse buttons, even when they are not triggering events.
   modeReset = true, ---Reset the mode all devices to 1, when a profile is loaded. Highly recommended.
   strictModifiers = true, ---if true, modifier key checks are exhaustive, for example a macro that needs the shift key pressed will not activate if the control key is also pressed.
   useHIDKeys = false, ---uses the PressHidKey and ReleaseHidKey functions instead of the normal PressKey and ReleaseKey functions. Honestly no idea what difference this makes.

   --[[=============================================================]] --
   -- Screen configuration [Needed only for mouse movement macros]
   --[[=============================================================]] --

   monitors = {{3840, 2160, main = true}}, ---Define the resolution and position of one or more monitors
   restrictToMainScreen = true, ---Ignore all screens besides the primary screen when calculating mouse position

   --[[=============================================================]] --
   -- Polling Configuration [Only change in case of performance issues]
   --[[=============================================================]] --

   pollInterval = 1, ---The number of milliseconds the script will wait between checking the state of new events and paused coroutines. Lower values make Revenant more responsive and action timings more precise, but are potentially more taxing performance wise.
   pollFamily = "lhc", ---Define a device family used for polling. If pollMKeysOnly is set to "false", macros bound to the device will be ignored.
   pollMKeysOnly = true, ---Reserve M keys for polling

   --[[=============================================================]] --
   -- LCD Configuration
   --[[=============================================================]] --

   outputLCD = true, ---Utilize the LCD display on a compatible logitech keyboard or the LGS LCD emulator
   LCDLines = 10, ---The number of lines your LCD display is capable of displaying at once.
   LCDLineLength = 76, ---Unitless measurement of how much text fits into the LCD display. In the case of the LGS LCD emulator this amount depends on screen resolution and scaling setting, adjust if text overflows or cuts off to early.
   LCDMessageDuration = 3000, ---How long to show messages on the LCD display by default (in milliseconds)
   LCDPersistentProfile = true, ---Should the Profile information page be kept on the LCD display at all times? (This will interfere with other LCD apps)
   keepNameOnLCD = true, ---Always show the profile header in the first line of the LCD display when text is displayed
   LCDSeparator = true, ---Define a separator to divide the LCD display between header line and text content. set to false to disable the separator, true to fill the line with "=" or provide a custom string to fill the line with.
   LCDHidePrimaryMode = "unnamed", ---Don't show the designation of the primary mouse mode in the LCD profile header. set to "unnamed" to only hide it if it does not have a defined name.
   LCDLastLinePagination = true, ---Reserve the last line on multi-page text displays for pagination
   LCDClearLastLine = true, ---Don't show non-pagination text in the last line of the LCD display (to avoid the blue background)

   --[[=============================================================]] --
   --[[=============================================================]] --
   -- EVERYTHING BELOW THIS LINE IS FAIRLY TECHNICAL!
   -- DON'T CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
   --[[=============================================================]] --
   --[[=============================================================]] --

   --[[========================================================================================]] --
   -- Advanced Profile Inheritance Configuration
   --[[========================================================================================]] --

   preventDocOverride = true, ---Don't let the contents of internal documentation definitions overwrite imported documentation
   preventOptionOverride = true, ---Don't let subsequently loaded configurations override options defined in the current configuration
   mergeDocumentation = true, ---Should profiles merge their documentation with that of their parent profiles?
   mergeScopeDefaults = true, ---Should profiles merge their scope defaults with that of their parent profiles?
   preventInheritance = {}, ---A list of macro names that can't be inherited by other macros

   --[[========================================================================================]] --
   -- Debug logging settings
   --[[========================================================================================]] --

   logEvents = false, ---Log each key event that Revenant receives
   logMemory = false, ---Append a section showing memory usage to each event log entry
   logDebounce = false, ---output a log message whenever Revenant has debounced a button
   showCompiled = false, ---Log statistics about the profile into the LGS console after compiling
   clearLog = true, ---Clear the LGS log output every time a new profile is loaded.

   --[[=============================================================]] --
   -- Flex Syntax and Inheritance Configuration
   --[[=============================================================]] --

   modeStack = "append", -- The direction in which macros defined in mode based groups are stacked. "append" or "prepend"
   shiftStack = "append", ---The direction in which macros defined in shift based groups are stacked. "append" or "prepend"
   customStack = "append", ---The direction in which macros defined in custom groups are stacked.  "append" or "prepend"
   modeSort = "standard", ---The order in which macros grouped by modes are sorted into a single group. "standard", "reverse" or an numerical order
   shiftSort = "standard", ---The order in which macros grouped by shift states are sorted into groups. "standard", "reverse" or an numerical order
   customSort = {}, ---If you have defined your bindings in custom groups, you can optionally control the order in which their macros will be parsed and executed by listing their names in your chosen order.
   stackOrder = {"custom", "mode", "shift"}, ---Determines in which order macros will be sorted into a group if they were originally defined in different places
   stackAutoReverse = true, ---Attempt to retain logical macro order in some questionable stack orders

   --[[========================================================================================]] --
   -- Linter [turning these off might cause you to lose control of your mouse because of typos]
   --[[========================================================================================]] --

   enableLinting = true, ---Always check if macros and configurations have the correct properties with the correct types for each property
   abortOnLintError = true, ---Prevent Revenant from initializing profiles and macros if the linter detects problems with their configuration

   --[[=====================================================================================]] --
   -- Lag Offset [probably only needs changed for very bad/old computers]
   --[[=====================================================================================]] --

   offsetMovementLag = true, ---Should Revenant attempt to compensate for performance based lag in mouse movement macros?
   offsetWaitLag = true, ---attempt to compensate for performance caused lag when pausing between actions
   maxLagSamples = 100, ---The maximum number of timing samples used to determine lag offset
   waitLagThreshold = 50, ---minimum duration in milliseconds of a timing value to be relevant for  lag compensation
   lagPositionThreshold = 1000, ---Discrepancy in mouse position (in Logitech units) that will trigger lag countermeasures
   maxMovementLagSamples = 100, ---How many samples of mouse coordinates should be used to offset potential lag

   --[[=====================================================================================]] --
   -- Debounce Setting [Designed to offset hardware faults, but is not very reliable]
   --[[=====================================================================================]] --

   enableDebounce = false, ---Attempt to identify and block suspiciously fast manual button presses (not really reliable)
   debounceSettings = { ---Define debounce values for buttons of specific devices. The first entry in the array if the number of the key, the second a number of milliseconds and the third defines if "up" or "down" events should be monitored. Events that happen faster than the millisecond value won't trigger macros.
      mouse = {{1, 30, "up"}, {2, 30, "up"}}
   }
}
return config
