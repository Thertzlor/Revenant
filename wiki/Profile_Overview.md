When you 

The Profile template object has the following fields (although for most profiles only the `key` and `config` fields tend to be relevant)
* `key`: The dictionary of [Key Bindings](#bindings)
* `config`: Global [configuration](#configuration) for the profile.
* `library`: A dictionary of macros available throughout all [inherited](#inheritance) profiles.
* `start`: a special Macro to execute when the profile is loaded
* `exit`: Special macro to execute when the Profile is unloaded
* `documentation`: The [Documentation](#documentation) dictionary which assigns descriptions to macro names for use in [Documentation Mode]().
* `scopeDefaults`: Lets you define Profile wide defaults for *any* macro option.
* `scopeOverride`: Experimental feature to forcefully override options on any macro on the profile.
* `hooks`: Advanced feature for injecting your own lua logic at specific steps in Revenant's lifecycle.

# Bindings
Bindings are defined in the `key` table, which maps key names to macros.   
Usually the majority of a profile definition consists of adding macros to different buttons on the key table.  

The default naming scheme for buttons combines the first letter of their family (`m` for "mouse", `k` for "keyboard" and `l` for "left handed controller") with the number of the programmable key according to Logitech.

Note that LGS does not allow capturing or binding functionality to normal keyboard keys.

## `start` and `exit` bindings
The `start` and `exit` properties of a profile can be set to 

Because the way LGS terminates lua scripts upon exiting a profile is a bit irregular it cannot be guaranteed that the `exit` binding will have time to complete or even run at all, so better not bind anything important to it.

# Configuration
The `config` property holds your Profile's configuration. These are settings that globally affect all Macros and generally define the environment, for example which types of devices are available, special designations for certain buttons, monitor resolution etc.  
For a full list of available options see the [Options Documentation]().
## External Configuration
An external configuration is simply a lua file that only contains *only* a configuration table and that is loaded into the current profile using a **relative** path the `externalConfigs` option. You can find an example of such an external configuration in the repository here: `start\reference_config.lua`. External configurations enable you to easily share mouse set-ups and general settings between multiple profiles.  
You can use external configs together with internal configs, with any internal settings overriding external ones.  
An external config can itself extend via another configuration file via its `externalConfig` option and here too will the child settings override the parent settings if both are set.
# Library
A profile's Library, stored logically in the `library` property, is a table of named macros that are not bound directly to keys.  
It is designed as an organizational tool for utility macros that are then included via reference on the macros on the actual keys.
# Documentation

## External Documentation
Like configurations, a profile's documentation can be loaded via a separate file and like the external configs their contents can be overridden by local documentation definitions.
# Inheritance
Over the decades, 

Let's say we have many games that use similar control schemes.

"e" to interact, "i" for inventory, "shift" to run, "m" for map, "r" to reload, and so on and so forth.


# Advanced
## scopeDefaults
The scope defaults lets you set default values for any macro option
## scopeOverride
Like the name suggests it will completely override any setting on the macros itself, scopeDefaults or Profile configuration. Usually only used for testing and debugging profiles.
## hooks
A number of event hooks that allow the injection of custom logic at specific points in the script. See [Advanced Lua integration]().