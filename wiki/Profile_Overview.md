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
# Inheritance
Over the decades, 

Let's say we have many games that use similar control schemes.

"e" to interact, "i" for inventory, "shift" to run, "m" for map, "r" to reload, and so on and so forth.


# Advanced
The following fields offer advanced functionality that only the most ambitious profiles should require.
## scopeOverride
Like the name suggests it will completely override any setting on the macros itself, scopeDefaults or Profile configuration. Usually only used for testing and debugging profiles.
```lua

k.m3={}

```
## hooks
A number of event hooks that allow the injection of custom logic at specific points in the script. See [Advanced Lua integration]().