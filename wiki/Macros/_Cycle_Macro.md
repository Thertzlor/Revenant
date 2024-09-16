With the cycle Macro you can define multiple actions for a single button, advancing to the next with each button press.

`type` value `cycle` or `c`

### Complete Syntax:
>`{ <steps...>, type="cycle"|"c" [, cn/cancel=<number>, i/interval=<number>, limit=<number>, finish=<option|macro>, inherit=<option>, range=<option>] }`
```lua

--- A simple example. cycles between pressing "a", "b" and "c", on the fourth press the cycle restarts.
k.m3 = {"a","b","c", type="cycle"}

--- We can even nest mutltiple cycles within each other, resulting in a cycle of "a","b","a","a","b","b","a","b","c".
k.m3 = {"a","b",{"a","b","c", type="cycle"}, type="cycle"}

```
# Functionality
The Cycle Macro offers an additional way to put more than one action onto a key, a feat normally borderline impossible using the LGS GUI.

Cycling between different actions and macro with each button press enables for example toggling menus on and off with one button when exiting the menu requires a different key, or, in action games, putting an entire combo attack on a single button while still controlling the button timing for individual presses manually.

## Named Links
Like the Sequence Macro, the cycle macro offers a quick method to link to other named macros by providing a table containing a single string. The string will be resolved to a link to the macro with that name.
```lua

-- Cycles between acting as "macro_a" and "macro_b", the "x" and "y" key respectively.
k.m3 = { {"macro_a"}, {"macro_b"} ,type="cycle" }

-- Defining the target macros
k.m4 = {"x", type="key", name="macro_a"}
k.m5 = {"y", type="key", name="macro_b"}

```
# Options
Besides the [General Macro Options]() the Cycle Macro offers the following options to customize behavior:
## cancel
* shorthand: `cn`

When a cycle macro is cancelled, it is set back to its initial position and its number of completed cycles is also reset to 0. The `cancel` option defines when this occurs.  
* If the option is set to `0` the cycle will not cancel unless it is externally cancelled from a [Control Macro]() or the entire profile is reloaded.  
This is the default value.
* If the `cancel` option is set to `1` the cycle will continue only as long as no other button is pressed. If another button is pressed, even if this does not cause any other macro to execute, the cycle will be cancelled and restart from the beginning when pressed again.
* If the `cancel` option is set to any positive number (except 1) the cancellation happens on a timeout. For example a cycle macro with a `cancel` option set to `500` automatically resets after 500 milliseconds. The cancel timer is reset with every activation of the cycle, so you can press the button after 450ms and it will only reset after *another* 500ms.
* If the the `cancel` option is set to any negative number the effects of the timing cancel and the button cancel are combined. A cycle with a cancel option of `-500` will cancel after 500ms of inactivity *or* if another button is pressed, whichever happens first.
```lua

-- resets back to "a" whenever another button is pressed.
k.m3 = {"a","b","c", type="cycle", cancel = 1 }

-- resets back to "a" after one second of inactivity.
k.m3 = {"a","b","c", type="cycle", cancel = 1000 }

-- resets back to "a" whenever another button is pressed OR after one second of inactivity.
k.m3 = {"a","b","c", type="cycle", cancel = -1000 }

```
The Configuration setting [separateDeviceCycles]() controls if button presses on one device family can cancel cycles on another device. 

## range
This option lets you start, end and initialize the cycle at any index you want.  
The accepted value is a table with one to three numbers:

> `{<start>[,<end>,<initial>]}`

* The first number is the *start* value, defaulting to `1`.
* The second number is the *end* value, defaulting to **the length of the command table**.
* The third number is the *initial position* value, defaulting to `1`.

Values have to be positive, `0` will be ignored.

***Start*** is the position the cycle will reset to after it reaches the end of the command.
For example, if you have a cycle with three positions and you set the *start* value to `2`, the cycle will start at position 1 but after completing will jump to position *2* and continue from there. The command at position 1 will not be reached again until the entire cycle is cancelled and restarted.
```lua

-- initially starts at 1 ("a") but after getting to 3 ("c") will cycle back to 2 ("b") and continues cycling between "b" and "c".
k.m3 = {"a","b","c", type="cycle", range = {2} }

```
***End*** is the position at which the cycle will restart. Normally a cycle will iterate through all of its positions but by setting the `end` value manually you can cut it short.  
A cycle with 3 positions with the end value set to `2` will only cycle between positions 1 and 2, never reaching 3.
```lua

-- The second value of the range option is 2, so when the macro reaches position 2 ("b"), it will never continue to 3 ("c"), but instead cycle back to 1 ("a").
-- since the first position of the range table is 0, it is ignored and the default value of 1 is used.
k.m3 = {"a","b","c", type="cycle", range = {0,2} }

```
***Initial Position*** is the position a cycle starts at. The difference between *Init* and *start* is that a cycle is only set to the *init* position when the profile is first loaded or right after the cycle is cancelled while the start position will be reached after every completed cycle.  
```lua

-- this macro starts at position 2 ("b") when the profile is first loaded or after being cancelled/reset.
k.m3 = {"a","b","c", type="cycle", range = {0,0,2} }

```
## interval
* shorthand: `i`

Choose how many steps to advance with each button press.  
If the length of the command table is not divisible by the interval the remainder will "overflow" into the next cycle, as seen in the example below.
* **default value:** `1`
```lua

-- Will cycle between "a" and "c", skipping "b" and "d" every time. 
k.m3 = {"a","b","c","d", type="cycle", interval = 2}

-- Results in a cycle of "a", "c", "b", "a", "c" and so on, as odd and even cycles end up skipping different positions.
k.m4 = {"a","b","c", type="cycle", interval = 2}

```
## limit
Normally, cycle macros cycle indefinitely but by setting the `limit` option you can choose for how many cycles the macro will run.

* **default value:** `0` (no limit)
```lua

-- after reaching "c" for the third time, the cycle does not return to "a".
-- instead it will continue to trigger "c", unless another "finish" value is set.
k.m3 = {"a","b","c", type="cycle", limit=3}

```
## finish
This option decides what happens on subsequent button presses after the macro hits its cycle limit.

There are four possible values:

* **`stall`** *(default)* = After reaching the cycle limit the button will continue triggering the last macro of the cycle.
* **`end`** = After reaching the cycle limit the button does nothing unless the cycle is reset.
* **`reset`** = The cycle is reset to its initial position, and the number of completed cycles is set back to 0.
* The fourth option is to provide a table that will be interpreted as a macro. The macro will be executed for every button press once the cycle limit is reached, similar to the `stall` option.

Naturally, if no `limit` option is set, this option has no effect.
```lua

-- same as the "limit" example, the macro continues to act as a "c" button after 3 cycles.
k.m3 = {"a","b","c", type="cycle", limit=3, finish="stall"}

-- After reaching "c" for the third time, pressing this button does nothing.
k.m4 = {"a","b","c", type="cycle", limit=3, finish="end"}

-- After reaching "c" for the third time, resets the number of completed cycles and starts back act "a"
-- For all practical purposes this is the same as the cycle simply having no limit.
k.m5 = {"a","b","c", type="cycle", limit=3, finish="reset"}

-- In the following example "reset" DOES make a difference:
-- This cycle initializes at "a" but after hitting "c" cycles back from "b" for the next two cycles.
-- Finally, after reaching "c" for the third time it is reset back to "a" and completes another 3 cycles before resetting again.
k.m6 = {"a","b","c", range={2,0,1}, type="cycle", limit=3, finish="reset"}

-- By putting a key macro into the finish option, this button will start acting as a "d" key after copmpleting its cycle 3 times.
-- Any type of macro can be used.
k.m7 = { "a","b","c", type="cycle", limit=3, finish={"d",type="key"} }

```
## inherit

This option decides what happens on subsequent button presses after the macro hits its cycle limit.

There are four possible values:

* **`status`** *(default)* = The child cycle will share status option like number of completed cycles and initial position with its parent.
* **`timing`** = The parent and child cycle will share the same clock timer.
* **`all`** = The child cycle will inherit both status and timing properties.
* **`none`** = The child cycle is completely autonomous.

```lua

-- Inheriting the status is the default behavior. When the parent's position is reset after 2 seconds, the nested cycle's position is reset too.
k.m3 = { "a","b",{"c","d","e", type="cycle", inherit="status"}, cancel=2000, type="cycle"}

-- Inheritance is turned off, even if the position of the parent resets, the nested cycle will continue from its last position once triggered again.
k.m4 = { "f","g",{"h","i","j", type="cycle", inherit="none"}, cancel=2000, type="cycle"}

```