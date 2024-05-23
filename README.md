![Logo](./media/Revenant_logo.png)
# Revenant: Advanced Lua framework for LGS profiles
Are you fed up with the limitations of the LGS macro system? Would you prefer to map your keybindings and macros in a simple text file rather than a clunky GUI?

**Revenant** is a framework that provides a unified and native way to utilize the full power of Logitech's lua scripting features not just without having to wrestle with the awkward API but with the overall intention to be usable without much lua programming experience.
> **Important:** This script only works with the original **Logitech Gaming Software** and does not support G-Hub, since critical features are missing in the G-Hub implementation of the lua API. If you are stuck with a newer device that only supports G-Hub...  I feel sorry for you but there's really nothing to do besides complaining to Logitech.

When using Revenant you don't write *lua*, you define macro logic within Revenant's templating language that just happens to take the form of lua tables.
```lua
local profile = ...
local k = profile.key

profile.config = { devices="G600", monitors={1920,1080} }


k.m3 = "/3"
```
# Why?
I started developing lua scripts for my G600 all the way back in 2011 when the mouse bindings I envisioned for The Witcher 2 could not be realized within the GUI of LGS and I was struck by how complicated and awkward even basic assignments were to implement in lua (in a safe and bug-free way at least).  
I wanted a solution that did away with all the boilerplate code and manual state management. But even other existing lua profile managers like G-Max and ll.Project, while introducing me to useful concepts like polling, did not provide the flexibility I needed as they *still* required writing full lua functions for any logic beyond simple string outputs (besides being seemingly unmaintained).

With Revenant's templating simple keybindings remain simple but the system is powerful enough to basically express arbitrarily complex logic.  
You might ask yourself "couldn't you just learn lua itself instead of a templating language described in lua?" and the answer is... absolutely, but this way you can just ignore any programming shenanigans that don't have anything directly to do controlling mouse functionality.

# Features
## Bind anything to any button:
- 28 Macro Types for pretty much anything you could want your mouse to do.
- Bind multiple macros one key.
- Select different Macros to execute via button cycling, multi-clicks, hold time and other conditions.

## Positioning controls:
- Modify key bindings based on specific areas of your monitor(s).
- Move your mouse anywhere instantaneously or over time.

## Easily Customizable
- Define your own key and mode names, make your mouse your own.
- Group bindings by keys, modes, g-shift states
- Easily integrate custom lua functions.

## Designed to be user friendly:
- Fully featured linter and type checker for profiles.
- VSCode integration with intellisense and detailed annotations.

## Fully asynchronous:
- Multiple key sequences can run at the same time.
- Running sequences can be dynamically cancelled paused and resumed.

## Easily Manage any number of modes:
- Support for Device dependent or independent modes
- can synchronize to hardware modes and supports backlight on certain (non lightsync) Logitech devices.

## Macros as Dynamic Components:
- A macro can be nested in, linked to and extended from other macros.
- Build macro chains and logical conditions without any lua or logitech API knowledge.

## Hierarchical Class-like Profiles:
- Dynamically inherit and extend profiles from another Profile
- support for multiple inheritance
- Configuration and documentation files are inheritable as well

## Easy Monitoring
- Profiles and Modes are automatically integrated with your Logitech LCD Displays
- Documentation mode for quickly displaying macro functionality
- Also works with the LGS LCD Emulator.


# Installation
Installing *Revenant* is easy:
1. Create a new LGS profile and *delete* all the standard LGS bindings (Left and right mouse button stay bound by default)

2. Download the latest release of Revenant from the releases section and unpack it. For the quickest start unpack the "revenant" folder into the install location of LGS.

3. From the `start` folder of the Revenant directory copy the contents of the `LGS_Template.lua` file and paste it into the *lua scripting* window of the LGS profile. [If you put it into any other folder than your LGS installation, you will have to adjust the values of the `rv.path` and `rv.configPath` values]

...That's all you need to start defining macros and tweaking your profile, however it's generally more practical to use external profile files.

To set up an external profile simply change the `rv.externalProfile` setting in the LGS script to `true`, copy the `reference_profile.lua` file from the `start` directory into the `profiles` directory and name the lua file the same nanme as the name in the `rv.profileName` property.

# Quickstart: bindings

## Configuring

# Macro Types