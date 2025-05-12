When you use Revenant all functionality is organized by profiles.  
The basic profile setup is handled in the `Scripting` editor of your LGS profile, which tells Revenant what the profile is called as well as how and where to load files, as seen in the `reference_LGS_template.lua` file.

The main part of setting up the mouse keys and the Revenant environment can then either be done by configuring a profile template either in a separate lua file (the recommended) method or within the `rv.profile` function in the scripting window.

The Profile template object has the following fields (although for most profiles only the `key` and `config` fields tend to be relevant)
* `key`: The dictionary of [Key Bindings](#bindings)
* `config`: Global [configuration](#configuration) for the profile.
* `library`: A dictionary of macros available throughout all [inherited](#inheritance) profiles.
* `start`: A [special Macro](#start-and-exit-bindings) that executes when the profile is loaded
* `exit`: A [special Macro](#start-and-exit-bindings) that executes when the Profile is unloaded
* `documentation`: The [Documentation](#documentation) dictionary which assigns descriptions to macro names for use in [Documentation Mode]().
* `scopeDefaults`: Lets you define Profile wide [defaults](#scopedefaults) for *any* macro option.
* `scopeOverride`: An [Experimental feature](#scopeoverride) to forcefully override options on any macro on the profile.
* `hooks`: Advanced feature for injecting your own lua logic at specific steps in Revenant's lifecycle.

# Bindings
Bindings are defined in the `key` table, which maps key names to macros.   
Usually the majority of a profile definition consists of adding macros to different buttons on the key table.  

The default naming scheme for buttons combines the first letter of their family (`m` for "mouse", `k` for "keyboard" and `l` for "left handed controller") with the number of the programmable key according to Logitech.

Note that LGS does not allow capturing or binding functionality to normal keyboard keys.
```lua

k.m3={}

```
## `start` and `exit` bindings
The `start` and `exit` properties of are special bindings for macros that will automatically execute when a profile is loaded and unloaded without any key being pressed.

Because the way LGS terminates lua scripts upon exiting a profile is a bit irregular it cannot be guaranteed that the `exit` binding will have time to complete or even run at all, so better not bind anything important to it.
```lua

k.m3={}

```
# Configuration
The `config` property holds your Profile's configuration. These are settings that globally affect all Macros and generally define the environment, for example which types of devices are available, special designations for certain buttons, monitor resolution etc.  
For a full list of available options see the [Options Documentation]().
```lua

k.m3={}

```
## External Configuration
An external configuration is simply a lua file that only contains *only* a configuration table and that is loaded into the current profile using a **relative** path the `externalConfigs` option. You can find an example of such an external configuration in the repository here: `start\reference_config.lua`. External configurations enable you to easily share mouse set-ups and general settings between multiple profiles.  
You can use external configs together with internal configs, with any internal settings overriding external ones.  
An external config can itself extend via another configuration file via its `externalConfig` option and here too will the child settings override the parent settings if both are set.
```lua

k.m3={}

```
# Library
A profile's Library, stored in the `library` property, is a table of named macros that are not bound directly to keys.  
It is designed as an organizational tool for utility macros that are then included via reference on macros on the actual keys.
```lua

k.m3={}



```
> **Important:** If a macro bound to a key is given the same name as a macro in the library, all name references within the current profile will prioritize the bound macro over the library macro. Just avoid duplicate names if possible.

# Documentation
Revenant lets you document your macros, not just for when you read the file but also on the lua console and the LCD display.  
You can set your profile to `Documentation mode` which will, instead of performing the action on a macro, output a description of that macro on the screen or console.

The content of the field is a table, where the keys are the macro names and values are the strings used to document them.

Besides the profile's documentation object, a macro can also be documented via the `documentation` property directly on the macro itself. The direct property on the macro will always override the general documentation for the profile.

```lua

k.m3={}

```
## External Documentation
Like configurations, a profile's documentation can be loaded via a separate file and like the external configs their contents can be overridden by local documentation definitions.
# scopeDefaults
The scopeDefaults property contains a table on which you can set options for any type of macro. These options will be used as the defaults for any macro for which the option is valid unless of course the macro overrides the default by defining that options on itself.  
These defaults make it possible to simplify setting up profiles containing many macros with similar settings.  
While some of the basic default settings 

If set both in the configuration and scopeDefaults the value set in scopeDefaults is used.

If a macro inherits an options value from a parent such as a group macro or sequence the inherited values will override the scopeDefaults as well as they are more specific than than the scope of the profile.
```lua

k.m3={}

```
# Inheritance and Extension
Once you have configured a profile to fit your needs you don't need to repeat or copy your set-up for further profiles thanks to Revenant's powerful inheritance features.

This goes beyond reusing external configuration files, for example let's say we have many action games that use similar control schemes such as "e" to interact, "i" for inventory, "shift" to run, "m" for map, "r" to reload, "ctrl" to crouch, and so on for which we can create a single generic "action" profile and then have multiple specific profiles extend from in, each only defining the few bindings that are exclusive to each game.

Here is an example of my typical action game base profile:
```lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

a.config = {clearLog = true, externalConfigs = "conf/defaultConfig", noMacroExtension = true}

b.m4 = "/05"
b.m5 = "/09"

b.m9 = "e"
b.m10 = "/s"
b.m11 = "i"
b.m12 = "/c"
b.m13 = "r"
b.m17 = "m"
b.m18 = "\t"
b.m20 = {{"/e", n = "esc"}, {t = "doc", g = 1}, t = "g"}

a.documentation = {
   m4 = "+quicksave:",
   m5 = "+quickload:",
   m9 = "+interaction:",
   m10 = "+sprint:",
   m11 = "+inventory:",
   m12 = "+crouch:",
   m13 = "+reload:",
   m17 = "+map:",
   m18 = "+tab menu:",
   esc = "+Escape.\nG-Shift for documentation mode"
}
```

Here we have all the typical

As you can see, this profile also already uses an extetnal configuration

Through inheritance my profile for *Far Cry 3* only takes up 10 lines: 
```lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "_defaultprofile", description = "Far Cry 3"}

b.m11 = "1"
b.m12 = "c"
b.m15 = "t"
b.m16 = "f"
b.m19 = "y"
```
Since the game mostly sticks to the usual shooter controls the profiles merely consists of adding bindings for the keys m15, m16 and m19 replacing the bindings on m11 and m12.


## Macro Extension
By default when a profile binds a macro to a button that also has a macro bound to it by the "parent" profile the 


## Macro Name Resolution
When multiple profiles are merged together during inheritance it is possible to end up with multiple macros with the same name on different profiles.  
Since there are several functionalities like link and control macros that target other macros by

When a Revenant checks for a reference macros it does two things: First it checks if there is a macro with the referenced name defined in the scope of the current profile.  
If none is found Revenant checks if *any* profile contains a macro with the referenced name, working backwards from the highest macro in the inheritance chain down to the first.

Let's illustrate this with a few examples:

```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", name="button"}
b.m4 = {"button", type="link"}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

b.m5 = {"b", name="button"}
b.m6 = {"button", type="link"}

```
Here Profile B extends from Profile A, meaning loading it will result in a profile with 4 keybindings, two macros named "button" and two links. But which of the "button" macros do the link macros in the combined profile refer to?  
The answer is that each of the links still refers to the "button" macro originally defined in the same profile, meaning the keys m3 and m4 both output "a" and m5 and m6 output "b".

You can chain as many inherited profiles as you want, 
```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", name="button"}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}
b.m4 = {"button", type="link"}

```
```lua

--- ProfileC.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileB"}

b.m5 = {"b", name="button"}

```
We load profile C. Both profiles A and B define a macro called "button", while profile B only contains a link to "button" without defining any macro with that name. So which one of the "button" macros is targeted by the Link macro?

The answer is the "button" macro from profile C because it is the most recently loaded child macro giving it higher priority. So in our final configuraion m3 outputs "a", m4 outputs "b" and m5 outputs "b" as well.

Finally let's see how 
```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", name="button"}
b.m4 = {"button", type="link"}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

b.m3 = {"b", name="button"}
b.m5 = {"button", type="link"}

```

Both profiles define a macro named "button" and link it to another key. Since the m3 "button" macro of profile B overrides the m3 binding of macro A will m5 now link to the `a` or `b` variant of "button"?

The answer is that m5 still links to the `a` variant of "button"; the macro may no longer be bound to m3, but even unbound macros are still parsed, as long as they are named.  
Otherwise an accidentally duplicated macro name on a child profile could easily disrupt up the functionality of a parent profile.

## Library Resolution
The macros that are stored in a profiles library are treated differently during inheritance than macros defined directly on a key.


# Advanced
The following fields offer advanced functionality that only the most ambitious profiles should require.
## scopeOverride
Like the name suggests it will completely override any setting on the macros itself, scopeDefaults or Profile configuration. Usually only used for testing and debugging profiles.
```lua

k.m3={}

```
## hooks
A number of event hooks that allow the injection of custom logic at specific points in the script. See [Advanced Lua integration]().