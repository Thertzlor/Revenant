# Change Log

All notable changes to the *Revenant* framework will be documented in this file.

## [1.0.1]
- Added a new [cyclical](https://github.com/Thertzlor/Revenant/wiki/Multiclick-Macro#cyclical) option for the multiclick macro that enables cycling back from the start after there have been more clicks than the macro has positions.
- Added the [debugOutput](https://github.com/Thertzlor/Revenant/wiki/Options-Documentation#debugoutput) option for better integration with DebugView.
- Improved the quality of the inital seed for math.random.
  - Initialization happens earlier now so math.random calls during the profile parsing stage are properly random now.
- Added ["not" mode](https://github.com/Thertzlor/Revenant/wiki/Condition-Syntax#logic-modes) for `condition` options with single values and changed the `"xor"` implementation to a proper multi-input xor cascade.

## [1.0.0]
- First public release.
