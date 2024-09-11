A macro that lets you call external commands defined in the Logitech Gaming Software GUI.  
`type` value: `externalmacro` or `e`

### Complete Syntax:
>`{ <name>, type="externalmacro"|"e" [, p|play=<option>, macroBlocking=<boolean>, lcd=<boolean>] }`

```lua
-- Executes the built in LGS "Paste" Command
k.m3 = { "Paste", type="externalmacro"}

-- Executes a uswer defined command called "Custom Multikey" if it exists.
k.m4 = { "Custom Multikey", type="externalmacro"}

```
# Functionality
With this macro you can execute any LGS command by calling it by its name, even those with functionality that is not directly supported via the lua API (such as opening shortcuts, FN and media keys, etc.)  
Internally this macro acts as a wrapper for the `PlayMacro` function.

This approach comes with some limitations however. The `PlayMacro` function simply forwards the command but there is no way of telling if a macro with the provided name actually exists, or what the state of any LGS commands currently is.

# Options
Besides the [General Macro Options]() the External Macro offers the following options to customize behavior:
## play
* shorthand: `p`

Select the play mode for the external macro. Because only one LGS macro can run at a time and we cannot know which one is currently running (if any) a call of `AbortMacro` cannot be limited to the current macro but in fact aborts *any* LGS macro that may be running.

There are three possible values:

* **`"normal"`** *(default)* = Press the button to trigger the command. This is the default 
* **`"hold"`** = Press the button to trigger the command. Execute `AbortMacro` when releasing the button
* **`"toggle"`** = Trigger the command on the first press, execute `AbortMacro` when pressing the button again.

Note that **Revenant** macros like those executed via the [Sequence Macro]() are **not** affected by the `AbortMacro` call.
```lua

-- Triggers the macro when the button is pressed. The default behavior
k.m3 = { "Custom Multikey", play="normal", type="externalmacro"}

-- Triggers the macro when the button is pressed, aborts any running LGS macro when it is released.
k.m4 = { "Custom Multikey", play="hold", type="externalmacro"}

-- Triggers the macro when pressed the first time, aborts any running LGS macro when pressed again.
k.m5 = { "Custom Multikey", play="toggle". type="externalmacro"}

```
## macroBlocking
Decide if another LGS macro can block the execution of this command. Normally if a LGS macro such as a Multikey or Text macro is running, all other calls to `PlayMacro` are ignored.  
When macroBlocking is set to `false`, the `AbortMacro` function is called before triggering the command, aborting any potentially running LGS macro and ensuring that the current command will run.
* **default value:** `true`
```lua

-- If this macro is triggered while it or any other LGS command is running, it will simply be ignored.
k.m3 = { "Custom Multikey", macroBlocking=true, type="externalmacro"}

-- If this macro will abort any other running LGS macro before playing, preventing it from being blocked itself.
k.m4 = { "Custom Multikey", macroBlocking=false,type="externalmacro"}

```
## lcd  
This option controls if in addition to triggering the LGS command, the macro will also output a description of the action (`"Playing LGS macro [name]"`/`"Stopping LGS macro [name]"`) to the LCD screen if one is available.
* **default value:** `true`
```lua

-- Outputs the message "Playing LGS macro Custom Multikey". This is the default behavior
k.m3 = { "Custom Multikey", lcd = true, type="externalmacro"}

-- Triggers the same macro silently.
k.m3 = { "Custom Multikey", lcd = false,  type="externalmacro"}

```