description
`type` value `mode` or `m`

### Complete Syntax:
>`{ type="mode"|"m", <mode>,  [, family=<option>, temporary=<boolean>, hardwareOnly=<boolean>] }`

```lua

--- Changes the mouse to mode number 2.
k.m3 = { type="mode", 2 }
--- Cycles through all available modes.
k.m4 = { type="mode", 0 }

```
# Functionality
LGS defines 3 modes for most logitech devices, each with a different backlight.
By default, revenant will also use these native modes with optional name assignments, and utilize the built in mode change macro of the device to cycle between them.

It's also possible to decouple the modes used by LGS from the "Hardware" modes, which allows for more than three modes, although on some devices such as the G600 mouse the modes will no longer be differentiated by the backlight. In either case, the `mode` macro is used to navigate between the different modes of your profile.
>[!TIP]
>You can configure the number, names and colors of modes with the [globalModes](./Options-Documentation#globalmodes) option or separately per device in your profile configuration.  


# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options) the Mode Change Macro offers the following options to customize behavior:

## family
Sets the device family for which the mode should be changed.

valid values are:
* **`"all"`** = Change the mode for all devices.
* **`"mouse"`** = Change the mode only for the mouse.
* **`"keyboard"`** = Change the mode only for the keyboard.
* **`"lhc"`** = Change the mode only for the Left-handed controller.

If this option is not explicitly set, the mode change will target the device that triggered the macro. So if you put a mode change macro on a mouse button, the macro will change the mode for the mouse, if you put it on a keyboard key, it will be changed for the keyboard.

If you are using the [globalModes](./Options-Documentation#globalmodes) option in your profile configuration the `family` option has no effect, since all devices are bound to the same modes anyway.

```lua

--- This key changes the mouse to mode to 2.
k.m3 = { type="mode", 2, family="mouse" }

--- This key sets the keyboard mode to 1.
k.m4 = { type="mode", 1, family ="keyboard" }

-- This key sets the mode for ALL devices to 3.
k.m5 = { type="mode", 3, family ="all" }

```
## temporary
With this option enabled, the mode will only change for as long as the button is held down. Basically this makes a mode button act like a custom G-shift key.  
When the button is released again, the device switches back to whatever mode was set before.

```lua

--- Changes the mode to "2" as long as the button is held down.
k.m3 = { type="mode", 2, temporary=true }

```
## hardwareOnly
Changes the hardware mode using the LGS "Mode Change" macro but does not update the mode in Revenant.  
This is generally only useful if the mode in LGS and the mode detected by Revenant get out of sync.
```lua

--- Every press toggles the hardware mode macro, but the mode detected by Revenant stays the same.
k.m3 = { type="mode", 0, hardwareOnly=true }

```