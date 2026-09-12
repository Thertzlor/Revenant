Executing arbitrarily complex mouse movements or altering the function of your mouse buttons based on different sections of your screen can make for some quite versatile profiles, but these advanced functions rely on Revenant having correct data about your monitors.  
This page will walk you through all you need to know.

# Basics
By default functionality involving monitor coordinates such as [area restrictions](./Macro_Overview#area) or mouse movement macros will target your current main monitor. Since lua internally uses normalized coordinates, pixel based measurements require the monitor's resolution to be defined.  
The default Revenant configuration assumes a standard 1080x1920 monitor, if you are running a different resolution you can define it like this:

```lua

---@type ProfileTemplate, Revenant
local profile = ...
local k = profile.key

profile.config = { 
   -- Configuring Revenant for a 4K monitor.
   monitors = {3840, 2160}
}

-- Position the cursor 500px from bottom left of your screen.
k.m3 = { type = "mouseposition", {500, 500} }

```



# Multi Monitor Set Ups
Setting up multiple monitors is a bit tricky since everything gets projected on a single 65535x65535 grid and we need to manually provide Revenant with information about where each monitor's area begins and ends by definining the coordinates of their corners.

To make the set-up process as easy as possible the Revenant Debug Profile you can find under `start/debug_profile.lua` offers a handy set-up function, that can be used as follows:
 
1. Define the resolutions of your monitors in the `config.monitor` setting of the debug profile according to the [monitors](./Options_Documentation/#monitors) schema. Leave out the `topLeft` and `bottomRight` properties but don't forget to set the `main` property on the main monitor as defined in windows.
2. Copy the `debug_profile.lua` file into your profile folder and load it into LGS.  
**Important:** Keep the scripting window open.
3. The monitor set-up function is bound to mouse button 4 by default, start the guided set-up by pressing it.
4. The Output of the Lua scripting window will start showing instructions to calibrate your displays, which involves recording your mouse positions in different corners of your screens via pressing the set-up button again.
5. When the set-up is completed, the Output window will show your final monitor configuration table with the computed `topLeft` and `bottomRight` valued filled in.  
Copy this table (select text -> right click -> copy, since ctrl+c might *not* work in the output window) and paste it into the config.monitor setting of any profile to enjoy full mouse movement support.

Optionally, you might first want to apply the generated setting to the Debug Profile itself and, after reloading the profile, use the logging function on the middle mouse button to check if the calculated pixel values are correct and if the detection of the monitor index works correctly, especially around the edges of the screen.

Here is an example of a fully configured multi monitor set-up:
```lua

---@type ProfileTemplate, Revenant
local profile = ...
local k = profile.key

profile.config = { 
         --- 3 monitors with dufferent resolutions
   monitors = {
      {
         3840, 2160, main = true, 
         bottomRight = {39459, 43683, 65535, 65535}, 
         topLeft = {16913, 0, 0, 0}
      },
      {
         1920, 1080, 
         bottomRight = {16907, 65535, -17, 98318}, 
         topLeft = {0, 32777, -49164, 49174}
      },
      {
         1680, 1050, 
         bottomRight = {65535, 65535, 141330, 98318}, 
         topLeft = {50741, 33688, 98328, 50540}
      }
   },
}

-- Position the cursor 300px from bottom and 200px from the left of your second screen.
k.m3 = { type = "mouseposition", {300, 200}, screen = 2 }

```

>[!IMPORTANT]
Pixel based calculations for multiple monitors may be buggy if Window's display scaling is set to something other than 100%.