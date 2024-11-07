local rv = ... ---@type Revenant
local type, gsub, next = type, string.gsub, next
---@class (exact) OptionsCollection #Holds all options that can be set by the user
---@field mouseButtonCount? integer
---@field mouseModeConfig? ModeDefinition
---@field mouseModeCount? integer
---@field monitors? DeskoptDefinition[]|DeskoptDefinition #Define the resolution and position of one or more monitors
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
---@field stackOrder? ("custom"|"mode"|"shift")[] #Determines in which order macros will be sorted into a group if they were originally defined in different places
---@field separateDeviceThreads? boolean #Determines if button presses on a device will impact the state of continuous macros on another device
---@field defaultThreadInterrupt? boolean|"exclusive"|"exclusivePause" #Determines if starting a continuous macro cancels other playing continuous macros by default
---@field logPrimaryButtonState? boolean #Log primary mouse buttons, even when they are not triggering events.
---@field separateDeviceCycles? boolean #Determines if button presses on a device will impact the state of cycle macros on another device
---@field LCDPersistentProfile? boolean #Should the Profile information page be kept on the LCD display at all times? (This will interfere with other LCD apps)
---@field restrictToMainScreen? boolean #Ignore all screens besides the primary screen when it comes to mouse movement
---@field preventOptionOverride? boolean #Don't let subsequently loaded configurations override options defined in the current configuration
---@field LCDLastLinePagination? boolean #Reserve the last line on multi-page text displays for pagination
---@field lagPositionThreshold? integer #Discrepancy in mouse position (in normalized Logitech units) that will trigger lag countermeasures
---@field maxMovementLagSamples? integer #How many samples of mouse coordinates should be used to offset potential lag
---@field defaultThreadCancel? boolean #Determines if Sequences are cancelled when another button is pressed by default.
---@field LCDHidePrimaryMode? boolean|"unnamed" #Don't show the designation of the primary mouse mode in the LCD profile header. set to "unnamed" to only hide it if it does not have a defined name.
---@field maxResolveIterations? integer
---@field mergeDocumentation? boolean #Should profiles merge their documentation with that of their parent profiles?
---@field movementLagStepThreshold? number #Minimum number of movement steps required to make a mouse movement relevant for lag offset calculations.
---@field mergeScopeDefaults? boolean #Should profiles merge their scope defaults with that of their parent profiles?
---@field preventDocOverride? boolean #Don't let the contents of internal documentation definitions overwrite imported documentation
---@field LCDMessageDuration? integer #How long to show messages on the LCD display by default (in milliseconds)
---@field offsetMovementLag? boolean #Should Revenant attempt to compensate for performance based lag in mouse movement macros?
---@field newLineAfterName? boolean #When documenting a key insert a newline between name and key description
---@field keyboardLocale? "de-DE"|"en-US"|"en-GB" #The Layout of your keyboard. currently supported are "de-DE", "en-US" and "en-GB".
---@field noMacroExtension? boolean #If there are any keybindings on a button, never merge them with parent bindings.
---@field preventInheritance? string[] #A list of macro names that can't be inherited by other macros
---@field abortOnLintError? boolean #Prevent Revenant from initializing profiles and macros if the linter detects problems with their configuration
---@field stackAutoReverse? boolean #Attempt to retain logical macro order in some questionable stack orders
---@field defaultModeTarget? "join"|"self" #Define if the globally defined modes will be applied to all devices
---@field LCDClearLastLine? boolean #Don't show text in the last line of the LCD display (to avoid the blue background)
---@field globalModeFamily? HardwareFamily #Set which family's M-key state should be used to track the global mode ("kb", "mouse" or "lhc")
---@field primaryButtons? boolean #Enable binding to mouse buttons 1 and 2 (unstable and not recommended)
---@field strictModifiers? boolean #exhaustive key checks, for example a macro that needs the shift key pressed will not activate if the control key is also pressed.
---@field enableDebounce? boolean #Attempt to identify and block suspiciously fast manual button presses (not really reliable)
---@field shiftSort?  SortMode #The order in which macros grouped in shift states are sorted into a single group
---@field customStack? StackMode #The direction in which macros defined in custom groups are stacked
---@field modeSort? SortMode #The order in which macros grouped by modes are sorted into a single group
---@field shiftStack? StackMode #The direction in which macros defined in shift based groups are stacked
---@field externalConfigs? string|(string|OptionsCollection)[]? #define a path of an external configuration file, or an array of multiple paths, loaded in order.
---@field waitLagThreshold? integer #Minimum duration in milliseconds of a timing value to be relevant for  lag compensation
---@field defaultKeys? table<string,table> #These keys, corresponding the windows default mouse bindings, will be mapped by default on every profile.
---@field offsetWaitLag? boolean #Attempt to compensate for performance caused lag when pausing between actions
---@field modeStack? StackMode #The direction in which macros defined in mode based groups are stacked
---@field globalGShift? boolean #Count G-shift on one device as G-shift for all other devices as well.
---@field keepNameOnLCD? boolean #Always show the profile header in the first line of the LCD display when text is displayed.
---@field enableLinting? boolean #Always check if macros and configurations have the correct properties with the correct types for each property
---@field pollMKeysOnly? boolean #Reserve M keys for polling
---@field multiClickTime? integer #The standard interval used by multi click buttons to determine whether something is  a multi press
---@field maxLagSamples? integer #The maximum number of timing samples used to determine lag offset
---@field defaultLagFactor? integer #The Lag factor to assume as a default when loading a profile.
---@field LCDSeparator? boolean|string #Define a separator to divide the LCD display between header line and text content. set to false to disable the separator, true to fill the line with "=" or provide a custom string to fill the line with.
---@field showCompiled? boolean #Log statistics about the profile into the LGS console after compiling
---@field defaultStacking? integer #The default stacking behavior of sequence macros when triggered multiple times. Set to 1 to cancel the current instance and start over, or 2 restart it after the instance has finished
---@field actionVariance? integer #randomize the timing between actions within a defined range of milliseconds.
---@field logDebounce? boolean #output a log message whenever Revenant has debounced a button
---@field LCDLineLength? integer #Unitless measurement of how much text fits into the LCD display. In the case of the LGS LCD emulator this amount depends on screen resolution and scaling setting, adjust if text overflows or cuts off to early.
---@field useHIDKeys? boolean
---@field externalDocs? string|string[] #Set a path to an external documentation file, or provide an array of multiple paths wich will be loaded in order
---@field fixedWaitLag? number
---@field pollFamily? HardwareFamily #Define a device family used for polling. If pollMKeysOnly is set to "false", macros bound to the device will be ignored.
---@field defaultHold? integer #The default duration a holdKey macro needs to be held down to switch to the next action, in milliseconds
---@field logEvents? boolean #Log each key event that Revenant receives
---@field logMemory? boolean #Append a section showing memory usage to each event log entry
---@field pollInterval? integer #The number of milliseconds the script will wait between checking the state of new events and paused coroutines. Lower values make Revenant more responsive and action timings more precise, but are potentially more taxing performance wise.
---@field modeReset? boolean #Reset the mode all devices to 1, when a profile is loaded. Highly recommended.
---@field clearLog? boolean #Clear the LGS log output every time a new profile is loaded.
---@field devices? l<string|HardwareDefinition>? #The Name of your Logitech device as defined in HardwareDefinitions.lua, an array of names if multiple devices are used.
---@field description? string #A custom description of the profile which will be shown on the LCD display.
---@field outputLCD? boolean #Utilize the LCD display on a compatible logitech keyboard or the LGS LCD emulator.
---@field globalModes? ModeDefinition #Define a number of global modes for your profile. You can provide an array of numbers, strings acting as names of the different modes, or arrays in which the first element is the mode name and the second is a color value used for the device backlight.
---@field actionDelay? integer #The default duration of milliseconds to wait between subsequent action in sequence macros
---@field defaultShift? integer #The default G-shift condition in which macros will trigger. 0 means g-shift needs be inactive, 1 means only when active and 2 means macros will trigger regardless of g-shift. compile Relevant
---@field historyDepth? integer #How many past button presses should be kept in memory? Higher values are necessary for more complex "past button" conditions.
---@field keyVariance? integer #randomize the timing between pressing and releasing keys within a defined range of milliseconds.
---@field customSort? string[] #If you have defined your bindings in custom groups, you can optionally control the order in which their macros will be parsed and executed by listing their names in your chosen order.
---@field defaultMode? integer|integer[] #define in which mode macros will trigger by default. 1 for the first mode 2 for the second mode ... etc. Set to 0 to enable them in all modes. You can also provide an array of number to set a default trigger in multiple modes.
---@field LCDLines? integer #The number of lines your LCD display is capable of displaying at once.
---@field keyDelay? integer #The default duration to wait between pressing and releasing a key
---@field extends? string|string[] #Set a path to another external profile file that will be used as basis of the current profile. All macros on the parent profile will be retained except for the ones overwritten by the assignments of this profile. You can also provide an array of multiple paths wich will be loaded and combined in order. compile relevant
---@field rename? table<string,string> #Remap key names to custom names, standard key names are m, k and l for mouse, keyboard and lhc respectively followed by their number according to LGS
---@field debounceSettings? table<HardwareFamily,{[1]:integer,[2]:integer,[3]:"up"|"down"}[]> #Define debounce values for buttons of specific devices. The first entry in the array if the number of the key, the second a number of milliseconds and the third defines if "up" or "down" events should be monitored. Events that happen faster than the millisecond value won't trigger macros.
--[[=============================================================]] --
---Options Collection with fields pre-filled with default values.
---@class InternalOptions:OptionsCollection
---@field fixedWaitLag number
---@field debounceSettings table<HardwareFamily,{[1]:integer,[2]:integer,[3]:"up"|"down"}[]>
---@field defaultShift integer
---@field pollInterval integer
---@field offsetWaitLag boolean
---@field defaultMode integer|integer[]
--[[=============================================================]] --
---A class for loading and containing the Revenant configuration of a profile
---@class (exact) ConfigDefinition:BaseClass
---@field new fun(self:self,baseData:OptionsCollection|string,stack:string[]|nil,basePath:string,isFinal?:boolean)
---@field finalConfig OptionsCollection #Final output once all potential parent configs have been loaded and merged
---@field private base OptionsCollection #Content of the current Options object
---@field private parents OptionsCollection[] #All parent profiles loaded before the current one
---@field private final? boolean #true if this is the top options object loaded by the profile.
---@field private external boolean #Does this definition originate in an external file?
---@field private stack string[] #list of parent configs
---@field private lintPreset OptionsLintPreset #list of parent configs
local ConfigDefinition = rv.baseClass:new()

ConfigDefinition.lintPreset = { ---Type definitions for all Revenant options
   modeSort = {type = {"string", "table"}, values = {"reverse", "standard"}, tableKeys = "number", tableTypes = {"string", "number"}},
   shiftSort = {type = {"string", "table"}, values = {"reverse", "standard"}, tableKeys = "number", tableTypes = "number"},
   defaultThreadInterrupt = {type = {"boolean", "string"}, values = {"exclusive", "exclusivePause"}},
   keyboardModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   mouseModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   lhcModeConfig = {type = "table", tableKeys = "number", tableTypes = {"string", "table"}},
   defaultKeys = {type = "table", tableKeys = "string", tableTypes = {"string", "table"}},
   extends = {type = {"table", "string"}, tableKeys = "number", tableTypes = "string"},
   devices = {type = {"string", "table"}, tableKeys = "number", tableTypes = "string"},
   preventInheritance = {type = "table", tableKeys = "number", tableTypes = "string"},
   debounceSettings = {type = "table", tableKeys = "string", tableTypes = "table"},
   customSort = {type = "table", tableKeys = "number", tableTypes = "string"},
   keyboardLocale = {type = "string", values = {"de-DE", "en-US", "en-GB"}},
   rename = {type = "table", tableKeys = "string", tableTypes = "string"},
   pollFamily = {type = "string", values = {"lhc", "kb", "mouse"}},
   customStack = {type = "string", values = {"prepend", "append"}},
   defaultModeTarget = {type = {"number", "string"}, range = {0}},
   shiftStack = {type = "string", values = {"prepend", "append"}},
   modeStack = {type = "string", values = {"prepend", "append"}},
   defaultLagFactor = {type = "number", acceptFloat = true},
   maxMovementLagSamples = {type = "number", range = {2}},
   maxResolveIterations = {type = "number", range = {1}},
   lagPositionThreshold = {type = "number", range = {0}},
   keyboardButtonCount = {type = "number", range = {0}},
   globalModes = {type = "table", tableKeys = "number"},
   LCDMessageDuration = {type = "number", range = {-1}},
   fixedWaitLag = {type = "number", acceptFloat = true},
   LCDHidePrimaryMode = {type = {"boolean", "string"}},
   defaultStacking = {type = "number", range = {0, 2}},
   keyboardModeCount = {type = "number", range = {0}},
   mouseButtonCount = {type = "number", range = {0}},
   waitLagThreshold = {type = "number", range = {1}},
   keyboardShiftKey = {type = "number", range = {0}},
   defaultShift = {type = "number", range = {0, 2}},
   lhcButtonCount = {type = "number", range = {0}},
   mouseModeCount = {type = "number", range = {0}},
   actionVariance = {type = "number", range = {0}},
   multiClickTime = {type = "number", range = {0}},
   externalConfigs = {type = {"string", "table"}},
   keyboardBindHardwareModes = {type = "boolean"},
   maxLagSamples = {type = "number", range = {2}},
   mouseShiftKey = {type = "number", range = {0}},
   LCDLineLength = {type = "number", range = {0}},
   LCDSeparator = {type = {"boolean", "string"}},
   pollInterval = {type = "number", range = {1}},
   historyDepth = {type = "number", range = {0}},
   lhcModeCount = {type = "number", range = {0}},
   movementLagStepThreshold = {type = "number"},
   keyVariance = {type = "number", range = {0}},
   defaultMode = {type = "number", range = {0}},
   actionDelay = {type = "number", range = {0}},
   defaultHold = {type = "number", range = {0}},
   lhcShiftKey = {type = "number", range = {0}},
   mouseBindHardwareModes = {type = "boolean"},
   separateDeviceThreads = {type = "boolean"},
   preventOptionOverride = {type = "boolean"},
   LCDLastLinePagination = {type = "boolean"},
   logPrimaryButtonState = {type = "boolean"},
   keyDelay = {type = "number", range = {0}},
   LCDLines = {type = "number", range = {0}},
   lhcBindHardwareModes = {type = "boolean"},
   separateDeviceCycles = {type = "boolean"},
   restrictToMainScreen = {type = "boolean"},
   LCDPersistentProfile = {type = "boolean"},
   defaultThreadCancel = {type = "boolean"},
   mergeScopeDefaults = {type = "boolean"},
   mergeDocumentation = {type = "boolean"},
   preventDocOverride = {type = "boolean"},
   offsetMovementLag = {type = "boolean"},
   newLineAfterName = {type = "boolean"},
   abortOnLintError = {type = "boolean"},
   stackAutoReverse = {type = "boolean"},
   LCDClearLastLine = {type = "boolean"},
   noMacroExtension = {type = "boolean"},
   externalProfile = {type = "boolean"},
   globalModeFamily = {type = "string"},
   strictModifiers = {type = "boolean"},
   enableDebounce = {type = "boolean"},
   primaryButtons = {type = "boolean"},
   enableLinting = {type = "boolean"},
   pollMKeysOnly = {type = "boolean"},
   keepNameOnLCD = {type = "boolean"},
   offsetWaitLag = {type = "boolean"},
   showCompiled = {type = "boolean"},
   globalGShift = {type = "boolean"},
   logDebounce = {type = "boolean"},
   description = {type = "string"},
   useHIDKeys = {type = "boolean"},
   logEvents = {type = "boolean"},
   logMemory = {type = "boolean"},
   modeReset = {type = "boolean"},
   outputLCD = {type = "boolean"},
   clearLog = {type = "boolean"},
   stackOrder = {type = "table"},
   monitors = {type = "table"},
   path = {type = "string"}
}

---Combine two Configurations into one.
---@generic T
---@param a OptionsCollection #The first OptionsCollection
---@param b T #The second OptionsCollection
---@param isDefault? boolean #If true, preventOptionOverride is ignored on collection a
---@return T
function ConfigDefinition:mergeConfigs(a, b, isDefault)
   local replace = a.preventOptionOverride ~= nil and a.preventOptionOverride
   if isDefault then replace = false end
   return rv.tbl:intersectSimple(a, b, replace)
end

---@protected
---@param baseData OptionsCollection|string
---@param stack string[]|nil
---@param basePath string
---@param isFinal? boolean
function ConfigDefinition:constructor(baseData, stack, basePath, isFinal)
   if baseData == nil then -- No data, no options
      self.finalConfig = {}
      return
   end
   self.stack = stack or {}
   self.external = type(baseData) == "string"
   if self.external then -- Here we import the current external config file, if one has been specified
      local p = baseData --[[@as string]] :gsub("%.lua$", ""):gsub("$", ".lua")
      rv:put("Importing", p)
      self.stack[#self.stack + 1] = p ---Putting path into stack to prevent infinite loops
      local suc, ret = pcall(function() return rv.utils.lenientLoad(p, false, basePath) end) ---@type boolean,any
      self.base = suc and ret or {}
   else
      self.base = baseData --[[@as OptionsCollection]]
   end
   self.finalConfig = self.base
   self.parents = {}
   local parentData = self.base and self.base.externalConfigs
   local extensions = self.base.extends
   if extensions and extensions ~= "" then
      if type(extensions) == "string" then extensions = {extensions} end
      for i = 1, #extensions do -- loading one or more "fake" profiles to serve as a base for parent imports
         local fakeProfile = rv.utils.fakeProfileImport(extensions[i], basePath)
         if fakeProfile and fakeProfile.config and next(fakeProfile.config) then
            if not parentData then
               parentData = {fakeProfile.config}
            elseif type(parentData) == "string" then
               parentData = {fakeProfile.config, parentData}
            else
               parentData[#parentData + 1] = fakeProfile.config
            end
         end -- This needs to be simulated because the actual profile initializes after the config import
      end
   end
   if parentData then
      -- if basePath == "origin" then rv:put("INVALID ERROR ERROR ERROR") end
      if type(parentData) == "string" then parentData = {parentData} end
      for i = 1, #parentData do
         local p = parentData[i] -- initializing parent profiles, but only keeping their final output
         self.parents[#self.parents + 1] = ConfigDefinition:new((type(p) == "table" and p) or ((basePath) .. p), self.stack, (basePath)).finalConfig
      end
   end
   for i = 1, #self.parents do -- overriding parenr configs with own settings
      self.finalConfig = self:mergeConfigs(self.finalConfig, self.parents[i])
   end

   if isFinal then
      local fin = self:outputFinalized()
      if fin.enableLinting then
         -- making sure the general configurations are valid
         rv.lint:configLinter(fin, self.lintPreset)
      end
   end
end

---Output the
---@return InternalOptions #Final output once all potential parent configs have been loaded and merged
function ConfigDefinition:outputFinalized() return self:mergeConfigs(self.finalConfig, rv.presets.defaultConfig, true) end

return ConfigDefinition
