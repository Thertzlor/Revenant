A macro to simulate scrolling your mouse wheel.

`type` value `mousewheel` or `w`

### Complete Syntax:
>`{ type="mousewheel"|"w", <number> }`
```lua

--- scroll the mouse wheel up by 3 clicks
k.m3 = { type="mousewheel", 3 }

--- scroll the mouse wheel down by 1 click
k.m4 = { type="mousewheel", -1 }

```
# Functionality
Positive values scroll up, negative values scroll down.  
This macro simply passes any value it gets to the logitech API's `MoveMouseWheel` function.

# Options
*None*, other than the [General Macro Options](./Macro-Overview#general-macro-options).