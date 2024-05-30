
The Sequence macro is used for playing back a sequence of actions, key strings or other macros with either automatic or manually defined delays.  
In its simplest form it can be used to replicate the functionality of the LGS "Multi Key" and "Text Block" commands but with more options for execution such as pausing and continuing, or playing multiple sequences concurrently.

Advanced usage of the Sequence macro enables highly complex and dynamic operations via the ability to nest macros of any type within a sequence.

`type` value: `sequence` or `s`

### Complete Syntax:
>`{ <entries...>, type="sequence"|"s" [, p/play=<option>,  l/loop=<number>, stack=<option> ,ad/actionDelay=<number> , kd/keyDelay=<number>, av/actionVariance=<number>, kv/keyVariance=<number>, cancel=<boolean>, interrupts=<boolean|option> ] }`

Examples:
```lua
k.m3 = {"ab",500,"cd", type="sequence"}

k.m4 = {}
```

# Functionality
A sequence consists of a list of commands of which there are 5 different types:
* A **string** is a key sequence to be typed
* A **number** is a manual delay
* A table **containing a single string** is a [link to another macro](#named-links)
* A table **containing exclusively numbers** is a [Dynamic Timing Adjustment](#dynamic-timing-adjustments)
* Any **other table** is parsed as a macro.

You can nest one sequence in another sequence. These "child" sequences will run sequentally, which can be useful for example by using the `loop` option to repeat a specific portion of a sequence multiple times.


# Timing Options
The following options act as standard timings for the entire macro except when specifically overwritten by a manual timing operation within the sequence itself.

As Key Macros can also type text, all timing options can be applied to them as well.

For all timing options it should be noted that the millisecond delays will not be always 100% accurate and you should always expect a deviation of a few milliseconds. This is a technical limitation that cannot be avoided on Windows (and as such also happens with LGS native commands).

Each of the four following options has a global counterpart in the Profile configuration which can be used to defined the default timings of all sequences and key macros of a profile.
## actionDelay
* shorthand: `ad`

The action delay is the primary delay type in a sequence. It governs how long to wait between each step as well as how long to wait before pressing the next key when typing out a string.

The duration is given in milliseconds.   

Manual delays in the form of numeric entries in the sequence override this setting.

Example:
```lua

-- Writes "a", "b" and "c", waiting for 300 milliseconds between each letter.
k.m3 = {"abc", type="sequence", actionDelay=300}

-- This sequence behaves identically to the one above, as both the delay inside a string and the delay between sequence items is controlled by the same actionDelay value.
k.m4 = {"ab","c", type="sequence", actionDelay=300} 

-- Here a manual delay overrides the general setting, resulting in a 300ms delay between "a" and "b" followed by a 500ms delay before "c"
k.m5 = {"ab",500,"c", type="sequence", actionDelay=300}
```
## keyDelay
* shorthand: `kd`
  
While actionDelay is concerned with how long to wait between keys, keyDelay controls how long a key remains pressed down before it is released again.  
This option has no effect on non-key actions in the sequence.

By default, revenant releases pressed keys immediately for maximum speed and smoothness however some programs and games (especially older ones) require a key to remain pressed for some amount of time before registering it, so if you have problems with your key inputs being swallowed or not triggering, adjusting the **keyDelay** is often the solution.

Example:
```lua
k.m3 = 
```
## actionVariance
* shorthand: `av`

The actionVariance setting lets you control a randomized amount of variance applied to each [action delay](#actiondelay).

The range is given in milliseconds. For example if you have set an actionDelay of 100ms and an actionVariance of 40ms the actual delay will be anywhere between 80ms and 120ms.

There's always a miniscule variance in any timing, so variance settings of less than 10ms are generally not noticeable or useful.

Example:
```lua
-- Simple application of actionVariance
k.m3 = {"This macro randomly waits between 250ms and 350ms after each letter.", type="sequence", actionDelay = 300, actionVariance = 100}
```
## keyVariance
* shorthand: `kv`
  
keyVariance works the same as the [actionVariance](#actionvariance) option but but applies the result to the [key delay](#keydelay).

The range is given in milliseconds. setting a keyDelay of 50ms and an actionVariance of 20ms the actual delay will be anywhere between 40ms and 60ms.

# Execution Options
Besides the [General Macro Options]() the following options cen be used to define various behaviors of the sequence pertaining to how it is toggled and how it plays.
## play
* shorthand: `p`

Define how the the sequence is triggered and played. Valid play modes are:

* **"normal"** = Play the sequence when the button is pressed down. The behavior of additional presses is defined via the [stack](#stack) option.
* **"toggle"** = Pressing the button once starts the sequence, pressing it again cancels it.
* **"hold"** = The sequence is played while the button is held down and canceled when the button is released.
* **"ptoggle"** = Works the same as the "toggle" mode but **pauses** the sequence instead of aborting it. When the button is pressed again the sequence continues where it left off.
* **"phold"** = Works the same as the "hold" mode but **pauses** the sequence instead of aborting it on keyup. When the button is pressed down again the sequence continues where it left off.


Example:
```lua
k.m3 = 
```
## loop
* shorthand: `l`

Set the number of times a sequence will loop.
The number includes the first run.

If set to -1 a sequence will loop indefinitely. 

Example:
```lua
-- this sequence types "abc" 5 times.
k.m3 = {"abc", type ="sequence", loop= 5 }

-- this sequence types "abc" indefinitely while held down.
k.m4 = {"abc", type ="sequence",play ="hold", loop= -1 }
```
## stack
This option defines what happens when a sequence macro is triggered while another instance of the same sequence is already running. There are 4 possible values:

* **0** = Cancel and restart the sequence from the beginning.
* **1** = Cancel the sequence.
* **2** = queue up another run of the sequence and execute it after the current run finishes. Multiple runs can be queued at once.
* **3** = Do nothing and simply ignore additional button presses of the same button while the sequence is running.

Example:
```lua
k.m3 =
```
## cancel

If set to `true` pressing any other button will cause the sequence to stop playing, when set to `false` the sequence keeps playing even while other macros execute.  
Other continuos macros have additional options for interacting with other playing sequences, defined with the [interrupts](#interrupts) option.

The default value of this option is set according to the [defaultThreadCancel]() option.

This option has no effect for sequence macros that are nested within another sequence.

Example:
```lua
k.m3 =
```
## interrupts

This option is similar to the [cancel](#cancel) option but only defines interactions with other continuos macros like sequences as well as non-instant mouse movement.

* **false** = If another sequence is playing this sequence will run at the same time.
* **true** = Cancels any other running sequences before playing.
* **"exclusive"** = Cancels other running sequences and runs in "exclusive" mode, meaning it can't be cancelled and blocks all input.
* **"exclusivePause"** = Runs in exclusive mode, but other sequences continue playing after this sequence ends.

This option has no effect for sequence macros that are nested within another sequence.

The default value of this option is set according to the [defaultThreadInterrupt]() configuration.

If another sequence has its `cancel` option set to `true` either explicitly or through to the global default, setting this option to `false` or `"exclusivePause"` will **not** prevent it from being cancelled.

Example:
```lua
k.m3 =
```

# Named Links
Any table consisting of a single string is interpreted as a named link to another macro, basically acting as a simplified [Link Macro]().

Example:
```lua
-- Our example macro to be linked
k.m3 = {"a","b","c",type ="cycle", name = "foo" }

-- Types three question marks, waits 300ms and then executes the macro "foo".
k.m4 = { "???" , 300, {"foo"}, type="sequence" }
```
# Timing Inheritance
When nesting another sequence macro within a sequence, the child sequence will inherit the timing values of the parent sequence, at that particular part in the sequence.

Example
```lua
k.m3 = 
```
# Dynamic Timing Adjustments
In the previous sections we have seen how to 
but what if we want to change timings generally but *mid-sequence*?

The Dynamic Timing Adjustment does just that. It is defined as a table containing 1 to 4 numbers, each corresponding to a timing option: [actionDelay](#actiondelay), [keyDelay](#keydelay), [actionVariance](#actionvariance), [keyVariance](#keyvariance) in that order.

The value provided for each option will be used for any subsequent steps in the sequence, unless overwritten by another adjustment or a manually defined delay.

When the sequence loops any adjustments are reset when starting the next loop. When shortening the list, timing options corresponding to the left out numbers are unaffected.

Example:
```lua
-- A minimal example; The "abc" output uses a delay of 200ms, the "def" part uses the 400ms defined in the Dynamic Timing Adjustment
k.m3 = { "abc", { 400 }, "def" , type="sequence", actionDelay = 200}

-- Example utilizing all adjustments
k.m4 = { "abc", { 400, 20, 100, 80 }, "def", 100, "ghi" , type="sequence", actionDelay = 200, keyDelay = 20, actionVariance = 0, keyVariance = 0}
```

## Special Negative Values
Adjusting values on the fly is powerful, but how can you unset the timings back to the defaults?  
Or maybe you are asking yourself about you can adjust the `keyDelay` without also touching the `actionDelay` since the timing adjustments are position based.  

The answer is that specific negative values act as special operators:

* **-1** = set the value back to default timing value of the sequence.
* **-2** = set the value back to the *global* default of the timing option, ignoring any options set directly on the macro.
* **-3** = Leave the timing unaffected (will retain values from previous dynamic timing adjustments).

Example:
```lua
-- A minimal example; The "abc" output uses a delay of 200ms, the "def" part uses the 400ms defined in the Dynamic Timing Adjustment
k.m3 = { "abc", { 400 }, "def" , type="sequence", actionDelay = 200}


k.m4 = { "abc", { 400, 20, 100, 80 }, "def" , type="sequence", actionDelay = 200, keyDelay = 20, actionVariance = 0, keyVariance = 0}
```
