Conditions are a powerful tool for advanced control over macros. Whereas general macro trigger options like g-shift mode and area lets you check for global conditions that are present in every profile, the condition option can be used to define custom triggers based on the state of specific macros, buttons, flags etc, allowing you to set up relationships between buttons.

Conditions are expressed in as a single number or string value but they can also be combined and grouped.

### Complete Syntax:
>`<designation>` (for a single condition)  
>or as a Condition Object for more complex use cases:  
>`{ <designation|Nested Condition Object>... [, logic=<option>] }`

# Condition Types
The following types of condition checks are available:
* **`number`** / **`"name"`**: key with number/name currently pressed
* **`-number`** / **`"-name"`**: key with number/name NOT currently pressed
* **`"^name"`**: key "name" was last pressed
* **`"|name"`**: a key that was not "name" last pressed.
* **`":name"`**: sequence "name" running
* **`"~name"`**: sequence "name" not running
* **`".name"`**: variable "name" in rv.flags is set to true
* **`"*name"`**: variable "name" in rv.flags is not set to true

Note that the button checks do not care about macro executions on buttons, only if it was pressed at all.  
For example if you press mouse button named m3 and its macro does not execute because its condition was not met the condition "button m3 was last pressed" or `^m3` will be met for the next button's check.

Example:
```lua
-- Triggers "a" key only if mouse button 3 is currently pressed.
k.m4 = {"a", condition = 3}

-- Sequence Triggers only if the button named "m4" is currently pressed.
k.m5 = {"b", 500, "c" ,500, "a", type="sequence" , loop = 6 , name="seq", condition = "m4"}

-- Triggers x key but only if the sequence called "seq" (on m5) is currently running
k.m6 = {"x", condition = ":seq"}

-- Triggers y key but only if the sequence called "seq" (on m5) is NOT currently running
k.m7 = {"y", condition = "~seq"}
```
# Advanced History Queries
The `"^name"` notation lets us check which button was last pressed, but we can even go further. This history query can in fact *chain* multiple key names together, to check further back in time.  
Macros with a chained history query work like combination locks and will only trigger if specific buttons were pressed in a specific order.  
When writing chained history queries the order goes from first key pressed to last key pressed.

Example:
```lua
-- Triggers "a" only if preceded by m3, m4 , m5
k.m6 = {"a", condition = "^m5^m4^m3"}
```
Of course, we can also mix in negative checks by chaining the `"|"` notation, or mix both types of checks.
```lua
-- Triggers "a" key only if mouse button 3 is currently pressed.
k.m6 =
```

## Wildcards
## Key sequences
# Logic Modes
When you set more than one condition on a macro you can use the `logic` option to define how the different conditions should be evaluated.  
By default the conditions are evaluated in `and` mode, so all conditions have to be true.

The `logic` option accepts the following evaluation modes (however `and`/`or` should be sufficient for most use cases):

* `and`: True if all conditions in the list to evaluate to `true`.
* `or`: True if least one condition evaluates to `true`.
* `xor`: True if at least one condition has evaluates to `true` but not *all* of them do.
* `xnor`: True if *all* conditions evaluate to `true` or *all* conditions evaluate to `false`.
* `nand`: True if all conditions do *not* evaluate to `true`.
* `nor`: True if no condition evaluates to `true`.

Example:
```lua
-- 
k.m3 = {"a", condition = {4,5, logic ="or"} }
```
# Grouping and Nesting
You can also provide more than one list of conditions, as well as lists of lists with no limit on nesting or combining different logic modes.

Example:
```lua
k.m3 =
```
