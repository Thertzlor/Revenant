# Change Log

All notable changes to the *Revenant* framework will be documented in this file.

## [1.1.0] The Time Manipulation update
- New general macro option [delay](), wich can delay the execution of any macro by a set amount of time.
- New general macro option [timeout](), which can deactivate macros after a set amount of time.  
The effect of a timeout varies between macro types:
  - [Sequence Macros](https://github.com/Thertzlor/Revenant/wiki/Sequence-Macro) and continous [Mouse Position Macros](https://github.com/Thertzlor/Revenant/wiki/Mouse-Position-Macro) will cancel, even if their normal end point has not been reached (number of loops complete, final position).
  - A [Flag Toggle Macro](https://github.com/Thertzlor/Revenant/wiki/Flag-Macro) with a timeout will unset its flag when the timeout triggers without needing to be pressed again.
  - [Mode Change Macros](https://github.com/Thertzlor/Revenant/wiki/Mode-Change-Macro) will set the mouse mode back to its previous value on timeout.
  - A [Key Macro]() with a key-down function will release its keys when the timeout event triggers (even if the button is still held down).
    - Key Macros with a key-up effect will press their keys down again.
  - [Control Macros](https://github.com/Thertzlor/Revenant/wiki/Control-Macro) also act as temporary versions of themselves when they have a timeout defined:
    - `"pause"` control macros will resume their target macros again on timeout.
    - `"resume"` control macros will pause their target macros again on timeout.
    - `"toggle"` control macros will simply toggle again on timeout.
    - `"cancel"` control macros are *unaffected*.
  - [Key Buffer Macros](https://github.com/Thertzlor/Revenant/wiki/Key-Buffer-Macro) will remove themselves from the buffer queue on timeout 
- Since Revenant is public now, there is a new option [minimumVersion]() available with which Profiles can specify what version of Revenant they are designed for to prevent future compatibility issues.
  - When initializing, Revenant will log a warning when attempting to load a profile with a higher minimum version than itself (only major and minor versions are considered for this comparison).

## [1.0.1]
- Added a new [cyclical](https://github.com/Thertzlor/Revenant/wiki/Multiclick-Macro#cyclical) option for the multiclick macro that enables cycling back from the start after there have been more clicks than the macro has positions.
- Added the [debugOutput](https://github.com/Thertzlor/Revenant/wiki/Options-Documentation#debugoutput) option for better integration with DebugView.
- New option [detectPausedSequences](https://github.com/Thertzlor/Revenant/wiki/Options-Documentation#detectpausedsequences) to enable key conditions to react to sequences that are paused but not terminated.
- Improved the quality of the inital seed for math.random.
  - Initialization happens earlier now so math.random calls during the profile parsing stage are properly random now.
- Added ["not" mode](https://github.com/Thertzlor/Revenant/wiki/Condition-Syntax#logic-modes) for `condition` options with single values and changed the `"xor"` implementation to a proper multi-input xor cascade.
- Better handling of failed profile imports.

## [1.0.0]
- First public release.
