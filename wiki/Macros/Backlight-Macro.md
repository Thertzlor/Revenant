
> [!IMPORTANT]
Not all Logitech devices support setting the Backlight color Programmatically. The G600 for example does not support it but the G502 does.

This macro changes the Backlight color of a Logitech device to an RGB value of your choice.  
It can be assigned with the `type` value of `backlight` or `b`.

### Complete Syntax:
>`{ type="backlight"|"b", <colors...>  [, family=<option>] }`
```lua

-- Changes the Backlight of the mouse to red.
k.m3 = { type = "backlight", 255, 0, 0 }

```
# Color Formats
The Backlight macro accepts RGB values in 3 different formats: the **R**ed, **G**reen and **B**lue values as separate numbers or a single string with a valid hex code with either 3 or 6 characters.
```lua

-- Cyan with RGB channel values
k.m3 = { type = "backlight", 0, 255, 255 }

-- Cyan with 6 char Hex code
k.m4 = { type = "backlight", "#00FFFF" }

-- Cyan with 3 char Hex code
k.m5 = { type = "backlight", "#0FF" }

```
# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options) the Backlight Macro offers the following options to customize behavior:
## family
This option controls for which device family the Backlight should be changed. Accepted values are `mouse`, `keyboard` or `lhc`.
If the option is not set the family of the device on which this macro was triggered will be used.
```lua

-- Even though the macro is on a mouse button, the macro changes the lighting of the keyboard.
k.m3 = { type = "backlight", "#ff0000", family = "keyboard" }

```
