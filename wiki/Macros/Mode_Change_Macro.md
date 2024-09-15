description
`type` value `mode` or `m`

### Complete Syntax:
>`{ <mode>, type="mode"|"m" [, family=<option>, temporary=<boolean>, hardwareOnly=<boolean>] }`

```lua

--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode"}
--- Cycles through all available modes.
k.m4 = { 0, type="mode"}

```
# Functionality
LGS defines 3 modes for most logitech devices, each with a different backlight.
By default, revenant will also use these native modes with optional name assignments, and utilize the built in mode change macro of the device to cycle between them.

It's also possible to decouple the modes used by LGS from the "Hardware" modes, which allows for more than three modes, although on some devices such as the G600 mouse the modes will no longer be differentiated by the backlight.

> **Important**: You can configure the number, names and colors of modes with the [globalModes]() option or [separately per device]() in your profile configuration or.

## Automatic mode reset
One of the reasons I hardly used mouse modes in the base LGS software was that when you change the mode from 1 to 2 and your mouse profile changes, the mouse is still mode 2.  
This might be a matter of personal preference but I use secondary modes for specific sub-parts of games and programs, so launching a profile in mode 2, because the last profile was in mode 2 makes no sense. Especially since most of my profiles don't have any buttons defined in any mode besides 1.

To solve this issue, Revenant introduces the modeReset option to automatically reset the mode to 1, when a new Profile is loaded.  
Set this option to `false` in your profile configuration to enable the LGS default behavior of keeping modes static across profiles.


# Options
Besides the [General Macro Options]() the Mode Change Macro offers the following options to customize behavior:

## family
Sets the device family for which the mode should be changed.
If you are using global modes or use the argument "all" the mode will be changed for all devices.
```lua

--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode", family="mouse"}
--- Cycles through all available modes.
k.m4 = { 1, type="mode", family ="keyboard"}
k.m4 = { 3, type="mode", family ="all"}

```
## temporary
With this option enabled, the mode will only change for as long as the button is held down. Basically this makes a mode button act like a custom G-shift key.

```lua

--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode"}
--- Cycles through all available modes.
k.m4 = { 0, type="mode"}

```
## hardwareOnly
Changes the hardware mode using the LGS "Mode Change" macro but does not update the mode in Revenant.  
This is generally only useful if the mode in LGS and the mode detected by Revenant get out of sync.
```lua

--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode"}
--- Cycles through all available modes.
k.m4 = { 0, type="mode"}

```