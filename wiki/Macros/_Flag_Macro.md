This macro allows you to set one or more boolean flags inside revenant which can be checked in `condition` queries.

`type` value `flag` or `f`

### Complete Syntax:
>`{ <string...|{string|boolean}> [, toggle=<boolean> ] ,  type="flag"|"f" }`

```lua

--- toggles a flag called "test_flag" when the button is pressed, toggles it back when released
k.m3 = { "test_flag", type="flag" }

--- sets the flag to `true` regardless of what value it was before
k.m5 = { { "test_flag" , true }, type="flag" }

--- This macro can only trigger when "test_flag" is true.
k.m6 = { "a", type="key", condition=".test_flag" }

```
# Functionality
This macro exists mostly because Revenant attempts to manage state without using "real" user defined lua variables.  
While it would be possible to define a local variable, set it in a `function` macro and directly put it in a condition, flags provide a way to do this managed to by Revenant itself, and more flag manipulation feature may be added in the future.  
Currently, only simple binary flags are supported.

The flag macro can either simply toggle a flag to the opposite value it currently is by specifying its name or set it to a specific `true`/`false` value by listing the name followed by the value in a table.


## Setting multiple flags
A macro may set multiple flags by listing more than one flag name:
```lua

--- toggles three flags at once.
k.m4 = { "flag_a", "flag_b", "flag_c" , type="flag" }

```
Setting multiple flags to specific values can also be accomplished by continually alternating flag names and boolean values in the nested table:
```lua

--- sets flag_a to false, flag_b to true and flag_c to false
k.m4 = { {"flag_a", false, "flag_b", true,  "flag_c", false} ,  type="flag" }

```
# Options
Besides the [General Macro Options]() the Flag Macro offers the following options to customize behavior:
## toggle
Instead of setting a flag only while the button is pressed down, the `toggle` option prevents the flag getting flipped again when the button is released.
Instead, the flag stays set until the button is pressed another time.
* **default value:** `false`
```lua

--- toggles "test_flag" when the key is pressed down without un-toggling it when releasing
k.m4 = { "test_flag", toggle=true, type="flag" }

```