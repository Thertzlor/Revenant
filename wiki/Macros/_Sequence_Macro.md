
The Sequence macro is used for playing back a sequence of actions, which can be keys, key strings or other macros with either automatic or manually defined delays.  
In its simplest form it can be used to replicate the functionality of the LGS "Multi Key" and "Text Block" commands but with more options for execution such as pausing and continuing, or playing multiple sequences concurrently.

Advanced usage of the Sequence macro enables highly complex and dynamic operations via the ability to nest macros of any type within a sequence.

`type` value: `sequence` or `s`

### Complete Syntax:
>`{ type="sequence"|"s", <entries...>  [, p/play=<option>,  l/loop=<number>, stack=<option> ,ad/actionDelay=<number> , kd/keyDelay=<number>, av/actionVariance=<number>, kv/keyVariance=<number>, fragile=<boolean>, interrupts=<boolean|option> ] }`

Examples:
```lua

-- A simple example: output "ab", wait 500ms, then output "cd"
k.m3 = { type="sequence","ab",500,"cd" }

-- This more complex example with sub-macros and loops was used to navigate into a nested submenu of a game that doesn't support key bindings, with pauses to wait for UI transitions.
-- In words: Press escape wait 300ms, then press down and wait 25ms five times, after 200ms press enter and left separated with a 250ms wait and then press enter twice.
-- Also note the use of shorthand notation in the sub-macro for brevity.
k.m4 = {type = "sequence", "/e", 300, {t="s", "/d", 25, l = 5}, 200, "\n", 250, "/l", 250, "\n\n"}
```

# Functionality
A sequence consists of a list of commands of which there are 5 different types:
* A **string** is a key sequence to be typed.
* A **number** is a delay in milliseconds.
* A table **containing a single string** is a [link to another macro](#named-links).
* A table **containing exclusively numbers** is a [Dynamic Timing Adjustment](#dynamic-timing-adjustments).
* **Any other table** is parsed as a child macro.

You can nest one sequence in another sequence. These "child" sequences will run sequentially, which can be useful for example by using the `loop` option to repeat a specific portion of a sequence multiple times.

## Named Links
Any table consisting of a single string is interpreted as a named link to another macro, basically acting as a simplified [Link Macro]().
```lua

-- Our example macro to be linked
k.m3 = { type ="cycle", "a","b","c", name = "foo" }

-- Types three question marks, waits 300ms and then executes the macro "foo".
k.m4 = { type="sequence", "???" , 300, {"foo"} }

```
# Options
Besides the [General Macro Options]() the Wrap Key Macro offers the following options to customize behavior:
## loop
* shorthand: `l`

Set the number of times a sequence will loop.
The number includes the first run.

If set to -1 a sequence will loop indefinitely. 
```lua

-- this sequence types "abc" 5 times.
k.m3 = {"abc", type ="sequence", loop= 5 }

-- this sequence types "abc" indefinitely while held down.
k.m4 = {"abc", type ="sequence",play ="hold", loop= -1 }

```

## **Timing Options**
The following options act as standard timings for the entire macro except when specifically overwritten by a manual timing operation within the sequence itself.

As Key Macros can also type text, all timing options can be applied to them as well.

For all timing options it should be noted that the millisecond delays will not be always 100% accurate and you should always expect a deviation of a few milliseconds. This is a technical limitation that cannot be avoided on Windows (and as such also happens with LGS native commands).

Each of the four following options has a global counterpart in the Profile configuration which can be used to defined the default timings of all sequences and key macros of a profile.
## actionDelay
* shorthand: `ad`

The action delay is the primary delay type in a sequence. It governs how long to wait between each step as well as how long to wait before pressing the next key when typing out a string.

The duration is given in milliseconds.   

Manual delays in the form of numeric entries in the sequence override this setting.
```lua

-- Writes "a", "b" and "c", waiting for 300 milliseconds between each letter.
k.m3 = { type="sequence", "abc", actionDelay=300 }

-- This sequence behaves identically to the one above, as both the delay inside a string and the delay between sequence items is controlled by the same actionDelay value.
k.m4 = { type="sequence", "ab","c", actionDelay=300 } 

-- Here a manual delay overrides the general setting, resulting in a 300ms delay between "a" and "b" followed by a 500ms delay before "c"
k.m5 = { type="sequence", "ab",500,"c", actionDelay=300 }

```
## keyDelay
* shorthand: `kd`
  
While actionDelay is concerned with how long to wait between keys, keyDelay controls how long a key remains pressed down before it is released again.  
This option has no effect on non-key actions in the sequence.

By default, revenant releases pressed keys immediately for maximum speed and smoothness however some programs and games (especially older ones) require a key to remain pressed for some amount of time before registering it, so if you have problems with your key inputs being swallowed or not triggering, adjusting the **keyDelay** is often the solution.
```lua

-- Presses "a", "b" and "c", holding the button down for 300ms each. 
-- The actionDelay value in the profile configuration is used for the pause BETWEEN each press.
k.m3 = { type="sequence", "abc", keyDelay=300 }

```
## actionVariance
* shorthand: `av`

The actionVariance setting lets you control a randomized amount of variance applied to each [action delay](#actiondelay).

The range is given in milliseconds. For example if you have set an actionDelay of 100ms and an actionVariance of 40ms the actual delay will be anywhere between 80ms and 120ms.

There's always a miniscule variance in any timing, so variance settings of less than 10ms are generally not noticeable or useful.
```lua

-- Simple application of actionVariance
k.m3 = { type="sequence", "This macro randomly waits between 250ms and 350ms after typing each letter.", actionDelay=300, actionVariance=100 }

```
## keyVariance
* shorthand: `kv`
  
keyVariance works the same as the [actionVariance](#actionvariance) option but but applies the result to the [key delay](#keydelay).

The range is given in milliseconds. setting a keyDelay of 50ms and an actionVariance of 20ms the actual delay will be anywhere between 40ms and 60ms.
```lua

-- While the duration between each press of "a" is always 100ms, the duration of how long the "a" button is pressed will randomly fluctuate between 20 and 120 milliseconds (70 +/- 50)
k.m3 = { type="sequence", "aaaaaaaaaaaaa", keyDelay=100, keyDelay=70, keyVariance=50 }

```

## Dynamic Timing Adjustments
In the previous sections we have seen how to 
but what if we want to change timings generally but *mid-sequence*?

The Dynamic Timing Adjustment does just that. It is defined as a table containing 1 to 4 numbers, each corresponding to a timing option: [actionDelay](#actiondelay), [keyDelay](#keydelay), [actionVariance](#actionvariance), [keyVariance](#keyvariance) in that order.

The value provided for each option will be used for any subsequent steps in the sequence, unless overwritten by another adjustment or a manually defined delay.

When the sequence loops any adjustments are reset when starting the next loop. When shortening the list, timing options corresponding to the left out numbers are unaffected.

A dynamic timing adjustment within a nested sequence will only affect the timings within that nested sequence, leaving timings of any following commands in the parent sequence unaffected 
```lua

-- A minimal example; The "abc" output uses a delay of 200ms, the "def" part uses the 400ms defined in the Dynamic Timing Adjustment
k.m3 = { type="sequence", "abc", { 400 }, "def" , actionDelay=200 }

-- Example utilizing all adjustments
k.m4 = { type="sequence", "abc", { 400, 20, 100, 80 }, "def", 100, "ghi" , actionDelay=200, keyDelay=20, actionVariance=0, keyVariance=0 }

-- Example utilizing all adjustments
k.m4 = { type="sequence", "abc", { 400, 20, 100, 80 }, "def", 100, "ghi" , actionDelay=200, keyDelay=20, actionVariance=0, keyVariance=0 }

```
### Special Negative Values
Adjusting values on the fly is powerful, but how can you unset the timings back to the defaults?  
Or maybe you are asking yourself about you can adjust the `keyDelay` without also touching the `actionDelay` since the timing adjustments are position based.  

The answer is that specific negative values act as special operators:

* **-1** = set the value back to default timing value of the sequence.
* **-2** = set the value back to the *global* default of the timing option, ignoring any options set directly on the macro.
* **-3** = Leave the timing unaffected (will retain values from previous dynamic timing adjustments).
```lua

-- A minimal example; The "abc" output uses a delay of 200ms, the "def" part uses the 400ms defined in the Dynamic Timing Adjustment
k.m3 = { type="sequence", "abc", { 400 }, "def" , actionDelay=200 }


k.m4 = { type="sequence", "abc", { 400, 20, 100, 80 }, "def" , actionDelay=200, keyDelay=20, actionVariance=0, keyVariance=0 }

```
## Timing Inheritance
When nesting another sequence macro within a sequence, the child sequence will inherit the timing values of the parent sequence, at that particular part in the sequence.
```lua

-- A simple example.
-- both the "a" and "b" press from the main sequence AND the "c" and "d" press from the nested sequence have an actionDelay of 40ms and keyDelay of 20ms, even though the nested sequence specifies no options.
-- The nested sequence simply inherits the setting from the parent sequence.
k.m3 = { type="sequence", "ab", { "cd", type ="sequence" }, actionDelay=40, keyDelay=20 }

-- A more complex example.
-- The first nested sequence inherits only the actionDelay from its parent because it specifies its own keyDelay.
-- A dynamic timing adjustments sets the actionDelay to 60ms and keyDelay to 40ms, and since the second nested sequence comes after the adjustment it also inherits the adjusted value at that point. 
k.m3 = { type="sequence", "ab", { "cd", type ="sequence", keyDelay=15 }, {60,30}, "e", { "fg", type ="sequence" } , actionDelay=40, keyDelay =20 }

```