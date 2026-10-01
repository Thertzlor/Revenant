In this folder you can find a number of tools that should be helpful in getting your *Revenant* setup up and running at its full potential.
# [reference_LGS_template.lua](./reference_LGS_template.lua)
A basic template for setting up Revenant. **This is the part that you paste in your LGS lua scripting window**.  
It's highly recommended to set up a profile folder and use external definition files for further profile configuration and setting up bindings. 
# [quickstart_profile.lua](./quickstart_profile.lua)
A basic template for an external profile, showing how Revenant imports its profile definition and defines bindings.  
See the [Profile Overview](https://github.com/Thertzlor/Revenant/wiki/Profile-Overview) page for more details.
# [reference_config.lua](./reference_config.lua)
An annotated config file designed to be a good start for most profiles. Designed to be used as an [external config file](https://github.com/Thertzlor/Revenant/wiki/Profile-Overview#external-configuration).  
For a more detailed explanation of the options see the [Options Documentation](https://github.com/Thertzlor/Revenant/wiki/Options-Documentation)
# [debug_profile.lua](./debug_profile.lua)
A profile that cen be used to diagnose problems and configure advanced *Revenant* settings (keep the LGS lua console or a debug viewer open while using it).  
Feel free to switch around the bindings if your mouse doesn't have enough buttons to trigger certain macros.  
The debug profile offers the following functionalities:

* `Mouse Button 3:`  
Log the current position of your mouse in pixels and normalized monitor space. Useful to check if *Revenant* is correctly configured for your monitor.
* `Mouse Button 4:`  
Run Revenant's built in console based monitor wizard. This tool can guide you through setting up *multiple* monitors. If you only have one, or only need position based macros for your primary monitor this setup is not neccessary.
* `Mouse Button 5:`  
General Lag check. You can use this macro check if your lag offset needs to be adjusted. It will first log the number of milliseconds since the profile was activated.  
Then, after a 500ms delay it will log again, this time both the running time and the number of milliseconds since the last logging function was executed. After another 250ms this process repeats.  
If the logged values differ significantly from 500 and 250 respectively, you might want to change your [lag settings](https://github.com/Thertzlor/Revenant/wiki/Options-Documentation#lag-offset-probably-only-needs-changed-for-very-badold-computers) in the profile configuration.
* `Mouse Button 6:`  
Movement Lag check. Executes a mouse movemen meant to last 1 second, and after each iteration the macro will output the automatically calculated lag offset value. This value is meant to be used as your `defaultLagFactor` setting, to ensure consistent movement even right after a profile loads.

# [macroExtractor](./macroExtractor/)
In this folder you can find a handy coonsole based Python script that you can point at exported xml profiles from LGS and convert any recorded macros to *Revenant* compatible [Sequence Macros](https://github.com/Thertzlor/Revenant/wiki/Sequence-Macro).  
Sequence Macros offer much more customization and flexibility than calling an LGS macro via an [External Macro](https://github.com/Thertzlor/Revenant/wiki/Executing-Macro), but you can't directly *record* keystrokes via the lua API. So since the LGS macro recorder is perfectly functional, we might as well makwe use of it.
