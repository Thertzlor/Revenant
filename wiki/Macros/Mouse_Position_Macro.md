A macro which enables repositioning the mouse, supporting instantaneous movement, movement over time and multiple steps.
`type` value `mouseposition` or `p`

### Complete Syntax:
>`{ type="mouseposition"|"p", <coordinate|coordinates[]>  [, screen=<number>, relative=<boolean>, duration=<number>, durationMode=<option>, velocity=<number>, p/play=<option>, stack=<option>, fragile=<boolean>, interrupts=<boolean|option> ] }`
```lua



-- Move the mouse in a triangular pattern, 500px wide and 500px high within 1.5 seconds.
k.m12 = { type = "mouseposition", {250, -500}, {250, 500}, {-500}, relative = true, duration = 1500 }

```
# Functionality


## Multiple Movement Points


### Individual adjustments


## Adjusting Movement lag
There is no actual logitech API for continous mouse movement. It is instead accomplished by setting different absolute mouse positions at every polling event.  
Unfortunately Windows does not move the mouse instantly, meaning at very high polling rates of 1 or 2ms the movement doesn't keep up, and the pointer moves slower than the macro intends.

Revenant can account for this by comparing the actual position of the mouse with where it *should* be and adjusting the movement rate accordingly[^1].  
This behavior is activated by the [offsetMovementLag]() profile option, which is enabled by default.

However, it still takes Revenant some time do determine what exact adjustment is necessary, so the first mouse movement after the profile is loaded may be slow for about half a second until the correct offset factor is determined.  
This effect can be avoided with the [defaultLagFactor]() profile option, which makes Revenant assume some default amount of lag when the profile is loaded that will then be refined by the lag offset logic.

To find a good `defaultLagFactor` value (which may be different for different computers), it is recommended to execute the [Revenant Debug Profile]() which has a movement macro that continuously logs the calculated lag offset to the console. Once this value has stabilized, it should be set as your `defaultLagFactor` in your configuration.


[^1]: Adjustment works for example by moving 4 steps every 4ms, so windows has time to execute the movement. This has no bearing on the perceived smoothness of the movement because such intervals are still much faster than standard monitor refresh rates.

# Options
Besides the [General Macro Options]() the Mouse Position Macro offers the following options to customize behavior:
## screen
Defines on which screen the coordinates of this macro are located.  
Defaults to the main monitor for absolute movement and the current monitor for relative movement.
```lua

k.m3 = 

```
## relative
With the relative option set, the target position is interpreted as a distance relative to the current mouse position instead of an absolute point on the monitor.

In relative mode negative values may be used to indicate a position to the left or below the mouse position.
```lua

k.m3 = 

```
## duration
Sets the duration of mouse movements in milliseconds.  
If no duration is set, the mouse moves to its destination instantly.
```lua

k.m3 = 

```
## durationMode
Decides whether the value of the [duration](#duration) option is divided up between all steps or defines the duration of a single step.

* **`"total"`** *(default)* = The duration value refers to the overall duration of all movement steps in total.
* **`"step"`** = The duration value refers to the duration of a single movement step.

```lua

-- The default behavior.
-- The movement lasts 1.5 seconds in total, with three steps that's 500ms per step.
k.m12 = { 
   type = "mouseposition",
   {250, -500}, {250, 500}, {-500}, 
   relative = true, duration = 1500, durationMode = "total"
}

-- In the step mode, the movement takes 1.5 seconds per step, for a total duration of 4.5 seconds.
k.m12 = {
   type = "mouseposition",
   {250, -500}, {250, 500}, {-500},
   relative = true, duration = 1500, durationMode = "step",
}

```
## velocity
The velocity of movement, interpreted as pixels per second.

```lua

k.m3 = 
d
```
>[!IMPORTANT]
`duration` and `velocity` cannot be set at the same time.