A macro that modifies the sensitivity settings of the mouse.  
`type` value `setdpi` or `dpi`

### Complete Syntax:
>`{ type="setdpi"|"dpi", <dpi arg> [, <index>],  [, lcd=<boolean>, d/direct=<boolean>] }`
```lua

-- Set the DPI setting to the second position of your profile's current DPI table.
k.m3 = { type="setdpi", 2 }

-- Set a new DPI table for the current profile, set index to the second position 
k.m4 = { type="setdpi", {500,1000,2000}, 2 }

-- Set the DPI of your mouse directly to 3000 DPI.  
-- This will disable previously set DPI tables, so it's advised to either only use direct assignments or only table/index assignments. 
k.m5 = { type="setdpi", 3000, direct= true }

```
# Functionality
The LGS software can store a list of DPI settings (a maximum of 16) either globally or per profile, which allows the mouse sensitivity to be adjusted on the fly.  
The DPI macro is Revenant's interface for this functionality. By default it's assumed that you have defined a DPI table for your profile in LGS and the argument of the macro is used to set the active index of that table.
```lua

-- Press this button to activate the first sensitivity level of your DPI table.
k.m3 = { type="setdpi", 1 }

-- Press this button to activate the second sensitivity level of your DPI table.
k.m4 = { type="setdpi", 2 }

```
However you can also use the macro to define and index a new DPI table for the profile.  
This is done by passing a table of dpi values as the first argument of the macro, with an optional second argument, that controls at which position the new table should be indexed.
If the second argument is omitted the new table will be indexed at position 1.

```lua

-- Defines a new DPI table for this profile and initializes its third position, setting the mouse to 2000 DPI.
k.m3 = { type="setdpi", {500, 1000, 2000, 3000} , 3 }

-- defines another DPI table. Because no second index parameter was given this table is initialized at its first position (500 DPI).
k.m4 = { type="setdpi", {500, 1000, 1500, 2000} }

```

# Options
Besides the [General Macro Options]() the DPI Macro offers the following options to customize behavior:
## direct
* shorthand: `d`

Set the DPI of the mouse directly to the value specified in the macro's argument.  
This is basically a shorthand for setting the Profile's DPI table to be a single value table with only the selected value and indexing it at position 1.
* **default value:** `false`
```lua

-- Set the DPI to 800 and discard any previously active DPI tables.
k.m3 =  { type = "setdpi", 800, direct = true }

```
Because setting the DPI via the `direct` option causes all other DPI table settings to be discarded, other DPI macros or functions that attempt to set the index of the DPI table to another value will no longer work. It is suggested to either only index based DPI macros or only direct ones, not both.
## lcd
The `lcd` option controls if the adjustment of the DPI settings by the macro will be displayed on the Logitech LCD display and the lua console. 
* **default value**: `true`

```lua

-- Changes the DPI setting and outputs "Setting DPI index to 1" to LCD display and console.
k.m3 = { type="setdpi", 1 }

-- Changes the DPI setting without outputting anything.
k.m4 = { type="setdpi", 2, lcd=false }

```