Conditions are a powerful tool for advanced control over macros. Whereas general macro trigger options like g-shift mode and area lets you check for global conditions that are present in every profile, the condition option can be used to define custom triggers based on the state of specific macros, buttons, flags etc, allowing you to set up complex relationships between buttons on your device(s).

Simple conditions can be expressed as a single number or string value, for more complex uses they are organized into tables.

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
* **`".name"`**: "name" in rv.flags is set to true
* **`"*name"`**: "name" in rv.flags is not set to true

Note that the button checks do not care about macro executions on buttons, only if it was pressed at all.  
For example if you press mouse button named m3 and its macro does not execute because its condition was not met the condition "button m3 was last pressed" or `^m3` will be met for the next button's check.
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
The positive (`^`) and negative (`|`) button history checks have some additional syntax to test for more complex conditions.
## Key Series
The `"^name"` notation lets us check which button was last pressed, but we can even go further. This history query can in fact *chain* multiple key names together, to check further back in time.  
Macros with a chained history query work like combination locks and will only trigger if specific buttons were pressed in a specific order.  
When writing chained history queries the order goes from first key pressed to last key pressed.
Note that when chaining checks, positive tests do not need to be prepended with `^` except in the very first position.
```lua

-- Triggers "a" only if preceded by m3, m4 , m5
k.m6 = {"a", condition = "^m3-m4-m5"}

```
Of course, we can also mix in negative checks by chaining the `"|"` notation, or mix both types of checks.  
```lua

-- A sequence of negated checks.
-- This button triggers if any button besides m3 was pressed followed by any button besides m4 and any button besides m5.
k.m6 = {"a", condition = "|m3-|m4-|m5"} 

-- Mixing positive and negative checks. 
-- This button triggers if any button besides m3 is pressed followed by m4 followed by anything besides m5.
-- For example simply press m4 three times followed by m6. 
k.m7 = {"a", condition = "|m3-m4-|m5"}

```
The maximum number of button presses that can be queried into the past is defined by the [historyDepth](./Options-Documentation#historydepth) option in the profile configuration.

## Wildcards
In a button check the hash (`#`) symbol acts as a wildcard. If used in the first position of a button check it will validate on any device, if used in the second position it will validate on any button number.  
And finally a check for `##` will always validate to `true` for any button.
```lua

-- Triggers "a" only if preceded by any button on the mouse
k.m5 = {"a", condition = "^m#"}

-- Triggers "b" only if preceded by button 4 on any device, mouse, keyboard or lhc
k.m6 = {"b", condition = "^#4"}

-- Triggers "c" only if preceded by m3, followed any other key on any device.
k.m7 = {"c", condition = "^m3-##"}

```
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
```lua

-- "a" can be pressed if either key 4 or 5 is pressed down.
k.m3 = {"a", condition = {4,5, logic ="or"} }

```
# Grouping and Nesting
You can also provide more than one list of conditions, as well as lists of lists with no limit on nesting or combining different logic modes.
```lua

-- An example of grouped and nested conditions:

k.m3 = {
   "x", type="key",
   -- "x" can only be pressed if either the seqA and seqB sequence macros are both running or the "flagA" flag is set but "flagB" is not.
   condition = {
                  {
                     ":seqA",":seqB",
                     logic = "and"
                  },
                  {
                     ".flagA","*flagB",
                     logic = "and"
                  },

                  logic = "or"
               }
}

k.m4 = {
   -- cycle between pressing "1" 20 times and pressing "2" 20 times in 300 ms intervals. 
   { "1", 300, type="sequence", loop=20, name="seqA"}, { "2" ,300, type="sequence", loop=20, name="seqB"},
   type = "cycle"
}

-- two buttons which just toggle flags
k.m5 = {"flagA" , type = "flag"}
k.m6 = {"flagB" , type = "flag"}

```
