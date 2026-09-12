The Revenant is unfortunately **not** powerful enough to bend time and undo your mistakes but it *can* modify the button presses it remembers.  
This macro deletes either all or a specific number of saved past button presses, or alters their timing data. 
* `type` value: `alterhistory` or `ah`
### Complete Syntax:
>`{ type="alterhistory"|"ah", [<number> , refresh = <boolean>]  }`
```lua

k.m3 = "a"

-- only triggers if neither of the last three buttons pressed was m3.
k.m4 = { "b", condition = "|m3-|m3-|m3" }

-- If we press m3 followed by this button, m4 will be able to trigger again despite m3 having been the second to last button pressed.
k.m5 = { type = "alterhistory" }

```
# Functionality
As shown in the example above the main use of this macro is modifying the behavior of the [button history condition](Condition-Syntax#key-series).  
If the macro is defined without a command it will wipe the entire button history. Alternatively you can provide a number command to delete a specific number of button presses from the history starting from the most recent one.
```lua

-- Delete the entire history
k.m3 = { type = "alterhistory" }

-- Delete the last 4 entries in the button history
k.m4 = { type = "alterhistory", 4 }

-- A value of 0 means that the currently pressed button is not kept in the history, nothing else is modified.
k.m5 = { type = "alterhistory", 0 }

```
# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options./Macro-Overview#general-macro-options) the Alter History Macro offers the following options to customize behavior:
## refresh
In addition to deleting entried from the button history we can also change timing data. The refresh option can be used to reset the timing value of the last pressed button to the current time. This can be used to manipulate the bahavior for macros using the `historyTimeout` option.

The refresh action is executed *after* the button press removal.

* **default value:** `false`
```lua

-- Type "a"
k.m3 = "a"

-- Type "b" but only if button m3 was pressed within the last second.
k.m4 = { "b", condition="^m3", historyTimeout=1000 }

-- Pressing this button will "refresh" the button data for having pressed m3.  
-- This means even if more than a second has passed, the m4 macro can trigger after m5 was pressed.
-- m5 itself is still wiped from the history.
k.m5 = { type="alterhistory", 0, refresh = true }


```