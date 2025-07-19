Revenant is highly configurable and offers a wide array of options to modify all aspects of a mouse profile.  
In order to keep things beginner friendly this page attempts to list all options starting from the most basic and common options at the top and getting more technical at the bottom.
# Hardware configuration

## devices
The Name of your Logitech device as defined in HardwareDefinitions.lua, an array of names if multiple devices are used.
* *default value: **"G600"***

## keyboardLocale
The Layout of your keyboard. currently supported are "de-DE", "en-US" and "en-GB"
* *default value: **"en-US"***

## separateDeviceCycles
Determines if button presses on one device can cancel the state of cycle macros on another device.
* *default value: **false***

## defaultModeTarget
Define if the globally defined modes will be applied to all devices "join" or the current device "self"
* *default value: **nil***

##  defaultKeys
These keys, by default corresponding to the windows default mouse bindings, will be mapped on every profile unless overwritten. This option should only contain the very basics.
* *default value: **`{ m3 = {"/3", m = 0, g = 2}, m4 = {"/4", m = 0, g = 2}, m5 = {"/5", m = 0, g = 2} }`***

## rename
Remap key names to custom names, standard key names are `m`, `k` and `l` for mouse, keyboard and lhc respectively followed by their number according to LGS. 

If the new name of a key is the name of another standard key, the names of the keys will be switched.

* *default value: **empty***

```lua

-- An example renaming map for the G600 that renames the buttons m9-m20 to g1-g12, sorting the thumb pad keys in their own distinct group. 
-- furthermore, the names of the m4/m8 and m5/m7 keys are switched.
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

```

## globalModeFamily
Set which family's M-key state should be used to track the global mode ("kb", "mouse" or "lhc")
* *default value: **"kb"***

## logPrimaryButtonState
Log the current state primary mouse buttons, even when they are not triggering proper events.  
However, as those states can only be detected passively, they are not added to the history of past button presses.
* *default value: **true***
```lua

profile.config = {
   logPrimaryButtonState = true,
}

-- This condition checking if left click is pressed only works with "logPrimaryButtonState" enabled.
profile.key.m3 = {"x", "y", "z", type = "cycle",  condition = "m1"}

```

## mouseButtonCount / keyboardButtonCount / lhcButtonCount
By default the number of buttons that Revenant will expect your device to have will be defined by the device definition chosen via the content of the [devices](#devices) option, but you can also manually override this number of buttons for any device family using these options.
* *default value: **[provided by device definition]***

## mouseShiftKey / keyboardShiftKey / lhcShiftKey
* *default value: **[provided by device definition]***
  
## mouseModeCount / keyboardModeCount / lhcModeCount
* *default value: **[provided by device definition]***
  
## mouseModeConfig / keyboardModeConfig / lhcModeConfig
For a description of a mode definitions, see the documentation for the [`globalModes`](#globalmodes) option.
* *default value: **[provided by device definition]***


## strictModifiers
If true, modifier key checks are exhaustive, for example a macro that needs the shift key pressed will not activate if the control key is *also* pressed.
* *default value: **true***

## primaryButtons
Enable binding to mouse buttons 1 and 2. 
>[!CAUTION]
>This functionality is unstable and not recommended due to LGS limitations. You basically need to sabotage your profile to make it work at all. 
* *default value: **false***

## useHIDKeys
uses the PressHidKey and ReleaseHidKey functions instead of the normal PressKey and ReleaseKey functions.
>[!CAUTION]
>This functionality is still experimental and unstable. the `*HidKey` functions are undocumented and I'm still trying to figure out how exactly they work and what they map to.
* *default value: **false***

# General Profile Configuration
## defaultMode
define in which mode macros will trigger by default. 1 for the first mode 2 for the second mode ... etc. Set to 0 to enable them in all modes. You can also provide an array of number to set a default trigger in multiple modes.
* *default value: **1***

## modeReset
Reset the mode of all devices to 1, when a profile is loaded. Highly recommended.
When you change the mode of your mouse, for example from 1 to 2 and then change the profile, the LGS software normally keeps mouse in mode 2.  
This might be a matter of personal preference but I use secondary modes for specific sub-parts of games and programs, so launching a profile in mode 2, because the last profile was in mode 2 never made sense. Especially since most of my profiles don't have any buttons defined in any mode besides 1.

Set the option to `false` in your profile configuration to enable the LGS default behavior of keeping modes static across profiles.
* *default value: **true***

## defaultShift
The default G-shift condition in which macros will trigger. 0 means g-shift needs be inactive, 1 means only when active and 2 means macros will trigger regardless of g-shift.
* *default value: **0***

## globalModes
Define a number of global modes for your profile. You can provide an array of numbers, strings acting as names of the different modes, or arrays in which the first element is the mode name and the second is a color value used for the device backlight (not supported by all devices).

* *default value: **empty***

Examples:
```lua
-- <profile A>
-- Three standard numeric modes.
config.globalModes = {1,2,3}

-- <profile B>
-- Three named modes.
config.globalModes = {"mode_1","mode_2","mode_3"}

-- <profile C>
-- A mix of named and numeric modes, two with backlight colors defined.
config.globalModes = { {1,"#f00"}, { "mode_2", "#00ff00" }, "mode_3"}

```


## globalGShift
Count G-shift on one device as G-shift for all other devices as well.
* *default value: **true***

## defaultStacking
The default stacking behavior of sequence of macros when triggered multiple times. For details, see the documentation for the [stacking]() option on sequence macros.
* *default value: **1***

## historyDepth
How many past button presses should be kept in memory? 
Higher values are necessary for more complex "past button" conditions.
* *default value: **5***

## description
A custom description of the profile which will be shown on the LCD display.
* *default value: **""***

## extends
Set a path to another external profile file that will be used as basis of the current profile. All macros on the parent profile will be retained except for the ones overwritten by the assignments of this profile. You can also provide an array of multiple paths wich will be loaded and combined in order.
* *default value: **nil***

## noMacroExtension
If there are any keybindings on a button, never merge them with parent bindings.
* *default value: **true***

## fragileThreads 
Determines if continuous macros are cancelled when another button is pressed by default
* *default value: **true***

## defaultThreadInterrupt 
Determines if starting a continuous macro cancels other playing continuous macros by default
* *default value: **true***


## reverseRelativeAxis 
Reverse the Y axis of relative movement in [Mouse Position Macros](), so that 400px means 400px upwards and "-10%" means 10% down.
* *default value: **true***

## externalConfigs
define a path of an external configuration file, or an array of multiple paths, loaded and combined in order.
* *default value: **nil***
## externalDocs
Set a path to an external documentation file, or provide an array of multiple paths, which will be loaded and overridden
* *default value: **nil***

# Timing Configurations

## actionDelay
The default duration of milliseconds to wait between subsequent action in sequence macros
* *default value: **2***

## keyDelay
The default duration to wait between pressing and releasing a key
* *default value: **2***

## multiClickTime
The standard interval used by multi click buttons to determine whether something is  a multi press
* *default value: **200***

## defaultHold
The default duration a holdKey macro needs to be held down to switch to the next action, in milliseconds
* *default value: **500***

## actionVariance
randomize the timing between actions within a defined range of milliseconds.
* *default value: **0***

## keyVariance
randomize the timing between pressing and releasing keys within a defined range of milliseconds.
* *default value: **0***

# Screen configuration [Needed only for mouse movement macros]

## monitors
Define the resolution and position of one or more monitors 

> `{ <width>, <height> [, main=<boolean>] }`

* *default value: **`{1920, 1080, main = true}`***

## restrictToMainScreen
Ignore all screens besides the current primary screen when calculating mouse position.  
If the cursor is located on a secondary screen while a *relative* mouse position macro is triggered, no movement will occur.
* *default value: **true***

# Polling Configuration [Only change in case of performance issues]

## pollInterval
The number of milliseconds the script will wait between checking the state of new events and paused coroutines. Lower values make Revenant more responsive and action timings more precise, but are potentially more taxing performance wise.
* *default value: **1***

## pollFamily
Define a device family used for polling. If pollMKeysOnly is set to "false", macros bound to the device will be ignored.
* *default value: **"lhc"***

## pollMKeysOnly
Reserve M keys for polling.  
M keys were a feature of very old Logitech devices (even for LGS standards) and chances are that your mouse/keyboard doesn't have them. This makes them perfect to exploit for polling since their state can be set even for devices that don't physically have them without interfering with functionality.
* *default value: **true***

# LCD Configuration

## outputLCD
Utilize the LCD display on a compatible logitech keyboard or the LGS LCD emulator
* *default value: **true***

## LCDLines
The number of lines your LCD display is capable of displaying at once.  
If you are using the LGS LCD Emulator the number of lines visible may depend on the resolution DPI and scaling settings of your monitor.
* *default value: **10***

## LCDLineLength
Unit-less measurement of how much text fits into the LCD display. In the case of the LGS LCD emulator this amount depends on screen resolution, dpi and scaling setting, adjust if text overflows or cuts off to early.
* *default value: **76***

## LCDMessageDuration
How long to show messages on the LCD display by default (in milliseconds)
* *default value: **3000***

## LCDPersistentProfile
Should the Profile information page be kept on the LCD display at all times? (This will interfere with other apps that may run on your lcd display)
* *default value: **true***

##  keepNameOnLCD
Always show the profile header in the first line of the LCD display when text is displayed
* *default value: **true***

## LCDSeparator
Define a separator to divide the LCD display between header line and text content. set to false to disable the separator, true to fill the line with "=" or provide a custom string to fill the line with.
* *default value: **true***

## LCDHidePrimaryMode
Don't show the designation of the primary mouse mode in the LCD profile header. set to "unnamed" to only hide it if it does not have a defined name.
* *default value: **"unnamed"***

## LCDLastLinePagination
Reserve the last line on multi-page text displays for pagination
* *default value: **true***

## LCDClearLastLine
Don't show non-pagination text in the last line of the LCD display (to avoid the blue background)
* *default value: **true***

## newLineAfterName
When documenting a key insert a newline between name and key description
* *default value: **true***

---
   > EVERYTHING BELOW IS FAIRLY TECHNICAL! DON'T CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING


# Advanced Profile Inheritance Configuration


## preventDocOverride
Don't let the contents of internal documentation definitions overwrite imported documentation
* *default value: **true***

## preventOptionOverride
Don't let subsequently loaded configurations override options defined in the current configuration
* *default value: **true***


## mergeDocumentation
Should profiles merge their documentation with that of their parent profiles?
* *default value: **true***

## mergeScopeDefaults
Should profiles merge their scope defaults with that of their parent profiles?
* *default value: **true***

## preventInheritance
A list of macro names that can't be inherited by other macros
* *default value: **empty***

## maxResolveIterations
??
* *default value: **500***


# Debug logging settings

## logEvents
Log each key event that Revenant receives
* *default value: **false***

## logMemory
Append a section showing teh current memory usage to each event log entry
* *default value: **false***

##  showCompiled
Log statistics about the profile into the LGS console after compiling
* *default value: **false***

## clearLog
Clear the LGS log output every time a new profile is loaded.
* *default value: **true***

## logDebounce
output a log message whenever Revenant has debounced a button
* *default value: **false***

# Flex Syntax and Inheritance Configuration
If you are not using flat bindings or combine multiple kinds of tiered bindings in your profiles and you end up with macros not triggering in the order you think they should, you can try adjusting these options (although usually it's more efficient to stick with a consistent binding scheme).

## stackOrder
Determines in which order macros will be sorted into a group if they were originally defined in different places
* *default value: **`{"custom", "mode", "shift"}`***

## modeStack
The direction in which macros defined in mode based groups are stacked. "append" or "prepend"
* *default value: **"append"***

##  shiftStack
The direction in which macros defined in shift based groups are stacked. "append" or "prepend"
* *default value: **"append"***

## customStack
The direction in which macros defined in custom groups are stacked.  "append" or "prepend"
* *default value: **"append"***

## modeSort
The order in which macros grouped by modes are sorted into a single group. "standard", "reverse" or an numerical order
* *default value: **"standard"***

## shiftSort
The order in which macros grouped by shift states are sorted into groups. "standard", "reverse" or an numerical order
* *default value: **"standard"***

## customSort
If you have defined your bindings in custom groups, you can optionally control the order in which their macros will be parsed and executed by listing their names in your chosen order.
* *default value: **empty***

## stackAutoReverse
Attempt to retain logical macro order in some questionable stack orders
* *default value: **true***


# Linter [turning these options off might cause you to lose control of your mouse for silly reasons like typos]


## enableLinting
Always check if macros and configurations have the correct properties with the correct types for each property
* *default value: **true***

## abortOnLintError
Prevent Revenant from initializing profiles or macros if the linter detects problems with their configuration
* *default value: **true***


# Lag Offset [probably only needs changed for very bad/old computers]

## offsetMovementLag
Should Revenant attempt to compensate for performance based lag in mouse movement macros?
* *default value: **true***

## defaultLagFactor
The amount of movement lag Revenant will assume to be present at profile load. 1 means no lag whatsoever.  
Set this to a higher value if mouse movements executed via macros appear slow or staggered right after loading a profile.
* *default value: **1***

## offsetWaitLag
attempt to compensate for performance caused lag when pausing between actions
* *default value: **true***

## maxLagSamples
The maximum number of timing samples used to determine lag offset
* *default value: **100***

## waitLagThreshold
minimum duration in milliseconds of a timing value to be relevant for  lag compensation
* *default value: **50***

## lagPositionThreshold
Discrepancy in mouse position (in Logitech units) that will trigger lag countermeasures
* *default value: **1000***

## maxMovementLagSamples
How many samples of mouse coordinates should be used to offset potential lag
* *default value: **100***
  
## movementLagStepThreshold
Minimum number of movement steps required to make a mouse movement relevant for lag offset calculations.
* *default value: **20***

# Debounce Setting [Designed to offset hardware faults, but is not very reliable]

##  enableDebounce
Attempt to identify and block suspiciously fast manual button presses (not really reliable)
* *default value: **false***

## debounceSettings
Define debounce values for buttons of specific devices. The first entry in the array if the number of the key, the second a number of milliseconds and the third defines if "up" or "down" events should be monitored. Events that happen faster than the millisecond value won't trigger macros.
* *default value: **`{mouse = {{1, 30, "up"}, {2, 30, "up"}}}`***