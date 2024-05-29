description
`type` value `group` or `g`

### Complete Syntax:
>`{ <mode>, type="mode"|"m" [, family=<option>, temporary=<boolean>, hardwareOnly=<boolean>] }`

Example:
```lua
--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode"}
--- Cycles through all available modes.
k.m4 = { 0, type="mode"}
```

# Functionality
LGS defines 3 modes for most logitech devices, each with a different backlight.
By default, revenant will use these native modes as well, with optional name assignments, using the internal mode change macro to cycle between them.

It's also possible to decouple the modes used by LGS from the "Hardware" modes, which allows for having more than three modes.


## Automatic mode reset
One of the reasons I hardly used mouse modes in the base LGS software was that when you change the mode from 1 to 2 and your mouse profile changes, the mouse is still mode 2.  
I use secondary modes for specific sub-parts of games and programs, so launching a profile in mode 2, because the last profile was in mode 2 makes no sense. Especially since most profiles don't have any buttons defined in any mode besides 1.

To solve this issue, Revenant introduces the modeReset option to automatically reset the mode to 1, when a new Profile is loaded (internally LGS uses an M-key state to keep track of the current mode).  
Set this option to `false` in your profile configuration to enable the LGS default behaviro of keeping modes.


# Options
Besides the [General Macro Options]() the Mode Change Macro offers the following options to customize behavior:

## family
Sets the device family for which the mode should be changed.
If you are using global modes or use the argument "all" the mode will be changed for all devices.

Example:
```lua
k.m3 = 
```
## temporary
With this option enabled, the mode will only change for as long as the button is held down. Basically this makes a mode button act like a custom G-shift key.

Example:
```lua
k.m3 = 
```
## hardwareOnly
Changes the hardware mode using the LGS "Mode Change" macro but does not update the mode in Revenant. This is generally only useful if the mode in LGS and the mode detected by Revenant get out of sync.

Example:
```lua
k.m3 = 
```