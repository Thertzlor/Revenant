Macros are the central building block of any mouse profile. They can do anything from simple key presses to complex logic.  
This page serves as an introduction to all built-in macro types, as well the common settings shared between all kinds of macros.
# Bindings and types
The type of a Macro is set via the `type` property, or its shorthand `t`.  
If no type is provided or the macro is provided as a simple string it will be automatically interpreted as a [Key Macro]()

* **Basic Input Macros**  
   Several ways to trigger keys on the keyboard or type out strings.
   * `key`, `k`: [Basic Key or String Input]()
   * `keyup`, `u`: [Key Up]()
   * `keydown`, `d`: [Key Down]()
   * `keytoggle`, `kt`: [Key Toggle]()

* **Multi Macros**  
   These macros present ways to manage multiple macros on a single key. Playing them sequentially, cycling between them or even triggering multiple macros at the same time.
   * `sequence`, `s`: [Sequence of Macros]()
   * `cycle`, `c`: [Cycle of Macros]()
   * `group`, `g`: [Group of Macros]()

* **Timing Macros**  
   Switch between key functionality based on the timing of consecutive key presses or holding a key for a certain duration.
   * `multiclick`, `t`: [Multiclick Key]()
   * `holdkey`, `h`: [Hold Timer Key]()

* **Mouse Functionality Macros**  
   Macros which set mouse properties instead of reacting to them.
   * `mouseposition`, `p`: [Mouse Position / Movement]()
   * `mousewheel`, `w`: [Mouse Wheel Control]()

* **Logitech Functionality Macros**  
   Functionality that is normally configured via LGS.
   * `mode`, `m`: [LGS Mode Select]()
   * `backlight`, `b`: [Device Backlight Color]()
   * `setdpi`, `dpi`: [Mouse DPI Modifier]()
   * `externalmacro`, `e`: [LGS Macro Execution]()

* **LCD Integration Macros**  
   LCD output for some Logitech Keyboards or the LGS LCD Emulator.  
   *[To activate the LCD Emulator shift + ctrl + right click on the LGS tray icon, until the option appears then in the window select `Tools -> Color -> Start`.]*
   * `log`, `o`: ['LCD Message']()
   * `documentation`, `doc`: [LCD Profile Documentation]()
   * `page`, `pg`: [LCD Page Navigation]()

* **Control Macros**  
   Control currently running macros or set cycle properties.
   * `macrocontrol`, `mc`: [Continuous Macro Control]()
   * `cyclecontrol`, `cc`: [Cycle Macro Control]()

* **Input Modifier Macros**  
   Macros for modifying the behavior of the *following* key inputs.
   * `bufferkey`, `kb`: [Key Buffer]()
   * `wrapkey`, `kw`: [Key Wrap]()

* **Meta Macros**  
   Macros that reference other macros or modify the Revenant environment.
   * `link`, `l`: [Link to Macro]()
   * `instance`, `i`: [New Instance of Macro]()
   * `flag`, `f`: [Set Flag]()
   * `func`, `fn`: [Lua Function Call]()
   * `wipehistory`, `w`: [Wipe Button History]()

# Syntax Notation
Throughout this documentation the syntax of a macro is shown in the following notation, demonstrated here with the `group` and `macrocontrol` macros:

>`{ type = "group"|"g", <macro...> [, allowEmpty=<boolean>] }`

>`{ type = "macrocontrol"|"mc",  <target|targets[]> [, <command> ,targetGroup=<option>] }`

We list the macro type first, Positional arguments are listed right after, and anything within `[brackets]` is optional. A notation like `<value...>` means that more than one value can be used, as seen in this key macro which presses 3 buttons together:

>`k.m3= { t="key", "a,"b","c" }`

The notation `<value[]>` also means that multiple values are accepted but they have to be placed in a list, like in this control macro:

>`k.m3 = { type="mc", {"macro_a", "macro_b"}, "cancel" }` 

the content of the bracketed designation can designate a type such as `<number>` or `<boolean>`, if there is a fixed number of option values the field is designated as `<option>`. Any other placeholder designates a field that can hold different types of values depending on the situation.

A property may be prepended with a shorthand separated with a slash as in `ad/actionDelay`. This means that for this option `ad` and `actionDelay` can be used interchangeably (if both the long and short form of an option are set the long form takes precedence).

# General Macro Options
While most macro types provide their own means of customization, the following options can be set on any macro and form the basics of controlling general macro behavior.  

## mode
* shorthand: `m`

If your profile has multiple modes, you can control which macro runs in which mode by assigning the number of a mode to this option.  
You can set the value to `0` to designate a macro that will explicitly run in *every* mode.  
If you have named modes in your configuration, their names and numerical index can be used interchangeably.

By default Revenant assumes 3 modes per device just like LGS which also includes triggering the native LGS mode change for backlight and UI feedback.  
It's possible to alter this behavior, add or remove modes or just generally decouple the Revenant modes from the LGS modes, details can be found in the [Mode Handling]() Section of the Mode change Macro Documentation.  

The `mode` option also supports testing for a list of different modes as well as negated mode checks (by prefixing the mode number or name with a minus).  
```lua

-- A mode change macro with a target of 0 cycles between all available modes.
k.m3 = { 0 , type = "mode" }

-- Only triggers in mode 1
k.m4 = { "a" , mode = 1 }

-- Multi mode selection: Macro runs in modes 2 and 3
k.m5 = { "b", mode = { 2, 3 } }

-- Macro runs in every mode.
k.m5 = { "c", mode = 0 }

-- Negated mode check, Macro runs in every mode except 2.
k.m6 = { "d" mode = -2 }

```
---
## mkey
Define one or more modifier keys that have to be pressed to allow a macro to run.

Modifiers are defined by a two letter code, the first letter being the direction, `g` for general, `l` for left or `r` for right, and the second letter the modifier type: `c` for control, `a` for alt, `s` for shift.  
Then there are three special codes: `cl` and `nl` for checking if capslock and numlock are active as well as `no` which designates macros that will only run if no modifier at all is pressed.  
The win/cmd key is not supported as its state cannot be natively queried by the lua API.  
The possible codes are as follows:

      Left Alt: "la"
      Right Alt: "ra"
      Any Alt: "ga"

      Left Shift: "ls"
      Right Shift: "rs"
      Any Shift: "gs"

      Left Control: "lc"
      Right Control: "rc"
      Any Control: "gc"
      
      Caps lock: "cl"
      Num lock: "nl"
      
      No key: "no"

It is possible to combine multiple modifier codes into one string to test for more than one pressed key.
```lua

-- Only triggers the 'x' key when any control key is pressed, left or right.
k.m3 = { "x", mkey = "gc" }

-- Only triggers the 'y' key when both the left alt key and the left shift key are pressed.
k.m4 = { "y", mkey = "lsla" }

-- doesn't trigger if ANY modifier is pressed.
k.m5 = { "z", mkey = "no" }

```
By default, even if the correct modifiers are pressed macros will not trigger if any additional modifier key is also active. To change this behavior see the [strictModifiers Option]().  

---
## gshift
* shorthand: `g`

This setting defines in which G-shift state a given macro should play. Valid values are 0, 1 and 2.

* **0** means that the macro only plays when g-shift is not active.
* **1** means that the macro only plays when g-shift is active
* **2** means that the macro plays in either g-shift state

Note that you do not bind your g-shift key itself as a macro, but in the configuration with the [mouseShiftKey](), [keyboardShiftKey]() or [lhcShiftKey]() options.  
For devices with a "canonical" G-shift button (which I believe is only the G600) no manual configuration is needed unless you specifically want to change the button to another.  
If a button serves as a G-shift button, it cannot be used to trigger any other macros.
```lua

-- Press `a` when g-shift is off and b when g-shift is on
k.m3 = { {"a",gshift=0}, {"b", gshift=1} }

-- Always press `c` regardless of g-shift.
k.m4 = {"c", gshift=2}

```
You can set the default `gshift` behavior for all macros that don't have this option explicitly set with the [defaultShift]() option.

---
## direction
* shorthand: `dir`

With this option you can decide if a macro should trigger when the mouse key is pressed (`normal`) or when the key is released (`up`).
```lua

-- Does nothing when the button is pressed, and types 'x' when released.
k.m3 = { "x" , direction = "up" }

```
Depending on the macro type triggering only on key release might change the behavior of the macro. For example normally the normal key macro waits until the next time its button is released before releasing a key, but when triggered with the 'up' direction will simply press and release the key(s) immediately.  
Most macros which normally only trigger once on key-down (sequences, mode changes, etc) remain unchanged but functionality that *requires* a key to be held down such as [Hold Keys]() won't function with only the "up" trigger.

--- 
## name
* shorthand: `n`

Assigning a name to a macro can simply serve as a means of documentation or to enable other macros to find the macro by reference.  
It does not matter where a macro originates, be it directly assigned to a key or as a nested sub-macro in a sequence, as long as it has a name it can be referenced anywhere.  
If your macro has no manual name assigned and is the only macro bound to a key, Revenant will automatically assign the key's name to your macro.  
Similarly the macros defined in a profile's `library` table are automatically assigned the name of their respective property key without needing a `name` property.
```lua

-- once triggered, this sequence will print the string "text", looping indefinitely.
k.m3 = { type="sequence","test ", loop=-1, name = "test-loop" }

-- m4 targets a macro by name, toggling between pausing and unpausing it.
k.m4 = { type="macrocontrol","test-loop", "toggle"  }


-- This macro is technically anonymous.
k.m5 = { type="sequence","test 2 ", loop=-1 }

-- 'Anonymous' top level macros can still be referenced by key name.
k.m4 = { type="macrocontrol","m5", "toggle" }

```
---
## area

The `area` option restricts a macro to triggering only while the cursor is inside a defined area of the screen.  
In order for area definitions (especially ones defined in pixel values) to work correctly it's important to configure your [Monitor Settings]().

An area definition has the following syntax:
> `{ <width> [,<height>] [, o/offset={ <left> [,<top>] }|<size>, exclude=<boolean>, screen=<number>] }`

Areas are defined as rectangles and the option accepts one or more rectangle definition objects.  
A rectangle definition consists of a width and an optional height value as well as an optional property `offset` (which can be shortened to  `o`).  
Both size and offset can be defined with either pixels or percentages of screen space, with unquoted numbers designating pixel values and strings ending with `%` designating percentages.

The first value in the definition defines the width of the rectangle, the second the height. If only one value is provided it is used for both width and height.  
Negative sizes wrap around the other side of the screen.

The `offset` property defines the rectangle's offset from the top left of the screen, first value for the X axis, second for Y. As with the main size definition, providing only a single value uses it for both X and Y offsets (n that case, the value can be provided without a table). If the entire `offset` property is omitted, both offsets are 0.  
Negative offset values calculate the offset from the opposing side of the screen.

The definition also has an optional property `exclude`, which can be set to `true` if the intention is to trigger the macro anywhere **outside** the defined rectangle, as well as a `screen` property which tells Revenant on which monitor the area is situated for multi monitor set-ups.

Examples:
```lua

-- setting the resolution. 
profile.config = { monitors = { 1920, 1080 } }

-- minimum valid area definition.
-- This macro only triggers in the top left quarter of the screen
-- (50% width, 50% height)
k.m3 = { "a", area = { "50%" } }

-- negative values wrap around, so "-50%" means "50% but from the right"
-- "100%" in the second position means covering the entire height of the screen.
-- Therefore this macro triggers in the right half of the screen.
k.m4 = { "b", area = { "-50%", "100%" } }

-- We can also work with pixels.
-- This macro executes within a 500x1000px rectangle in the top left corner of the screen.
k.m5 = { "c", area = { 500, 1000 } }

-- This area also defines a 500x1000px rectangle.
-- The offset shifts the position of the rectangle 400px to the left and 10% of the screen from the top.
-- As you can see, we can freely mix percentage and pixel values.
k.m6 = { "d", area = { 500, 1000, offset = {400, "10%"} } }


-- Here, the offsets are negative.
-- The rectangle is now positions 400px from the right side of the screen and 10% from the bottom.
k.m7 = { "e", area = { 500, 1000, offset = {-400, "-10%"} } }

```
---
## condition
* shorthand: `c`

Conditions are an advanced utility to control macro execution based on the current state of the profile context such as currently or previously pressed mouse keys, currently executing macros or triggered flags (and more).  
The condition option has its own specific syntax, allowing conditions to be grouped and nested with arbitrary depth. For details see: [Condition Syntax](./Condition_syntax.md).
```lua

-- Toggles the 'test' flag on and off but only if mouse 3 (middle mouse button) is currently pressed.
k.m4 = { type="toggleflag","test", condition="m3"}

-- This sequence can only be started when the 'test' flag is set.
k.m5 = { "123456789" , actionDelay = 500 , condition = ".test" , type = "sequence", name = "counter" }

-- Triggers the 'a' key but only while the 'counter' sequence is running and the middle mouse button is NOT pressed.
k.m6 = {"a", condition = { ":counter" , "-m3" }}

```
---
## blocking
* shorthand: `b`

The `blocking` option causes a macro to stop the execution of any other macros for the current event after it successfully executes.  

In other words if all macros on a key are designated as `blocking`, we can guarantee that only one of them, the first one to satisfy its execution condition which can in turn simplify what conditions the other macros need to be aware of. 
```lua

-- pressing "a" if shift is pressed, and "b" if not.
k.m3 = { 
      -- if shift is pressed this macro will run and block the second macro on the key.
      { "a" ,  mkey = "gs" blocking = true },
      
       "b" -- We don't need any conditions because the execution only arrives here if the shift key wasn't pressed.
}

```
Note that if you use the [Link Macro]() the `blocking` option of the linked to macro will be ignored since it does not originate in the same event context; To reactivate you have to set the option on the link directly.

---
## documentation
* shorthand: `doc`

Documentation can be assigned to a macro for use in the Documentation Mode which will display information about button functionality on your LCD screen or LCD emulator.

By default a macro will export a human readable summary of its name and functionality for Documentation mode but the `documentation` option overrides this export. However, if the documentation text is prepended with a `+`, the macro will export the generated summary *in addition* to the text content.  
For more details see [Documentation Mode]().
```lua

-- This macro outputs the content of its 'documentation' property in documentation mode
k.m3 = {"a", documentation = "presses the 'a' key" }

-- Outputs its documentation in addition to its exported value (which in this case is just "b")
k.m4 = {"b", documentation = "+presses the 'b' key"}

```
---
## unlock
To prevent stuck keys and other accidental binding mishaps Revenant employs a "locking" method that ensures that if a macro meets its conditions to trigger when a mouse button is pressed it will act as if the conditions are still met when the button is released even when in reality they might not be.  
If for example a button triggers the `a` key when shift is pressed and `b` when it isn't, it's possible that the shift key is released before the mouse button is released. Viewed naively this would mean that the button should now attempt to release `b` instead of `a` since the shift condition is no longer met, which leaves the `a` stuck pressed down.  
Locking prevents this issue.  
But maybe there is some Macro configuration in which we *want* the macro triggers to be evaluated both on `down` *and* `up` events and this is what the unlock option does.

Locking applies to 5 of the generic macro options previously discussed:

* `area`
* `condition`
* `mkey`
* `mode`
* `gshift`

Each option can be unlocked separately, but `unlock` also accepts a list to unlock multiple checks.
```lua

-- The 'gshift' check is unlocked, so if this button is released after the G-shift key, the "a" key remains pressed.
k.m3 = { "a" gshift = 1, unlock = "gshift" }

-- Providing a list to unlock both gshift and mode checks.
k.m4 = { "b" gshift = 1, mode = 2 unlock = { "gshift", "mode" } }

```
---
## process

The `process` option accepts a function that is applied to both the command and options of the macro.  
Note that this function only runs once when the macro is initialized and **not** whenever it is triggered. Likely only useful in obscure edge cases.

When the function is called, the command part is passed as the first argument, and the options as the second and it needs to return both in the same order.
```lua

-- You would think this macro would change the mode to 1 but it actually changes it to 2 because the process function doubles the 1.
k.m3={ 1 type = "mode" process = function(arg,opts) return {arg[1] * 2}, opts end}

```
---
## template
The `template` option is a boolean value that designates a macro as accessible only once instantiated via an instance macro.  
Template macros cannot be executed directly and the contents of their commands and options are not linted or processed, allowing them to contain even invalid definitions (but still valid lua syntax).  
The purpose of allowing invalid template macros is allowing for the `update` and `substitute` functionality of instance macros to "complete" the template and finally parse it as a valid macro. For details see the [Instance Macro]() documentation
```lua

-- Nothing happens when this button is pressed because the macro is a template.
-- It generally makes sense to define templates in the library table of your profile instead of a key.
k.m3={ type="sequence","abc", 300, "def", template = true,  name = "example"}

-- Once parsed by an instance macro, the action of the "example" macro are no longer a template and can be executed.
k.m4 = { type="instance","example" }

```

# Asynchronous Execution Options
A number of macros are capable of running asynchronously. This includes the [Sequence Macro](), the [Mouse Position Macro]() and the [Function Macro]() in async mode.  
This means that these macros can execute their logic while other key events can still be processed, allowing multiple of such asynchronous macro to operate at the same time, which is accomplished using polling and coroutines.  

Asynchronous macros have a number of additional Macro Options that govern how their coroutines behave.  
For the sake of simplicity we will demonstrate these options mainly with the [Sequence Macro]().

## play
* shorthand: `p`

Define how the the Macro is triggered and played. Valid play modes are:

* **"normal"** *(default)* = Play the macro when the button is pressed down. The behavior of additional presses is defined via the [stack](#stack) option.
* **"toggle"** = Pressing the button once starts the execution, pressing it again cancels it.
* **"hold"** = The macro is played while the button is held down and canceled when the button is released.
* **"ptoggle"** = Works the same as the "toggle" mode but **pauses** the execution instead of aborting it. When the button is pressed again the macro continues where it left off.
* **"phold"** = Works the same as the "hold" mode but **pauses** the execution instead of aborting it on keyup. When the button is pressed down again the macro continues where it left off.

```lua

-- Example sequence printing "test1" and "test2" in a loop.
-- play mode "normal": Pressing the button once starts the sequence. 
-- Pressing it second time will restart the sequence again from the beginning (behavior can be changed via the "stack" option).
k.m3 = { type="sequence", "test1",200,"test2",200, loop=-1 , play="normal" }

-- play mode "toggle": Pressing the button once starts the sequence, pressing it again stops it.
-- When triggered again, the sequence restarts from the beginning.
k.m4 = { type="sequence", "test1",200,"test2",200, loop=-1 , play="toggle" }

-- play mode "hold": The sequence plays while the button is held down.
-- When held down again, the sequence restarts from the beginning.
k.m5 = { type="sequence", "test1",200,"test2",200, loop=-1 , play="hold" }

-- play mode "ptoggle": Pressing the button once starts the sequence, pressing it again pauses it.
-- When triggered again, the sequence starts again where it left off.
k.m6 = { type="sequence", "test1",200,"test2",200, loop=-1 , play="ptoggle" }

-- play mode "phold": The sequence plays while the button is held down and pauses on release.
-- When held down again, the sequence starts again where it left off.
k.m7 = { type="sequence", "test1",200,"test2",200, loop=-1 , play="phold" }

```

## stack
This option defines what happens when an async macro is triggered while another instance of the same macro is already running. There are 4 possible values:

* **0** *(default)*= Cancel and restart the macro from the beginning.
* **1** = Cancel the macro.
* **2** = queue up another run of the macro and execute it after the current run finishes. Multiple runs can be queued at once.
* **3** = Do nothing and simply ignore additional button presses of the same button while the macro is executing.

```lua

-- An infinite loop of printing from 1 through 5. With the stack value set to 0, any additional press of this button will cause this sequence to restart from 1 immediately. 
-- This is the default behavior.
k.m3 = { type="sequence", "1","2","3","4","5", loop=-1, stack=0 }

-- In this case the sequence is cancelled with a second press. Similar to the "toggle" play option.
k.m4 = { type="sequence", "1","2","3","4","5", loop=-1, stack=1 }

-- Here, the sequence does not naturally loop, but you can press the button before the end of the sequence is reached to make it start again *after* the current run has finished.
k.m5 = { type="sequence", "1","2","3","4","5", stack=2 }

-- After the first press the sequence continues to run, no matter how often the button is pressed again.
k.m6 = { type="sequence", "1","2","3","4","5", loop=-1, stack=3 }

```
## fragile

If set to `true` pressing any other button will cause the macro's execution to stop. When set to `false` the macro keeps playing even while other macros execute.  

The default value of this option is set according to the [fragileThreads]() option, with the exception of async function macros which are never fragile unless the option is explicitly set on the macro directly.

This option has no effect for sequence macros that are nested within another sequence.

```lua

-- Sequence looping indefinitely until cancelled
k.m3 = { type="sequence", "a","b","c","d", loop=-1, fragile=true }

-- Pressing this or any other button will cancel the sequence on m3.
k.m4="x"

-- without the cancel option (and fragileThreads set to false) this sequence will keep looping even when m4 is pressed.
k.m5 = { type="sequence", "a","b","c","d", loop=-1 }

```
Note that any fragile macros will be cancelled *before* the macro causing the cancellation executes its own functionality.
## interrupts

This option is similar to the [fragile](#fragile) option but only defines interactions between multiple asynchronous macros.

* **true** *(default)* = Cancels any other running asynchronous macros before playing, even if they are not `fragile`. Useful for when you want to manually control which macros cancel each other and which don't
* **false** = If another async is playing this macro will run at the same time.
* **"exclusive"** = Cancels other running async macros and runs in "exclusive" mode, meaning it can't be cancelled and blocks all input.
* **"exclusivePause"** = Runs in exclusive mode, but other async macros continue playing after its execution ends.

This option has no effect for sequence macros that are nested within another sequence.

The default value of this option can be set globally via the [defaultThreadInterrupt]() configuration.

If another async macro has its `fragile` option set to `true` either explicitly or through to the global default, setting this option to `false` or `"exclusivePause"` will **not** prevent it from being cancelled.
```lua

-- This is our control sequence that runs when the other action is triggered, it simply repeatedly outputs "test".
k.m3 = { type="sequence", "test",200, loop=-1 }

-- The default behavior. The m3 sequence is immediately interrupted when this sequence is executed.
k.m4 = { type="sequence", "abc", interrupts=true }

-- If the m3 sequence is running when this one is initiated the "abc" output will simply be interweaved into the repeated "test" outputs.
-- This means the actual output could be "atebsct" or a similar combination, depending on timing.
k.m5 = { type="sequence", "abc", interrupts=false}

-- Not only does the "exclusive" setting cancel m3 or any other running sequences, it also prevents any further macro action from executing while this sequence is running.
k.m6 = { type="sequence", "abc", interrupts="exclusive"}

-- Works the same way as "exclusive", but after this sequence finishes the m3 sequence unpauses and continues.
-- This can lead to an output such as "teabcest".
k.m7 = { type="sequence", "abc", interrupts="exclusivePause" }

```
## parallel
This option *forces* an async macro to run in its own thread.  
Most of the time this is already the case, so why do we need this option?
The answer is that async macros that run as child macros of a sequence will by default run in the same thread as their parent macro. This means that the parent macro will wait for the child sequence to finish before it continues with its next actions, making everything run consecutively.

But let's say we **want** a child macro to start executing an action that plays *while* the rest of the parent sequence just continues on, we can use this option to accomplish this.


```lua

-- This sequence uses the parallel option to move the mouse while typing the second part of its output at the same time.
k.m3 = { 
   type="sequence", 
   "I will start moving the mouse NOW!", 
   { type="mouseposition", {200, 200}, {200, -200}, {200, 200}, {200, -200}, relative = true, duration = 1000, parallel = true }, 
   " ...and I keep typing it's moving." 
}

-- This serious medical macro outputs "I might be having a stroke, call an ambulance!"
-- Because the child sequence does not have the "parallel" option set, it is executed in the same thread
k.m4 = {type="sequence", "I might be ", {t="s", "having a stroke,"}, " call an ambulance!"}

-- If we activate the parallel option, both key outputs happen at the same time and interweave.
-- The output becomes "I might be h acvailnlg  ana satmrbouklea,nce!"
-- Which fittingly looks like the mouse is indeed having a stroke.
k.m5 = { type="sequence", "I might be ", {t="s", "having a stroke,", parallel=true}, " call an ambulance!" }

```