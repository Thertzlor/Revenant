This macro outputs a message to the Logitech lua log as well to any available LCD screen.

`type` value `log` or `o`

### Complete Syntax:
>`{ type="log"|"o", <message> [, persist=<number>, keepIndent=<boolean>, noLCD=<boolean>, debug=<boolean>] }`
```lua

--- self explanatory.
k.m3 = { type="log", "This is a log message" }

```
# Functionality
The log macro is used either for general information or debugging purposes.  
The log message does not have to be a string, you can even log a lua table and it will be prettified for output automatically.


# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options) the Log Macro offers the following options to customize behavior:

## noLCD
If this option is enabled the  message will only appear on the lua log but not on the LCD screen.

default value: `false`.

```lua

k.m3 = { type="log", "This log message appears on both the log and the LCD screen." }

k.m4 = { type="log", "This log message only shows up in the log.", noLCD=true }

```
## persist
The amount of time the message should stay on the LCD screen in milliseconds.  
set to `-1` to keep the message on the screen indefinetily.

The default value of this option is set via the [LCDMessageDuration](./Options-Documentation#lcdmessageduration) option

```lua

k.m3 = { type="log", "This message stays for 1 second", persist=1000 }

k.m4 = { type="log", "This message stays indefinitely (until overridden by another one)", persist=-1 }

```
## keepIndent
By default whitespace is trimmed from all lines of the log output when the text is prepared for being displayed on the LCD screen.  
With this option, spaces at the start of a line are retained, making it possible to retain indents, for example in code.  

default value: `false`.
```lua

k.m3 = { type="log",
[[First line, not indented
      Indented line 1
      Indented line 2
]], 
keepIndent=true 
}

```
(Note the double bracket notation for multiline strings in lua).
## debug
Set to `true` to output the message to the windows debugger using the `OutputDebugMessage` logitech API function.

Note that multiple lines of text will be parsed as multiple log entries.

default value: `false`.
```lua

k.m3 = { type="log", "This message shows up in in Windows DebugView", debug=true }

```