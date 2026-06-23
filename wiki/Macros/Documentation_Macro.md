A macro used to toggle Revenant's built in Documentation Mode for interactively displaying information about your current profile.
`type` value `documentation` or `doc`.

### Complete Syntax:
>`{ type="documentation"|"doc" }`
```lua

k.m3 = "a"

--- Press m4 to enter documentation mode.
k.m4 = { type="documentation" }

```
# Functionality of the Documentation Mode

The information can be displayed on an LCD capable Logitech Device, the Logitech LCD emulator or the output section of the Logitech scripting window.
>[!Tip]
You can open the LCD emulator by **alt+shift-clicking** the Logitech Gaming Software Icon your tray and selecting `LCD Emulator`.  
In the LCD Emulator window select `Tools -> Color -> Start` to launch your display. The next time Revenant sends any LCD message it will be displayed there.

>[!Note]
The length and number of lines the LCD can (unfortunately) depend on the DPI and display scale of your monitor.  
Should the LCD messages get cut off, you can adjust the [LCDLines](../_Options_Documentation.md#lcdlines) and [LCDLineLength](../_Options_Documentation.md#lcdlinelength) options until the content fits.

# Options
Besides the [General Macro Options](), the Documentation has no options of its own.