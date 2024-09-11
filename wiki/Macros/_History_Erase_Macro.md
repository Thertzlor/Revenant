This macro deletes either all or a specific number of saved past button presses. 
* `type` value: `wipehistory` or `wh`
### Complete Syntax:
>`{ [<number> ,] type="wipehistory"|"wh" }`
```lua

k.m3 = "a"

-- only triggers if neither of the last three buttons pressed was m3.
k.m4 = { "b", condition = "|m3-|m3-|m3" }

-- If we press m3 followed by this button, m4 will be able to trigger again despite m3 having been the second to last button pressed.
k.m5 = { type = "wipehistory" }

```
# Functionality
As shown in the example above the main use of this macro is modifying the behavior of the [button history condition]().  
If the macro is defined without a command it will wipe the entire button history. Alternatively you can provide a number command to delete a specific number of button presses from the history starting from the most recent press.
```lua

-- Delete the entire history
k.m3 = { type = "wipehistory" }

-- Delete the last 4 entries in the button history
k.m4 = {4,  type = "wipehistory" }

```
# Options
*None*, other than the [General Macro Options]().