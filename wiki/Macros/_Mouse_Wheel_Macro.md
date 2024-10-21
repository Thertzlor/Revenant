A macro to simulate scrolling your mouse wheel.

`type` value `mousewheel` or `w`

### Complete Syntax:
>`{ <number>, type="mousewheel"|"w" }`
```lua

--- scroll the mouse wheel up by 3 clicks
k.m3 = { 3 , type="mousewheel" }

--- scroll the mouse wheel down by 1 click
k.m4 = { -1 , type="mousewheel" }

```
# Functionality
Positive values scroll up, negative values scroll down.  
This macro simply passes any value it gets to the logitech API's `MoveMouseWheel` function.

# Options
*None*, other than the [General Macro Options]().