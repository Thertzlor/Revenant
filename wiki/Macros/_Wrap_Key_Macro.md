This is an advanced macro which enables you to wrap one or more key presses *around* the next output. It is best viewed, depending on the settings, as a variation of the [Key Buffer Macro]() or a [Key Down]() Macro with a built in dynamic [Key Up]() directive.

`type` value `wrapkey` or `w`

### Complete Syntax:
>`{ <arg>, type="wrapkey"|"w" [, scope=<option>, direct=<boolean>, exclusive=<boolean>] }`
```lua

-- Pressing this button will press left shift once m4 is pressed.
-- The shift button is released once the other output ("hello") is completed.
k.m3 = { "lshift" type="wrapkey" }

-- A string macro simply outputting "hello".
-- If m3 is pressed first it will output "HELLO" as the left shift key remains pressed for the duration of the output, it is then released.
k.m4 = "hello"

```
# Functionality
The Wrap key macro works by pressing all its keys in order, either when the next key output starts or directly the moment the key is pressed (via the [direct](#direct) option) and then waiting until another key output (including multi character outputs) finishes before releasing all its keys again in reverse order.  
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
However if a wrap key is applied to a sequence macro consisting of multiple key outputs it's not the whole sequence that is wrapped but only its first key output.

```lua

-- wrapping the next key output with left shift.
k.m3 = { "~", type = "wrapkey" }

-- "hello world" is a single string output.
-- After pressing m3 the output becomes "HELLO WORLD".
k.m3 = { "hello world", type = "sequence" }

-- This sequence also outputs "hello world", but separated into two outputs.
-- Only the first output is affected by the m3 wrap key, resulting in "HELLO world".
k.m3 = { "hello"," world", type = "sequence" }

```

# Options
Besides the [General Macro Options]() the Wrap Key Macro offers the following options to customize behavior:
## direct
Normally
* **default value:** `false`

```lua

-- A normal wrap key of "shift". The button will only be pressed when another output is triggered (here "x" from m5).
k.m3 = { "~", type = "wrapkey" }

-- A "direct" wrap key, which presses shift immediately and then waits until the end of another output to release it.
k.m4 = { "~", type = "wrapkey", direct = true }

-- A normal macro which can be wrapped by m4 and m5.
k.m5 = "x"

```
## scope
This option controls for which kind of output the wrapped key/s will be triggered.  
By default, this involves both pressing and releasing the keys, but when used in [direct](#direct) mode it controls only when the keys are released again.

* **`"global"`** *(default)* = The macro is triggered for any key output from any other macro of the profile.
* **`"family"`** = The macro will only be triggered for a key output from a macro launched from the same hardware family (mouse/keyboard/lhc) as the current Wrap Key Macro.
* **`"key"`** = The macro will only be triggered for the next key output from another macro on the same key.

```lua

-- Wrap key of "ctrl +  shift" which is scoped to other mouse buttons.
k.m3 = {"*~", type="wrapkey", scope="family"}

-- A normal macro on a mouse button.
-- If m3 is pressed first will output "ctrl + shift + s"
k.m4 = "s"

-- A normal macro on a keyboard button.
-- Even if m3 is pressed first, this key will never wrapped by the m3 macro as it is in the keyboard scope.
k.k1 = "a"

```
This next example demonstrates the behavior of the `scope` option in `direct` mode:  
we can keep the keys wrapped (pressed down) around as many key presses as we want until we trigger an output with the "right" scope which will release them again.

```lua

-- A wrap key macro for ctrl+shift.
-- Because it's in direct mode both keys will be pressed immediately when we press this button.
k.m3 = {"*~", type="wrapkey", scope="family", direct = true}

-- This macro bound on a button of the same family as the wrap key m3.
-- After outputting "ctrl + shift + s", ctrl and shift are released agaon.
k.m4 = "s"

-- This is a G-key on the keyboard.
-- Because it's not on the same family (mouse) as our wrap key, it will not cause "ctrl+shift" to be released.
-- This means we can output "ctrl + shift + a" as many times as we want without having to press m3 again.
k.k1 = "a"

```

## exclusive
By default Wrap Key macros are exclusive, meaning for each scope only one wrap key can be buffered, waiting to be pressed with the next output.  
Setting the `exclusive` option to false allows Revenant to prepare multiple wrapping keys.  
The option works just like the identically named option on the [Key Buffer Macro](), except Wrap Key macros are set to be exclusive by default. 

* **default value:** `true`
```lua

-- A non-exclusive wrap key for left control
k.m3 = { "*", type = "wrapkey", exclusive = false }

-- A non-exclusive wrap key for left shift
k.m4 = { "~", type = "wrapkey", exclusive = false }

-- By pressing both m3 and m4 before m5 you can output ctrl + shift + s.
-- In the default exclusive mode the last pressed wrapper would have overwritten the one saved before,so only wrapping with ctrl OR shift would have been possible. 
k.m5 = "s"

```