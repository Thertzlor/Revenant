A macro that changes the sensitivity settings of the mouse.  
`type` value `setdpi` or `dpi`

### Complete Syntax:
>`{ <dpi arg> [, <index>], type="setdpi"|"dpi" [, lcd=<boolean>, d/direct=<boolean>] }`
```lua

-- Set the DPI setting to the second position of your profile's current DPI table.
k.m3 = { 2, type="setdpi"}

-- Set a new DPI table for the current profile, set index to the second position 
k.m4 = { {500,1000,2000}, 2,  type="setdpi"}

-- Set the DPI of your mouse directly to 3000 DPI.  
-- This will disable previously set DPI tables, so it's advised to either only use direct assignments or only table/index settings. 
k.m5 = { 3000, type="setdpi", direct= true}


```
# Functionality
The LGS software can store a list of DPI settings (a maximum of 16) either globally or per profile, which allows the mouse sensitivity to be adjusted on the fly.  
The DPI macro is Revenant's interface for this functionality. By default Revenant assumes that you have defined a DPI table for your profile in LGS and uses the argument of the macro to set the active index of that table.
```lua

-- Press this button to activate the first sensitivity level of your DPI table.
k.m3 = {1, type="setdpi"}

-- Press this button to activate the second sensitivity level of your DPI table.
k.m4 = {2, type="setdpi"}

```
However you can also use the macro to define and index a new DPI table for the profile.  
This is done by passing a table of dpi values as the first argument of the macro, with an optional second argument, that controls at which position the new table should be indexed.
If the second argument is omitted the new table will be indexed at position 1.

```lua

-- Defines a new DPI table for this profile and initializes its third position, setting the mouse to 2000 DPI.
k.m3 = { {500, 1000, 2000, 3000} , 3, type="setdpi"}

-- defines another DPI table. Because no second index parameter was given this table is initialized at its first position (500 DPI).
k.m4 = { {500, 1000, 1500, 2000}, type="setdpi"}

```

# Options
Besides the [General Macro Options]() the DPI Macro offers the following options to customize behavior:
## direct
* shorthand: `d`

This is basically a shorthand for setting the Profile's DPI table to be a single value table with only the selected value and indexing it at position 1.
```lua

k.m3 = 

```
## lcd

* **default value**: `true`

Description
```lua

k.m3 = 

```