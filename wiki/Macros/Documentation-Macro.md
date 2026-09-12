A macro used to toggle Revenant's built in Documentation Mode for interactively displaying information about your current profile.
`type` value `documentation` or `doc`.

>[!Tip]
Documenting Macros is possible via the [macro itself](./Macro_Overview#documentation), or via [internal](./Profile_Overview#documentation) or [external](./Profile_Overview#external-documentation) documentation objects for the profile.
### Complete Syntax:
>`{ type="documentation"|"doc" }`

```lua

local profile = ...
local k = profile.key

--- The documentation object uses the targeted macro names as keys.
profile.documentation = {
   macro_1 = "This macro prints 1.",
   macro_2 = "This macro prints 2."
}

--- In Documentation Mode this button outputs the value from the Profile's documentation object.
k.m3 = {"1", name="macro_1"}

--- In Documentation Mode this button outputs the content of its own documentation option.
k.m4 = {"2", name="macro_2", documentation="This documentation has higher priority. The macro still prints 2."}

--- This button toggles Documentation Mode.
k.m5 = { type="documentation" }

```
# Functionality of the Documentation Mode

In Documentation mode macros do not trigger key presses or any other changes and instead output information about themselves, either by showing a user defined documentation text or by dynamically parsing their contents into a (hopefully) easily readable form.  

Documentation mode respects internal macro states and conditions. For example if a macro is assigned to a mode or G-Shift state you will only get documentation of the active macro in the current mode/g-shift configuration.

The information can be displayed on an LCD capable Logitech Device, the Logitech LCD emulator, or the output section of the Logitech scripting window.
>[!Tip]
You can open the LCD emulator by **alt+shift-clicking** the Logitech Gaming Software Icon your tray and selecting `LCD Emulator`.  
In the LCD Emulator window select `Tools -> Color -> Start` to launch your display. The next time Revenant sends any LCD message it will be displayed there.

>[!Note]
The length and number of lines the LCD can (unfortunately) depend on the DPI and display scale of your monitor.  
Should the LCD messages get cut off, you can adjust the [LCDLines](./Options_Documentation#lcdlines) and [LCDLineLength](./Options_Documentation#lcdlinelength) options until the content fits.

# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options), the Documentation Macro has no options of its own.