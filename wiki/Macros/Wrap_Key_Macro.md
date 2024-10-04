This macro enables you to wrap one or more key presses *around* the next output. It is best viewed as [Key Down]() Macro with a built in dynamic [Key Up]() directive.

`type` value `wrapkey` or `w`

### Complete Syntax:
>`{ <arg>, type="wrapkey"|"w" [, scope=<option>] }`
```lua

-- Pressing this button will press left shift.
-- The shift button is released once the other output (here the "hello" from m4) is completed.
k.m3 = { "lshift" type="wrapkey" }

-- A string macro simply outputting "hello".
-- If m3 is pressed first it will output "HELLO" as the left shift key remains pressed for the duration of the output, it is then released.
k.m4 = "hello"

```
# Functionality
The Wrap key macro works by pressing all its keys in order, the moment the key is pressed and then waiting until another key output (including multi character outputs) finishes before releasing all its keys again in reverse order.  
A wrap key macro can consist of any number of key names or any string of characters, but note that since a key cannot be pressed again while *already* pressed down, repeated keys or characters are ignored.

The normal [Key Macro]() only resolves [Modifier Shortcuts]() when they are followed by another non-modifier character, but Wrap Key macro does not make this distinction (unless the shortcut is explicitly escaped), since it will always be pressed in addition to some other key and modifiers keys like Shift, Ctrl, etc are natural candidates for use in Wrap Key Macros.  

Even though the [Key Buffer Macro]() has a similar wrapping feature for single keys or modifiers, the wrap key works differently by wrapping around the entire output, whereas the buffer would only wraps around the first key.  

```lua

-- our base macro, which outputs "example"
k.m3 = "example"

-- This macro wraps the left shift modifier around the next output.
-- the m3 output becomes "EXAMPLE", then the shift key is released. 
k.m4 = { "~", type = "wrapkey" }

-- This macro sets the left shift modifier as a key buffer. The shift key is not pressed immediately.
-- Most importantly the buffer only wraps around the first key stroke, so m3 outputs "Example".
k.m5 = { "~", type = "keybuffer" }

```

# Options
Besides the [General Macro Options]() the Wrap Key Macro offers the following options to customize behavior:
## scope
This option controls after which kind of output the wrapped key/s will be released.

```lua

k.m3 = 

```