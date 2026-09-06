![Logo](./media/Revenant_logo.png)
# Revenant: Advanced Lua framework for LGS profiles
Are you fed up with the limitations of the LGS macro system? Would you prefer to map your keybindings and macros in a simple text file rather than a clunky GUI?

**Revenant** is a framework that provides a unified and native way to utilize the full power of Logitech's lua scripting features not just without having to wrestle with the awkward API but with the overall intention to be usable without much lua programming experience.

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

# Why?
I started developing lua scripts for my G600 all the way back in 2011 when the mouse bindings I envisioned for The Witcher 2 could not be realized within the GUI of LGS and I was struck by how complicated and awkward even basic assignments were to implement in lua (at least in a way that's not bug-ridden).  
I wanted a solution that did away with all the boilerplate code and manual state management. But even other existing lua profile managers like G-Max and ll.Project, while introducing me to useful concepts like polling, did not provide the flexibility I needed as they *still* required writing full lua functions for any logic beyond simple string outputs (besides being seemingly unmaintained).

With Revenant's templating simple keybindings remain simple but the system is powerful enough to basically express arbitrarily complex logic.  

You might ask yourself "couldn't I just learn lua in general instead of a templating language described in lua?" and the answer is... absolutely, but this way you can just ignore any programming shenanigans that don't have anything directly to do controlling mouse functionality.

# Features
## Bind anything to any button:
- 27 Macro Types for pretty much anything you could want your mouse to do.
- Bind multiple macros to one key.
- Select different Macros to execute via button cycling, multi-clicks, hold time, parts of the screen and other conditions.

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


# Setup
Installing *Revenant* is easy:
1. Create a new LGS profile and *delete* all the standard LGS bindings (Left and right mouse button stay bound by default).

2. Download the latest release of Revenant from the releases section and unpack it. For the quickest start unpack the "revenant" folder into the install location of LGS.

3. From the `start` folder of the Revenant directory copy the contents of the `LGS_Template.lua` file and paste it into the *lua scripting* window of the LGS profile. [If you put it into any other folder than your LGS installation, you will have to adjust the values of the `rv.path` and `rv.configPath` values].

...That's all you need to start defining macros and tweaking your profile, however it's generally more practical to use external profile files.

To set up an external profile simply change the `rv.externalProfile` setting in the LGS script to `true`, copy the `reference_profile.lua` file from the `start` folder into the `profiles` directory and rename it to match in the `rv.profileName` property of your profile script.  
Now you can add your functionality to the lua file, just like editing in the lua editor the bindings are applied whenever you reload the mouse profile.

# Quickstart: bindings

## Configuring Hardware

G600 default

## More Advanced



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
   * `alterhistory`, `w`: [Wipe Button History]()

# Credits
