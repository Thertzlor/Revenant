## Welcome to the Revenant wiki!


* **Basic Input Macros**  
   Several ways to trigger keys on the keyboard or type out strings.
   * `key`, `k`: [Basic Key or String Input](./Key-Macro)
   * `keyup`, `u`: [Key Up](./Key-Macro#key-up)
   * `keydown`, `d`: [Key Down](https://github.com/Thertzlor/wiki/Revenant/Key-Macro#key-down)
   * `keytoggle`, `kt`: [Key Toggle](./Key-Macro#key-toggle)

* **Multi Macros**  
   These macros present ways to manage multiple macros on a single key. Playing them sequentially, cycling between them or even triggering multiple macros at the same time.
   * `sequence`, `s`: [Sequence of Macros](./Sequence-Macro)
   * `cycle`, `c`: [Cycle of Macros](./Cycle-Macro)
   * `group`, `g`: [Group of Macros](./Group-Macro)

* **Timing Macros**  
   Switch between key functionality based on the timing of consecutive key presses or holding a key for a certain duration.
   * `multiclick`, `t`: [Multiclick Key](./Multiclick-Macro)
   * `holdkey`, `h`: [Hold Timer Key](./Hold-Key-Macro)

* **Mouse Functionality Macros**  
   Macros which set mouse properties instead of reacting to them.
   * `mouseposition`, `p`: [Mouse Position / Movement](./Mouse-Position-Macro)
   * `mousewheel`, `w`: [Mouse Wheel Control](./Mouse-Wheel-Macro)

* **Logitech Functionality Macros**  
   Functionality that is normally configured via LGS.
   * `mode`, `m`: [LGS Mode Select](./Mode-Change-Macro)
   * `backlight`, `b`: [Device Backlight Color](./Backlight-Macro)
   * `setdpi`, `dpi`: [Mouse DPI Modifier](./DPI-Macro)
   * `externalmacro`, `e`: [LGS Macro Execution](./External-Macro)

* **LCD Integration Macros**  
   LCD output for some Logitech Keyboards or the LGS LCD Emulator.  
   *[To activate the LCD Emulator shift + ctrl + right click on the LGS tray icon, until the option appears then in the window select `Tools -> Color -> Start`.]*
   * `log`, `o`: [LCD Message Log Macro](./Log-Macro)
   * `documentation`, `doc`: [LCD Profile Documentation](./Documentation-Macro)
   * `page`, `pg`: [LCD Page Navigation](./Pagination-Macro)

* **Control Macros**  
   Control currently running macros or set cycle properties.
   * `macrocontrol`, `mc`: [Continuous Macro Control](./Control-Macro#continuous-macro-control)
   * `cyclecontrol`, `cc`: [Cycle Macro Control](./Control-Macro.md#cycle-macro-control)

* **Input Modifier Macros**  
   Macros for modifying the behavior of *other* key inputs.
   * `bufferkey`, `kb`: [Key Buffer](./Key-Buffer-Macro)
   * `wrapkey`, `kw`: [Key Wrap](./Wrap-Key-Macro)

* **Meta Macros**  
   Macros that reference other macros or modify the Revenant environment.
   * `link`, `l`: [Link to Macro](./Link-Macro)
   * `instance`, `i`: [New Instance of Macro](./Instance-Macro)
   * `flag`, `f`: [Set Flag](./Flag-Macro)
   * `func`, `fn`: [Lua Function Call](./Function-Macro)
   * `alterhistory`, `w`: [Alter Button History](./Alter-History-Macro)