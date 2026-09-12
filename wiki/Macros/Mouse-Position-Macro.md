A macro which enables repositioning the mouse, supporting instantaneous movement, movement over time and multiple steps.
`type` value `mouseposition` or `p`

> [!Caution]
It's recommended to disable the `Acceleration (Enhance Pointer Precision)` option in your LGS Pointer Settings, as it is known to interfere with programmatic position measurements.

### Complete Syntax:
>`{ type="mouseposition"|"p", <coordinate|coordinates[]>  [, s/screen=<number>, r/relative=<boolean>, d/duration=<number>, v/velocity=<number>, durationMode=<option>, p/play=<option>, stack=<option>, fragile=<boolean>, interrupts=<boolean|option> ] }`
```lua

---@type ProfileTemplate, Revenant
local profile = ...
local k = profile.key

-- Minimal config for a single full HD primary monitor (same as Revenant's default).
profile.config = {  monitors = {1920,1080} }

-- Position the mouse in the middle of the screen.
k.m3 = { type = "mouseposition", {"50%","50%"} }

-- Move the mouse in a triangular pattern, 500px wide and 500px high within 1.5 seconds.
k.m4 = { type = "mouseposition", {250, -500}, {250, 500}, {-500}, relative = true, duration = 1500 }

```

>[!IMPORTANT]
In order for this macro to work correctly at least your primary monitor's resolution needs to be correctly configured in the current profile, see [Monitor Configuration](./Monitor_Configuration) for reference.  
All following examples assume a 1920x1080 monitor for simplicity, which is also what Revenant assumes as default if no manual configuration is provided.

# Functionality
The mouse position macro moves the mouse to one or more specific points that can either be defined as positions in pixels or a percentage of the monitor's resolution.

A basic position is simply a table with an x and y coordinate. Any value written as a number (e.g `50`) is a pixel value and anything written as a percentage string (`"50%"`) is obviously a percentage.

If the y portion of a position is left out, the y value is assumed to equal the x value.

```lua

-- Put the mouse into the bottom left corner of the screen.
k.m3 = { type = "mouseposition", {0,0} }

-- Put the mouse in the exact middle of the screen.
-- Note how the second value doesn't need to be specified
k.m4 = { type = "mouseposition", {"50%"} }

-- Put the mouse in the middle of the screen vertically, 10 pixels from the bottom.
-- As you can, see mixing percentages and pixels is acceptable.
k.m4 = { type = "mouseposition", {"50%",10} }

```

## Multiple Movement Points
Mouse position macros can define multiple points that the cursor will move between in sequence, allowing you to build arbitrarily shaped movements.

Setting multiple points is generally only useful if the [duration](#duration) or [velocity](#velocity) option is set, since otherwise the mouse will jump to the final position immediately.

```lua

-- A Macro describing a zig-zag mouse movement.
k.m3 = { type = "mouseposition", {"30%","45%"}, {"40%","55%"},{"50%","45%"},{"60%","55%"},{"70%","45%"} duration = 2000 }

```
While Revenant is moving the cursor, it has complete control over it until the movement ends. If you attempt to move the mouse manually while a Mouse Position Macro is in progress, the mouse will simply snap back to its predetermined path on the next polling event.

### Individual Point Adjustments
The options for [relative](#relative) and [duration](#duration)/[velocity](#velocity) can be set for individual movement points, and if set will override that options value on the macro itself.

```lua

-- The first movement is relative, the second movement is absolute.
k.m3 = { type = "mouseposition", {300,300, relative=true}, {600,600}, duration = 1000 }

-- The first movement is relative, the second movement is absolute.
k.m3 = { type = "mouseposition", {300,300, relative=true}, {600,600}, duration = 1000 }

```

>[!TIP]
You can also use the shorthand names for `relative`,`duration` and `velocity` (`r`,`d`,`v`) in individual point adjustments.

Note however that the macro in general is not aware of timing adjustments to individual steps.  
For example, in a mouse movement macro with four steps and a duration of 1000ms, each step will normally take 250ms, but if one of the steps is manually set to take 500ms, the macro will still simply act as if it took 250ms, so the *actual* duration of the movement is 1250ms. This might be fixed in the future.  

## Adjusting Movement lag
There is no actual logitech API for continuous mouse movement. It is instead accomplished by setting different absolute mouse positions at every polling event.  
Unfortunately Windows does not move the mouse instantly, meaning at very high polling rates of 1 or 2ms the movement doesn't keep up, and the pointer moves slower than the macro intends.

Revenant can account for this by comparing the actual position of the mouse with where it *should* be and adjusting the movement rate accordingly[^1].  
This behavior is activated by the [offsetMovementLag](./Options-Documentation#offsetmovementlag) profile option, which is enabled by default.

However, it still takes Revenant some time do determine what exact adjustment is necessary, so the first mouse movement after the profile is loaded may be slow for about half a second until the correct offset factor is determined.  
This effect can be avoided with the [defaultLagFactor](../Options-Documentation#defaultlagfactor) profile option, which makes Revenant assume some default amount of lag when the profile is loaded that will then be refined by the lag offset logic.

To find a good `defaultLagFactor` value (which may be different for different computers), it is recommended to execute the [Revenant Debug Profile](../start/debug_profile.lua) which has a movement macro that continuously logs the calculated lag offset to the console. Once this value has stabilized, it should be set as your `defaultLagFactor` in your configuration.

[^1]: Adjustment works for example by moving 4 steps every 4ms, so windows has time to execute the movement. This has no bearing on the perceived smoothness of the movement because such intervals are still much faster than standard monitor refresh rates.

# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options) the Mouse Position Macro offers the following options to customize behavior:

## relative
With the relative option set, the target position is interpreted as a distance relative to the current mouse position instead of an absolute point on the monitor.

In relative mode negative values may be used to indicate a position to the left or below the mouse position.

```lua

-- Position the mouse 100px to the right and 50px upwards from its current position
k.m3 = { type = "mouseposition", {100,50}, relative=true }

-- Position the mouse 100px to the left and 20% of the screen's height downwards from its current position
k.m4 = { type = "mouseposition", {-100,"-20%"}, relative=true }

```

## duration
Sets the duration of mouse movements in milliseconds.  
If this value is not set or set to 0, the mouse moves to the destination instantly if there's also no [velocity](#velocity) defined.

* **default value**: `0`

```lua

-- Move the mouse 200px to the right and 100px up in half a second.
k.m3 = { type = "mouseposition", {200,100}, duration=500, relative=true }

-- The same movement but instantly (this is the default behavior)
k.m3 = { type = "mouseposition", {200,100}, duration=0, relative=true }

```

## velocity
Sets the velocity of the mouse movement, interpreted as pixels per second.  
If this value is not set or set to 0, the mouse moves to the destination instantly if there's also no [duration](#duration) defined.

* **default value**: `0`

```lua

-- Move the mouse 250px to the right, at 500 pixels per second (taking half a second for this distance)
k.m3 = { type = "mouseposition", {250,0}, velocity=500, relative=true }

```

>[!IMPORTANT]
`duration` and `velocity` cannot be set at the same time.

## durationMode
Decides whether the value of the [duration](#duration) option is divided up between all steps or defines the duration of a single step.

* **`"total"`** *(default)* = The duration value refers to the overall duration of all movement steps in total.
* **`"step"`** = The duration value refers to the duration of a single movement step.

```lua

-- The default behavior.
-- The movement lasts 1.5 seconds in total, with three steps that's 500ms per step.
k.m3 = { 
   type = "mouseposition",
   {250, -500}, {250, 500}, {-500}, 
   relative = true, duration = 1500, durationMode = "total"
}

-- In the step mode, the movement takes 1.5 seconds per step, for a total duration of 4.5 seconds.
k.m3 = {
   type = "mouseposition",
   {250, -500}, {250, 500}, {-500},
   relative = true, duration = 1500, durationMode = "step",
}

```

## screen
Defines on which screen the coordinates of this macro are located.  
Defaults to the main monitor for absolute movement and the current monitor for relative movement.

```lua

-- Instantly position the cursor in the middle of your second screen.
k.m3 =  { type = "mouseposition", {"50%"}, screen=2}

```