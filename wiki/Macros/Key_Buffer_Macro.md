This is an advanced key macro that adds one or more keys to a "buffer". The key will not be pressed at this point, but the next time another macro presses a key all buffered keys are prepended to the output.  
Buffers can be scoped to apply globally to a specific hardware family or the currently pressed key.

`type` value `keybuffer` or `kb`

### Complete Syntax:
>`{ <arg>, type="keybuffer"|"kb" [, scope=<option>, exclusive<boolean>] }`
```lua

--Adds the key "b" to the global key buffer
k.m3 = { "b", type="keybuffer", scope="global"}

--Adds the key "r" to the global key buffer
k.m4 = { "r", type="keybuffer", scope="global"}

-- This macro outputs the string "each"
-- if m3 was pressed first it will output "beach" 
-- If m4 was pressed first the output is "reach"
-- m3 is pressed followed by m4 and then m5, m5 will output "breach"
k.m5 = "each"

```
# Functionality
Explanation

The content of the key buffer is always parsed separately from the content of the actual output. For example even though `"*t"` is Revenant's shorthand for `ctrl + t`, if a buffer value of `"*"` is appended to a keypress of `"t"`, the output will be the literal asterisk character "*" followed by "t". 

# Options
Besides the [General Macro Options]() the Key Buffer Macro offers the following options to customize behavior:
## scope
Description
```lua

k.m3 = 

```
## exclusive
Description
```lua

k.m3 = 

```