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

## Grouping Bindings
The usual approach of simply binding macros to key names and defining any options inside the macro is called "flat binding" and is the binding method used for most examples in this documentation.  
However, there are other ways of organizing macros. The Grouping based approach lets you define groups for g-shift state, mouse mode or even custom names and options, with the individial key assignments being defined within those groups.

### Mode and Shift grouping

The following example demonstrates
Bindings in the `shift_0` group are triggered when the g-shift key is not pressed, while bindings inside the `shift_1` group are triggered *only* when g-shift is pressed.  
Additionally, there is also a `shift_2` group for macros that can trigger regardless of shift state.

```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

--assigning the entire group at once
b.shift_0 = {
   m3 = "a", 
   m4 = "b"
}

--assigning to a single property within a group
b.shift_1.m3 = "c"

b.shift_2.m5 = "d"

```
These shift-grouped bindings above are equivalent to the following "flat" bindings:
```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", {"c", gshift = 1}}
b.m4 = "b"
b.m5 = {"d", gshift = 2}

```
The mode groups work the same way. Revenant will parse as as many `mode_*` groups as are configured for the current profile plus a special `mode_0` group for macros that will trigger in all modes.  
*[Note that the standard autocomplete will always assume 3 modes]*

```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

-- Minimal config for two numeric modes instead of three.
a.config = { globalModes = {1,2} }

-- Macros active in mode 1
b.mode_1 = {
   m3 = "a", 
   m4 = "b"
}

-- Macros active in mode 2
b.mode_2.m3 = "c"

-- The macro for switching modes is active in all modes.
b.mode_0.m5 = {type="mode", 0}

```


### Custom Groups
The final and most advanced type of group is the custom group. These groups can be freely named, the only requirement is that their name needs to start with `_c`.  
*[Note that because of their arbitrary names, the standard autocomplete for macro assignments doesn't work for macros assigned inside custom groups, but if you are using them I'll assume you're advanced enough to not need it anyways.]*

What makes custom groups especially useful is that in addition to visually organizing macros, custom groups can also be used to inject macro options into all bindings that the group contains.

>[!CAUTION]
>When working with custom groups make sure to **never ever** assign a key name that is also the name of a macro option, this will likely break things.

```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

--- A purely visual custom group without any inheritance, containing a single macro
b._c_visual = {
   m3 = "a"
}

-- A custom group that inherits the g-shift option to its children.
-- functionally, this is identical to the built-in shift_1 group
b._c_shifted = {gshift = 1}
b._c_shifted.m3 = "b"

-- A custom group that injects "type", "actionDelay" and "loop" options
b._c_sequences = {type = "sequence", actionDelay = 300, loop = 3}
b._c_sequences.m4 = {"a", "b", "c"}
b._c_sequences.m5 = {"d", "e", "f"}

```

## `start` and `exit` bindings
The `start` and `exit` properties of are special bindings for macros that will automatically execute when a profile is loaded and unloaded without any key being pressed.
>[!IMPORTANT]
Because the way LGS terminates lua scripts upon exiting a profile is a bit irregular it cannot be guaranteed that the `exit` binding will have time to complete or even run at all, so better not bind anything important to it.
```lua

---@type ProfileTemplate, Revenant
local a = ...

a.start = { "hi!", type="key" }
a.exit = { "bye!", type="key" }

```
This profile will type "hi!", whenever it is loaded and "bye!" when unloaded.

The start binding is more useful in complex scenarios. For example you can use a sequence macro to loop a keypress with an `area` restriction in order to automatically output something the moment the mouse enters a specific portion of the screen without an additional button press.

# Configuration
The `config` property holds your Profile's configuration. These are settings that globally affect all Macros and generally define the environment, for example which types of devices are available, special designations for certain buttons, monitor resolution etc.  
For a full list of available options see the [Options Documentation]().
```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

-- Minimal config for two numeric modes instead of three.
a.config = { 
   globalModes = {1,2} 
}

```
## External Configuration
An external configuration is simply a lua file that only contains *only* a configuration table and that is loaded into the current profile using a **relative** path the `externalConfigs` option. You can find an example of such an external configuration in the repository here: `start\reference_config.lua`. External configurations enable you to easily share mouse set-ups and general settings between multiple profiles.  
You can use external configs together with internal configs, with any internal settings overriding external ones.  
An external config can itself extend via another configuration file via its `externalConfig` option and here too will the child settings override the parent settings if both are set.
```lua

--- Config.lua
---@type OptionsCollection
return {
   
}

```
```lua

--- Profile.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

a.config = {
   -- the extension is optional, "Config.lua" would be valid too.
   -- relative paths use a forward slash, for example "Presets/Config"
   externalConfigs = "Config"
   }

```
It is also possible to load multiple external config files into a profile by setting the `externalConfigs` option to a table containing a list of filenames instead of a single one.  
in case the configurations contain 
# Library
A profile's Library, stored in the `library` property, is a table of named macros that are not bound to keys.  
It is designed as an organizational tool for utility macros that are then included via reference on macros on the actual bindings.
```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

a.library = {
   
}

```
For most purposes it doesn't make a difference where a macro is initially defined but using the library table can make for much less cluttered profiles.  
Library macros are also useful for Macros designed to be used or overridden by child profiles that [extend](#inheritance-and-extension) the current one, as they feature some [handy behaviors when inherited](#library-resolution).
>[!CAUTION]
If a macro bound to a key is given the same name as a macro in the library, all name references within the current profile will prioritize the bound macro over the library macro. Just avoid duplicate names if possible.

# Documentation
Revenant lets you document your macros, not just for when you read the file but also on the lua console and the LCD display.  
You can set your profile to `Documentation mode` which will, instead of performing the action on a macro, output a description of that macro on the screen or console.

The content of the field is a table, where the keys are the macro names and values are the strings used to document them.

Besides the profile's documentation object, a macro can also be documented via the `documentation` option directly on the macro itself. The direct option on the macro will always override the general documentation for the profile.

```lua

local a = ...
local b = a.key

a.documentation = {
   
}

```
## External Documentation
Like configurations, a profile's documentation can be loaded via a separate file and like the external configs their contents can be overridden by local documentation definitions.
```lua

--- Docs.lua
---@type OptionsCollection
return {
   
}

```
```lua
--- Profile.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

a.config = {
   -- the extension is optional, "Documentation.lua" would be valid too.
   -- relative paths use a forward slash, for example "Presets/Documentation"
   externalDocs = "Documentation"
   }

```
# scopeDefaults
The scopeDefaults property contains a table on which you can set options for any type of macro. These options will be used as the defaults for any macro for which the option is valid unless of course the macro overrides the default by defining that options on itself.  
These defaults make it possible to simplify setting up profiles containing many macros with similar options.  
While some basic settings for macro timing and behavior can be defined via global options in the `configuration` object, this doesn't include all of them, while the scopeDefaults let you set default options for every option on every macro type.


A macro will only inherit options from the scopeDefaults that are valid 
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

Here we have all the typical keys bound to their conventional functions and I am also already using an external configuration file for all my global mouse settings.

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
All configurations and bindings are inherited from the parent.  
Since the game mostly sticks to the usual shooter controls the profiles merely consists of adding bindings for the keys `m15`, `m16` and `m19` replacing the bindings on `m11` and `m12`.

## Macro Extension
By default, child macros always override parent macros on the same key, but for more complex profiles it can be useful to merge bindings through the process of "macro extension".  
To enable this functionality for a profile, the "noMacroExtension" option needs to be deactivated in its configuration.

Which macro extension enabled, when a profile binds a macro to a button that also has a macro bound to it by the "parent" profile, revenant will decide whether or not to keep the child binding, based on comparing both macros' triggers.

There are five trigger relevant properties: [gshift](), [mode](), [mkey](), [condition]() and [area]().  
If any of these properties are different between the parent profile's macro and the child profiles macro then instead of the child macros binding overriding the parent binding, both macros are merged into one, so both can still trigger.

```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a",g=1}
b.m4 = "c"

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA", noMacroExtension = false }

-- This m3 binding triggers differently than m3 on ProfileA
b.m3 = "b"
b.m4 = "d"

```
On the m3 key the parent profile's "a" binding only triggers if g-shift is active. Therefore it has a different trigger than the "b" binding of the child's m3 key, so both bindings are kept, resulting in a merged button that outputs "a" if g-shift isn't pressed and "b" if it is.

The trigger conditions for both profiles' m4 bindings are however identical, so the standard logic of only keeping the child binding is applied.


## Multiple Inheritance
Revenant lets you chain as many inheritances as you want. ProfileC can extend ProfileB which extends ProfileA and so on.

But it is also possible to extend a profile from multiple other profiles at once that originally did not extend each other by providing the `extends` option as a list of names.

```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = "a"

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
-- Note that we're not extending anything here
b.m4 = "b"

```
```lua

--- ProfileC.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = { extends = { "ProfileA" , "ProfileB" } } -- Extending several profiles at once

b.m5 = "c"

```
If a profile extends multiple other profiles, the parent profiles are loaded in the order of the `extends` list, and each time the standard inheritance logic is applied, meaning that the above example behaves identical to the aforementined ProfileC extending ProfileB extending ProfileA example, even though ProfileB has no `extends` option set.  

This is a very flexible inheritance option, as choosing in which way the macros are overridden in each profile can be adjusted simply by altering the order of the list without needing to update the files of the other profiles at all.

## Macro Name Resolution
When multiple profiles are merged together during inheritance it is possible to end up with multiple macros with the same name on different profiles.  
Since there are several functionalities like link and control macros that target other macros by name it can be important to understand how such naming conflicts are resolved.

When a Revenant checks for a reference macros it does two things: First it checks if there is a macro with the referenced name defined in the scope of the current profile.  
If none is found Revenant checks if *any* profile contains a macro with the referenced name, working backwards from the highest profile in the inheritance chain down to the first.

Let's illustrate this with a few examples:

```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", name="button"}
b.m4 = {type="link", "button"}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

b.m5 = {"b", name="button"}
b.m6 = {type="link", "button"}

```
Here Profile B extends from Profile A, meaning loading it will result in a profile with 4 keybindings, two macros named "button" and two links. But which of the "button" macros do the link macros in the combined profile refer to?  
The answer is that each of the links still refers to the "button" macro originally defined in the same profile, meaning the keys m3 and m4 both output "a" and m5 and m6 output "b".

When chaining several profiles during inheritance we don't even need to define all macros on all profiles in order to target them:
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

-- Here, we link to a macro that is not defined on the current profile at all
b.m4 = {type="link", "button"} 

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

Finally let's see how links interact with child profiles that override bindings:
```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {"a", name="button"}
b.m4 = {type="link", "button"}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

b.m3 = {"b", name="button"}
b.m5 = {type="link", "button"}

```

Both profiles define a macro named "button" and link it to another key. Since the m3 "button" macro of profile B overrides the m3 binding of macro A will m5 now link to the `a` or `b` variant of "button"?

The answer is that m5 still links to the `a` variant of "button"; the macro may no longer be bound to m3, but even unbound macros are still *parsed*, as long as they are specifically named.  
Otherwise an accidentally duplicated macro name on a child profile could easily disrupt up the functionality of a parent profile in ways that are hard to debug.

But in case you *want* to replace a macro that is both defined and referenced in a parent profile, this can be accomplished using the profile's library.

## Library Resolution
The macros that are stored in a profiles library are treated differently during inheritance than macros defined directly on a key.  
Just like the bindings table, the child macro merges its own library with the library of the parent profile any if any macros share the same name, the parent's macro is overwritten with the library macro of the child profile.  

But importantly, only the state of the library after **all** profiles are combined is parsed, meaning that the replacement of library macros can propagate backwards from the children to the parent profile.

let's demonstrate:

```lua

--- ProfileA.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key

b.m3 = {type = "link", "button"}

a.library = {
   button = { "a" }
}

```
```lua

--- ProfileB.lua
---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

b.m4 = { type="link", "button"}

a.library = {
   button = { "b" }
}

```
Here both profiles define a library macro called "button", "a" on ProfileA and "b" on ProfileB but, you will notice that on ProfileB *both* the inherited m3 button and m4 output `b`, an important difference from regular inheritance;  
If profileA had defined its "button" macro as a binding on a key, the link macro on `m3` would still reference this variant of the macro and output "a" and ignore the newer "button" macro on the child profile.


# Advanced
The following fields offer advanced functionality that only the most ambitious profiles should require.
## scopeOverride
Like the name suggests it will completely override any setting on the macros itself, scopeDefaults or Profile configuration. Usually only used for testing and debugging profiles.
```lua

---@type ProfileTemplate, Revenant
local a = ...
local b = a.key
a.config = {extends = "ProfileA"}

```
## hooks
A number of event hooks that allow the injection of custom logic at specific points in the script. See [Advanced Lua integration]().