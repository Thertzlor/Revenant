A Macro that executes different actions, key outputs or any other kind of macro, depending on how long the button has been pressed down.

`type` value `holdkey` or `h`

### Complete Syntax:
>`{ type="holdkey"|"h", <entries...>  [, holdTime=<number>, init=<boolean>, holdMode=<option>, release=<option> ] }`
```lua

-- A basic hold key:
-- Hold for less than 200ms to output "a", hold between 200ms and 400ms to output "b".
-- After 400ms the macro automatically outputs "c".
k.m3 = { type="holdkey","a","b","c", holdTime=200 }

-- A more advanced hold key example for a "charged move" input:
-- In words: When the key is pressed, "x" is pressed down immediately because of the "init" option.
-- If the key is released within less than a second "x" is simply released.
-- If released later than 1 second, the release of "x" is followed by an output of "yz" (but only after keyup because of the "hold" release mode).
k.m4 = {
   type = "holdkey",
   { "x", type = "keydown" }, 
   { "x", type = "keyup", name = "upX" }, 
   1000,
   { {"upX"}, "yz", type = "sequence" }, 
   release = "hold", init = true
} 

```
# Functionality
Triggering different actions for tapping and holding a key is something that quite a few games and programs implement, but for software that doesn't natively support this, we can use this macro to directly achieve this functionality on our mouse.

The hold key macro can receive 3 types of commands: 
* **strings**, interpreted as key outputs.
* **numbers**, interpreted as manual timing intervals between the previous and next action
* and **tables**, interpreted as sub-macros.

Any kind of other macro can be nested in a hold key macro as an action.
## Named Links
Like the Sequence Macro, the hold key macro offers a quick method to link to other named macros by providing a table containing a single string. The string will be resolved to a link to the macro with that name.

```lua

-- executes macro_a or macro_b depending on whether the key was held for 200ms or more.
k.m3 = { type="holdkey", {"macro_a"}, 200, {"macro_b"} }

-- Defining the target macros.
k.m4 = { type="key", "x", name="macro_a" }
k.m5 = { type="key", "y", name="macro_b" }

```

## Empty Actions
By including an empty string in your command, you can designate specific intervals in your Hold Key Macro during which releasing the macro does nothing.

```lua

-- This hold key does nothing if released after less than 300ms, if held longer it outputs "hello"
k.m3 = { type="holdkey", "", 300, "hello" }


-- Empty actions can be positioned anywhere.
-- If held for less than 300ms this macro outputs "a", if held between 300 and 600ms it does nothing, and if held for longer than 600ms it outputs "c".
k.m4 = { type="holdkey", "a", 300, "", 300, "c" }

```

## Cancelling Held Keys
You can stop a hold key macro from triggering any action it *would* have triggered on release with a [Control Macro]().  
This is useful for when have a hold key macro held down and you change your mind and don't actually want to trigger anything.


```lua

-- A simple example Hold Key Macro.
k.m4 = { type="holdkey","a","b","c", holdTime=200, release="hold", name = "holder"}

-- Press this key while the hold key named "holder" is still held down to prevent any action on release.
-- This works well if the hold key is on the thumb-pad an the control on one of the buttons you reach with another finger. 
k.m3 = { type="macrocontrol", "holder" }

```

# Options
Besides the [General Macro Options]() the Hold Key Macro offers the following options to customize behavior:
## holdTime
This option determines the default interval between different actions on the macro.  
This value can be overridden my manual timing settings between two actions. 

* **default value:** `200`
```lua

-- If released earlier than 200ms outputs "a", otherwise outputs "b"
k.m3 = { type="holdkey", "a","b", holdTime= 200 }

-- If released earlier than 400ms outputs "c", otherwise outputs "d"
k.m4 = { type="holdkey", "c","d", holdTime= 400 }

```
## init
If this option is set to `true`, the first action of the macro's command will be executed when the button is pressed down, while the hold time logic decides which action will be performed when the button is released.  
This of course means that the macro performs two actions in total.
* **default value:** `false`
```lua

--default hold key logic.
-- Nothing happens when the button is pressed.
-- The key outputs "a", "b", or "c" if the button has been held for less than 200ms, 400ms or 600ms respectively
k.m3 = { type="holdkey", "a","b","c", holdTime= 200 }

-- With the "init" option set "a" is immediately typed when this button is pressed.
-- The button then outputs either "b" when held for less than 200ms otherwise the output is "c" 
k.m4 = { type="holdkey", "a","b","c", holdTime= 200, init=true }

```
## holdMode
This option controls how timing settings are interpreted.

* **`"relative"`** *(default)* = Any timing value is interpreted as the number of milliseconds since the last action step.
* **`"absolute"`** = Any timing value is interpreted as the number of milliseconds since the button has been pressed down.
* **`"additive"`** = Any manual timing value is interpreted as a number of milliseconds to be added to the default hold time of the macro. Can be negative.
 
```lua

-- The default behavior: each timing value is the number milliseconds between the current and next step. 
-- 0ms - 200ms = "a"
-- 201ms - 400ms = "b"
-- 401ms+ = "c"
k.m3 = { type="holdkey", "a",200",b",200,"c", holdMode="relative" }

-- The same timings as m3 in "absolute" mode: each timing value is the number milliseconds since the button has been pressed. The second manual value is 400 because the second step has not "reset" the timer.
-- 0ms - 200ms = "a"
-- 201ms - 400ms = "b"
-- 401ms+ = "c"
k.m4 = { type="holdkey", "a",200",b",400,"c", holdMode="absolute" }

-- In the additive mode, any manual timing values are added to the default holdTime value, in this case 200ms. Use positive values for longer steps, or negative values for shortened steps.
-- 0ms - 300ms (0 + 200 + 100) = "a"
-- 301ms - 450ms  (300 + 200 + (-50)) = "b"
-- 451ms+ = "c"
k.m4 = { type="holdkey", "a",100",b",-50,"c", holdTime = 200, holdMode="additive" }

```
## release
This option controls the Hold Key Macro's auto release functionality. The autorelease works by waiting until the minimum time required to trigger the last action of its command and then executing that action, even if the button has not been released yet (Releasing the button afterwards does nothing).  
This is useful if you want your hold key actions to still be performed as fast as possible.

This option accepts the following values:

* **`"auto"`** *(default)* = Once the button has been pressed long enough to trigger the macro's final action, that action will be executed immediately without waiting for the button to be released. 
* **`"hold"`** = The macro will always wait until the button is no longer held down before executing any action.


```lua

-- The default behavior: after 200ms the key outputs "b", even if not released, but if released earlier it outputs "a"
k.m3 = { type="holdkey", "a","b", holdTime= 200, release = "auto" }

-- Nothing happens until the button is released. If released after less than 200ms the button outputs "a", after more than 200ms it outputs "b".
k.m3 = { type="holdkey", "a","b", holdTime= 200, release = "hold" }

```