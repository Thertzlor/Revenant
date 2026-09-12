![Logo](./media/Revenant_logo.png)
# Revenant: Advanced Lua framework for LGS profiles
Are you fed up with the limitations of the LGS macro system? Would you prefer to map your keybindings and macros in a simple text file rather than a clunky GUI?

**Revenant** is a framework that provides a unified and native way to utilize the full power of Logitech's lua scripting features without having to wrestle with the awkward API.  
It is also meant to be usable without much lua programming experience.

When using Revenant you don't strictly write *lua*, you define macro logic within Revenant's templating language that just happens to take the form of lua tables.
```lua
local profile = ...
local k = profile.key

--- Configuring a Logitech G600 with a 1080p monitor.
profile.config = { devices="G600", monitors={1920,1080} }

--- The third mouse button presses the mouse wheel.
k.m3 = "/3"

--- The 9th mouse button, G9 on the thumbpad, cycles between the keys "a", "b" and "c"
k.m9 = { type = "cycle", "a","b","c"}

--- types "hello", waits one second, then types "world". Note that several such macros can run simultaneously.
k.m10 = { type = "sequence", "hello", 1000, "world"}

--- Enter the Konami Code because it's still the 80s.
k.m11 = "/u/u/d/d/l/r/l/rba\n"

-- Move the mouse in a triangular pattern, 500px wide and 500px high within 1.5 seconds.
k.m12 = { type = "mouseposition", {250, -500}, {250, 500}, {-500}, relative = true, duration = 1500 }

```

>[!IMPORTANT]
This script only works with the original **Logitech Gaming Software** and does not support G-Hub, since critical features are missing in the G-Hub implementation of the lua API. If you are stuck with a newer device that only supports G-Hub...  I feel sorry for you but there's really nothing to do besides complaining to Logitech.

# Documentation

This project is documented on [the wiki in this repository](wiki/).

# Why?
I started developing lua scripts for my G600 all the way back in 2011 when the mouse bindings I envisioned for The Witcher 2 could not be realized within the GUI of LGS and I was struck by how complicated and awkward even basic assignments were to implement in lua (at least in a way that's not bug-ridden).  
I wanted a solution that did away with all the boilerplate code and manual state management. But even other existing lua profile managers like G-Max and ll.Project, while introducing me to useful concepts like polling, did not provide the flexibility I needed as they *still* required writing full lua functions for any logic beyond simple string outputs (besides being unmaintained).

**Revenant** is designed with a more high-level approach in mind, its templating system keeps simple keybindings simple but the system is powerful enough to basically express arbitrarily complex logic.  

You might ask yourself "couldn't I just learn lua in general instead of a templating language described in lua?" and the answer is... absolutely, but this way you can ignore any programming shenanigans that don't have anything directly to do controlling mouse functionality.

# Features
## Bind anything to any button:
- 27 Macro Types for pretty much anything you could want your mouse to do.
- Bind multiple macros to one key.
- Select different Macros to execute via button cycling, multi-clicks, hold time, parts of the screen and other conditions.
- Supprts modifier keys, chorded button combinations and lots of other trigger conditions. 

## Positioning controls:
- Modify key bindings based on specific areas of your monitor(s).
- Move your mouse anywhere instantaneously or over time.
- Define activation areas and movement in pixels or screen percentages.

## Easily Customizable
- Define your own key and mode names, make your mouse your own.
- Group your bindings by keys, modes or g-shift states, whatever makes the most sense to you.
- Easily integrate custom lua functions.

## Designed to be user friendly:
- Fully featured linter and type checker. Don't lose control of your mouse because of typos.
- VSCode integration with intellisense and detailed annotations.

## Full Concurrency:
- Multiple macros can run at the same time.
- Running macros can be dynamically cancelled, paused or resumed.

## Easily Manage any number of modes:
- Support for Device dependent or independent modes.
- can synchronize to hardware modes and supports backlight on many Logitech devices.

## Macros as Dynamic Components:
- A macro can be nested in, linked to and extended from other macros.
- Build macro chains and logical conditions without any lua or logitech API knowledge.

## Hierarchical Class-like Profiles:
- Dynamically inherit and extend profiles from another Profile.
- Support for multiple inheritance.
- Configuration and documentation files are inheritable as well.

## Easy Monitoring
- Profiles and Modes are automatically integrated with your Logitech LCD Displays.
- Documentation mode for quickly displaying macro functionality
- Also works with the LGS LCD Emulator.

...Also comes with a Python script that can convert macros recorded with LGS to Revenant Seqeuence macros!

# Setup
Installing *Revenant* is easy:
1. Create a new LGS profile and *delete* all the standard LGS bindings (Left and right mouse button stay bound by default).

2. Download the latest release of Revenant from the releases section and unpack it. For the quickest start unpack the "revenant" folder into the install location of LGS.

3. From the `start` folder of the Revenant directory copy the contents of the `LGS_Template.lua` file and paste it into the *lua scripting* window of the LGS profile. [If you put it into any other folder than your LGS installation, you will have to adjust the values of the `rv.path` and `rv.configPath` values].

> [!TIP]
If you have a G600 you can skip step one and directly import the `example.xml` Template profile in the `start` folder instead of step 3.

...That's all you need to start defining macros and tweaking your profile, however it's generally more practical to use external profile files.  
This can be done in a few additional steps:
1. Change the `rv.externalProfile` setting in the LGS script to `true`
2. Fill in a name for your profile in the `rv.profileName` setting.
3. Copy the `quickstart_profile.lua` file from the `start` directory into the `profiles` directory and rename it to match your chosen name.
Now you can add your functionality to the lua file, just like editing in the lua editor, the bindings are applied whenever you reload the mouse profile.  
[Or, if you insist on the internal LGS editor, simply copy the contents of the `quickstart_profile.lua` except for the first line into the `rv.profile` function of the reference template.]
# Quickstart

## Configuring Hardware
LGS does not offer any lua API for checking which devices are connected, so you have to manually define which one(s) you are using.  
The framework supports all devices LGS supports and will allocate the correct number of mode and button slots for each.  
Simply put the name of your connected Logitech device from the [list of supported devices](./wiki/Supported_Devices) into the `device` setting of the profile config.


If you plan on using mouse position and movement macros, you should also define the resolution of your main monitor.
```lua
-- By default we assume you are using a G600 mouse on an HD monitor
profile.config = {devices = "G600", monitors = {1920, 1080}}
```
If you have several devices connected the value can be a list:
```lua
-- A mouse + keyboard combo on a 4K monitor.
profile.config = {devices = {"G502","G510s"}, monitors = {3840, 2160}}
```
For setting up multiple monitors see [Monitor Configuration](./wiki/_Monitor_Configuration).

## Bindings
The main part of the profile consist of the bindings in its `key` table.  
`m3, m4, m5...` are the standard bindings for the mouse buttons (the primary buttons can't be rebound by default), `k1,k2,k3...` are the G-keys on the keyboard.

Bindings consisting of a single symbol, `"a"`,`"x"`, `" "` or a single [key name](./key_output#logitech-key-names), will simply press that key and it's possible to quickly add modifier combinations using [prefixes](./key_output#modifier-keys) such as `"*c"` for `Ctrl+c` or `"#a"` for `Alt+a`. Upperase letters resolve to `shift + letter`.

Any strings that are not a key name will type their contents as text.

Tons of more complex macros are configured via lua tables and are listed [below](#macro-types) with functioning examples and once you are working with advanced functionality you might want to check out the documentation for general [Macro options](.//wiki/_Macro_Overview) further capabilities of your [Profile](./wiki/Profile_Overview) and [generally configuring *Revenant*](./Options_Documentation) to your liking.

# Macro Types

* **Basic Input Macros**  
   Several ways to trigger keys on the keyboard or type out strings.
   * `key`, `k`: [Basic Key or String Input]()
   * `keyup`, `u`: [Key Up]()
   * `keydown`, `d`: [Key Down]()
   * `keytoggle`, `kt`: [Key Toggle]()

* **Multi Macros**  
   These macros present ways to manage multiple macros on a single key. Playing them sequentially, cycling between them or even triggering multiple macros at the same time.
   * `sequence`, `s`: [Sequence of Macros]()
   * `cycle`, `c`: [Cycle of Macros]()
   * `group`, `g`: [Group of Macros]()

* **Timing Macros**  
   Switch between key functionality based on the timing of consecutive key presses or holding a key for a certain duration.
   * `multiclick`, `t`: [Multiclick Key]()
   * `holdkey`, `h`: [Hold Timer Key]()

* **Mouse Functionality Macros**  
   Macros which set mouse properties instead of reacting to them.
   * `mouseposition`, `p`: [Mouse Position / Movement]()
   * `mousewheel`, `w`: [Mouse Wheel Control]()

* **Logitech Functionality Macros**  
   Functionality that is normally configured via LGS.
   * `mode`, `m`: [LGS Mode Select]()
   * `backlight`, `b`: [Device Backlight Color]()
   * `setdpi`, `dpi`: [Mouse DPI Modifier]()
   * `externalmacro`, `e`: [LGS Macro Execution]()

* **LCD Integration Macros**  
   LCD output for some Logitech Keyboards or the LGS LCD Emulator.  
   *[To activate the LCD Emulator shift + ctrl + right click on the LGS tray icon, until the option appears then in the window select `Tools -> Color -> Start`.]*
   * `log`, `o`: ['LCD Message']()
   * `documentation`, `doc`: [LCD Profile Documentation]()
   * `page`, `pg`: [LCD Page Navigation]()

* **Control Macros**  
   Control currently running macros or set cycle properties.
   * `macrocontrol`, `mc`: [Continuous Macro Control]()
   * `cyclecontrol`, `cc`: [Cycle Macro Control]()

* **Input Modifier Macros**  
   Macros for modifying the behavior of *other* key inputs.
   * `bufferkey`, `kb`: [Key Buffer]()
   * `wrapkey`, `kw`: [Key Wrap]()

* **Meta Macros**  
   Macros that reference other macros or modify the Revenant environment.
   * `link`, `l`: [Link to Macro]()
   * `instance`, `i`: [New Instance of Macro]()
   * `flag`, `f`: [Set Flag]()
   * `func`, `fn`: [Lua Function Call]()
   * `alterhistory`, `w`: [ALter Button History]()

# Advanced VSCode integration
In order to have the best experience for editing your profile files I recommend using VSCode with the [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) extension installed for fully integrated intellisense for macro types, options, etc.

# Roadmap
I see *Revenant* as mostly completed as far as key based macros are concerned.  
Some improvements and extensions are planned, but most are fairly niche, with mouse movement being the one area that I plan to overhaul at some point, with support for curves in addition to straight lines as well as easing options.

I want to be able to generate a proper Developer documentation eventually, and I'm working on writing instructions for defining custom macros.

# Contributing
Help and improvements are always welcome, especially should there be any bugs or oddities involving Logitech devices that I don't have access to.  
If you want to contribute just make sure to be familiar with the limitations of the LGS lua environment, which can be quite restrictive.

# Credits
* G-Max and ll.project, two lua libraries that inspired a lot of *Revenant's* functionality a decade ago, by now they seem lost to time.
* kgober, who figured out the whole logitech polling logic back in the day, a lot stuff in the threading module is still based on his work.
* ***NOT*** G-Hub, which just sucks.