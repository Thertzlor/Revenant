description
`type` value `group` or `g`

### Complete Syntax:
>`{ <mode>, type="mode"|"m" [, family=<option>, temporary=<boolean>, hardwareOnly=<boolean>] }`

Example:
```lua
--- Changes the mouse to mode number 2.
k.m3 = { 2, type="mode"}
--- Cycles through all available modes.
k.m4 = { 0, type="mode"}
```

# Basic Functionality
LGS defines 3 modes for most logitech devices, each with a different backlight.
By default, revenant will use these native modes as well, using the internal mode change macro to cycle between them.


## Automatic mode reset
One of the reasons I hardly used mouse modes in the base LGS software was that when you change the mode from 1 to 2 and your mouse profile changes, the mouse is still mode 2.  
I use secondary modes for specific sub-parts of games and programs, so launching a profile in mode 2, because the last profile was in mode 2 makes no sense. Especially since most profiles don't have any buttons defined in any mode besides 1.

To solve this issue


## Advanced Mode Management


# Options
## family


Example:
```lua
k.m3 = 
```
## temporary
Description

Example:
```lua
k.m3 = 
```
## hardwareOnly
Description

Example:
```lua
k.m3 = 
```