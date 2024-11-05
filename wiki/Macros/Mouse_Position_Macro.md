A macro which enables repositioning the mouse, supporting instantaneous movement, movement over time and multiple steps.
`type` value `mouseposition` or `p`

### Complete Syntax:
>`{ <coordinate|coordinates[]>, type="mouseposition"|"p" [, screen=<number>, relative=<boolean>, duration=<number>, durationMode=<option>, velocity=<number>, p/play=<option>, stack=<option>, fragile=<boolean>, interrupts=<boolean|option> ] }`
```lua

k.m3 = { type=""}

```
# Functionality
Explanation

## Multiple Movement Points

### Individual adjustments

# Options
Besides the [General Macro Options]() the Mouse Position Macro offers the following options to customize behavior:
## screen
Defines on which screen the coordinates of this macro are. Defaults to the main screen.
```lua

k.m3 = 

```
## relative
Description
```lua

k.m3 = 

```
## duration
Description
```lua

k.m3 = 

```
## durationMode

* **`"total"`** *(default)* = The duration value refers to the overall duration of all movement steps in total.
* **`"step"`** = The duration value refers to the duration of a single movement step.

```lua

k.m3 = 

```
## velocity
The velocity of movement, interpreted as pixels per second.
```lua

k.m3 = 

```