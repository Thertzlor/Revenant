With the cycle Macro you can define multiple commands for a single button, advancing to the next with each button press.

`type` value `cycle` or `c`

### Complete Syntax:
>`{ <steps...>, type="cycle"|"c" [, cn/cancel=<number>, i/interval=<number>, limit=<number>, finish=<option|macro>, inherit=<option>, range=<option>] }`


Example:
```lua
--- A simple example. cycles between pressing "a", "b" and "c", on the fourth press the cycle restarts
k.m3 = {"a","b","c", type="cycle"}

--- We can even nest mutltiple cycles within each other, resulting in a cycle of "a","b","a","a","b","b","a","b","c"
k.m3 = {"a","b",{"a","b","c", type="cycle"}, type="cycle"}
```

# Basic Functionality
Explanation
## Named Links
Like the Sequence Macro, the cycle macro offers a quick method to link to other named macros by providing a table containing a single string. The string will be resolved to a link to the macro with that name.

Example:
```lua
k.m3 = 
```
# Options
Besides the [General Macro Options]() the Cycle Macro offers the following options to customize behavior:
## cancel
When a cycle macro is cancelled, it is set back to its initial position and its number of completed cycles is also reset to 0. The `cancel` option defines when this occurs.  
* If the option is set to `0` the cycle will not cancel unless it is externally cancelled from a [Control Macro]() or the entire profile is reloaded.  
This is the default value.
* If the `cancel` option is set to `1` the cycle will continue only as long as no other button is pressed. If another button is pressed, even if this does not cause any other macro to execute, the cycle will be cancelled and restart from the beginning when pressed again.
* If the `cancel` option is set to any positive number (except 1) the cancellation happens on a timeout. For example a cycle macro with a `cancel` option set to `500` automatically resets after 500 milliseconds. The cancel timer is reset with every activation of the cycle.
* If the the `cancel` option is set to any negative number the effects of the timing cancel and the button cancel are combined. A cycle with a cancel option of `-500` will cancel after 500ms of inactivity *or* if another button is pressed, whichever happens first.

Example:
```lua
k.m3 = 
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

Example:
```lua
k.m3 = 

```
***End*** is the position at which the cycle will restart. Normally a cycle will iterate through all of its positions but by setting the `end` value manually you can cut it short.  
A cycle with 3 positions with the end value set to `2` will only cycle between positions 1 and 2, never reaching 3.

Example:
```lua
k.m3 = 

```
***Initial Position*** The difference between *Init* and *start* is that a cycle is only set to the *init* position when the profile is first loaded or right after the cycle is cancelled while the start position will be reached after every completed cycle.  

Example:
```lua
k.m3 = 
```
Another possible way to use the range option is in conjunction with [Instance Macros](). We could use the update syntax to tweak subsequent instances but this can quickly get convoluted.


Example:
```lua
k.m3 = 
```

## interval

Choose how many steps to advance with each button press.  
If the length of the command table is not divisible by the interval the remainder will "overflow" into the next cycle, as seen in the example below.
* **default value:** `1`


Example:
```lua
-- Will cycle between "a" and "c", skipping "b" and "d" every time. 
k.m3 = {"a","b","c","d", type="cycle", interval = 2}

-- Results in a cycle of "a", "c", "b", "a", "c" and so on, as odd and even cycles end up skipping different positions.
k.m4 = {"a","b","c", type="cycle", interval = 2}
```
## limit
Normally, cycle macros cycle indefinitely but by setting the `limit` option you can choose for how many cycles the macro will run.
* **default value:** `0` (no limit)

Example:
```lua
k.m3 = 
```
## finish
Choose what happens after the macro hits the cycle limit.
* **default value:** `stall`

There are four possible values:

* `stall`: After reaching the cycle limit the button will continue triggering the last macro of the cycle.
* `end`: After reaching the cycle limit the button does nothing unless the cycle is reset.
* `reset`: The cycle is reset to its initial position, and the number of completed cycles is set back to 0.
* The fourth option is to provide a table that will be interpreted as a macro. The macro will be executed for every button press once the cycle limit is reached, similar to the `stall` option.

Naturally, if no `limit` option is set, this option has no effect.

Example:
```lua
k.m3 = 
```
