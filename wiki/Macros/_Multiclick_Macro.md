A macro to execute different actions with a single key via double clicks, triple clicks and so on.

`type` value `multiclick` or `t`

### Complete Syntax:
>`{ <entries...>, type="multiclick"|"t" [, timer=<number>, timeMode=<option>, triggerMode=<option>] }`

```lua

-- A single click prints "a", a double click prints "b"
k.m3 = { "a","b", type="multiclick"}

```
# Functionality
With the Multiclick macro you can define double click actions that work pretty much exactly like normal double clicks in Windows.  
It also works with an arbitrary number actions beyond two clicks.

Any other type of macro can be nested as an action within a Multiclick macro.

## Named Links
Like the Sequence Macro, the multiclick macro offers a quick method to link to other named macros by providing a table containing a single string. The string will be resolved to a link to the macro with that name.
```lua

-- Ececutes macro_a ("x") on a single click and macro_b ("y") on a double click.
k.m3 = { {"macro_a"}, {"macro_b"} ,type="multiclick" }

-- Defining the target macros
k.m4 = {"x", type="key", name="macro_a"}
k.m5 = {"y", type="key", name="macro_b"}

```
# Options
Besides the [General Macro Options]() the Multiclick Macro offers the following options to customize behavior:

## timer
The number of milliseconds during which the button has to be pressed again in order to count as a double click (or other multiclick)

The default value for the multiclick timer is 200ms and can be set globally via the [multiClickTime]() Option in the profile configuraion.

Since the macro has to wait for inputs during that time, this is also the minimum amount of delay that a multiclick macro will have for its first action action.  
However, once the number of presses is equal to the number of actions on the macro, the last action will be executed immediately since there's nothing else to wait for.
```lua

-- Here you have 250ms for the second "click" of the button in order to output "b" instead of "a".
k.m3 = { "a","b", timer=250, type="multiclick"}

-- This button waits 400ms for the second click.
k.m4 = { "c","d", timer=400, type="multiclick"}

```
## timeMode
Decides how the value defined in the `timer` option is interpreted. The default "relative" behavior interprets the timer to be relative to the last press of the button, while the alternative "absolute" option starts the timer only once after the first press.

For multiclick macros with only 2 actions this option is irrelevant, since they only have a single interval in any case.

valid time modes are:

* **`"relative"`** *(default)* = The countdown for the timer resets after every press.
* **`"absolute"`** = **All** presses need to happen within a single interval of the timing value. 
```lua

-- after pressing the button once ('a') you have 300ms to press it another time ('b'), and then another 300ms after the second press for the third ('c'), so 600ms in total for three presses.
k.m3 = { "a","b","c", timeMode="relative", timer=300, type="multiclick"}

-- In order to output "f" you have to press this button 3 times within 300ms.
k.m4 = { "d","e","f", timeMode="absolute", timer=300, type="multiclick"}

```
## triggerMode
Besides the `normal` trigger mode which executes only the action for the current number of clicks, the the `stack` mode allows all previously "passed" click actions to be executed as well. 

valid trigger modes are:

* **`"normal"`** *(default)* = Executes the action of the currently reached position.
* **`"stack"`** = Executes all actions *up to and including* the currently reached position.
```lua

--- single click presses "a", double click "b" and triple click "c"
k.m3 = { "a","b","c", type="multiclick", triggerMode="normal"}

--- single click presses "a", double click writes "ab", triple click writes "abc"
k.m4 = { "a","b","c", type="multiclick", triggerMode="stack"}

```