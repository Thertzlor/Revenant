This macro deletes either all or a specific number of saved past button presses. Its main use is modifying the behavior of the [button history condition]().  
* `type` value: `wipehistory` or `wh`
### Complete Syntax:
>`{ [<number> ,] type="wipehistory"|"wh" }`

Example:
```lua
k.m3 = "a"
-- only triggers 
k.m4 = { "b", condition = "^m3-m3-m3" }
k.m5 = { type = "wipehistory" }
```

# Functionality
As shown in the example above

# Options
*None*, other than the [General Macro Options]().