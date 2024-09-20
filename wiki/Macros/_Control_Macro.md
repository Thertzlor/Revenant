With this type of macro you can modify the state of other macros.

There are two variants, one for controlling continuos macros (`"macrocontrol"`) and one for controlling cycles (`"cyclecontrol"`).

# Continous macro control
Continous macros are macro types like `sequence` and `mouseposition` that run for an extended amount of time.  
Any such macro can be controlled with a control macro.
### Complete Syntax:
>`{ <target|targets[]> [, <command>], type = "macrocontrol"|"mc" [,targetGroup=<option>] }`

The first argument in a control macro is the name of the macro targeted by the control or alternatively a list of multiple names.  
It is also possible to specify the target `"all"` to control every continous macro on the profile at once.

The second argument is the control type:
* **`"cancel"`** *(default)* = Cancels the macro if it is running. The macro will restart from the beginning when triggered again.
* **`"pause"`** = Pauses the macro if it is running. The macro will continue from it's last position when resumed or triggered again.
* **`"resume"`** = Resume the macro if it is currently paused. If the macro was cancelled or has not run before this command has no effect.
* **`"toggle"`** = Pause a macro if it is running, resume it if it's paused. If the macro was cancelled or has not run before this command has no effect.

If the control type is omitted it is assumed to be `"cancel"`.
```lua

--- Prints "a","b","c" with 500ms breaks, looping forever
k.m3 = { "abc", actionDelay=500 , loop=-1 ,type="sequence", name="loopy"} 

--- cancels "loopy" when pressed
k.m4 = { "loopy", "cancel", type="macrocontrol"}

--- "cancel" is the default command, so it can be omitted. This macro acts exactly like m4.
k.m5 = { "loopy", type="macrocontrol"}

--- Pauses "loopy"
k.m6 = { "loopy", "pause", type="macrocontrol"}

--- Resumes "loopy"
k.m7 = { "loopy", "resume", type="macrocontrol"}

```
## Options for continous control
### targetGroup
If you are using the `all` selector, this option can be used to narrow down the affected macros to a specific macro type (either `sequence` or `mouseposition`, since these are the only continous macro types).
```lua

--- a control macro targetting "all" macros of type "sequence"
k.m3 = {"all", "toggle", targetGroup = "sequence" , type = "macrocontrol"}

--- This macro is affected by the control macro.
k.m4 = {"abcdefgh", actionDelay=500, type="sequence"}

--- This is a "continous" macro as well but not being of type "sequence", the control macro does not affect it.
k.m5= {"90%",duration=2000, type="mouseposition"}

```
# Cycle macro control
Cycle macros can be controlled by setting their position and completed cycles.
### Complete Syntax:
>`{ <target|targets[]>, <number|{number|nil [,number]}> , type = "cyclecontrol"|"cc" [,relative=<boolean>] }`

The command for the cycle control can either be a number, which sets the cycle position of the target macro, or a table with two numbers, the first setting the position and the second setting the number of completed cycles.  
To *only* set the completed cycles without changing the position the first entry in the list can be set to `nil`.

If the position of a cycle is set to a value that is bigger than the number of entries in the macro, the position will wrap around from the start. This does not count as a completing a cycle.
```lua

---the target macro
k.m3 = {"a","b","c", type="cycle", name = "cyc"}


--- sets the target's position to 1 (in this case "a")
k.m4 = {"cyc", 1, type="cyclecontrol" }

--- sets the target's position to 2 and the number of completed cycles to 3
k.m5 = {"cyc", {2,3}, type="cyclecontrol" }

--- sets the target's number of completed cycles to 2 without changing the position
k.m6 = {"cyc", {nil,2}, type="cyclecontrol" }

```
## Options for cycle control
### relative
by using the `relative` option, the numbers provided by the control macro are not absolutely set but instead added to the macro's current values.

Just like absolute values, relative values that go past the macro's number of steps or below zero will wrap around to the other end of the macro.
```lua

---the target macro
k.m3 = {"a","b","c", type="cycle", name = "cyc"}


--- sets the target's position to the current position +1
k.m4 = {"cyc", 1, relative=true , type="cyclecontrol" }

--- sets the position two steps back
k.m5 = {"cyc", -2, relative=true , type="cyclecontrol" }

--- sets the target's number of completed cycles 2 steps ahead without changing the position
k.m6 = {"cyc", {0,2}, relative=true , type="cyclecontrol" }

```