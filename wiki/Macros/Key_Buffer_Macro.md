This is an advanced key macro that adds one or more keys to a "buffer". The key will not be pressed at this point, but the next time *another* macro presses a key all buffered keys are prepended to that output.  
Buffers can be scoped to apply globally to a specific hardware family or the currently pressed key.

`type` value `keybuffer` or `kb`

### Complete Syntax:
>`{ <arg>, type="keybuffer"|"kb" [, scope=<option>, exclusive=<boolean>] }`
```lua

--Adds the key "b" to the global key buffer
k.m3 = { "b", type="keybuffer"}

--Adds the key "r" to the global key buffer
k.m4 = { "r", type="keybuffer"}

-- This macro outputs the string "each"
-- if m3 was pressed first it will output "beach" 
-- If m4 was pressed first the output is "reach"
-- m3 is pressed followed by m4 and then m5, the output will be "breach"
k.m5 = "each"

```
# Functionality
The key buffer exists to "compose" key combinations without actually pressing them. Instead, the queued up key presses are executed together with the *next* key output. After a buffer is applied, its contents are cleared.

In the [Key Macro]() documenation we made the distinction between "simple key macros" of one key (plus modifiers), for which the "down" and "up" events of the mouse button corresponds to pressing and releasing those key(s) and multi key macros that are pressed and released immediately in sequence once the button is pressed with no action when the button is released.  

How a Key Buffer interacts with simple key macros depends on its exact contents. If the buffer consists of only a single key press it is simply added to the key combination, the buffered key is pressed *and released* together with the other keys on the macro on on the press and release events respectively.  
If there is more than one key in the buffer (such as `"abc"` or `"aaa"` if a single key buffer was added multiple times) or a single character that is actually a key combination (such as `"A"` which is actually `shift + a`), then the buffer will be pressed **and released** before the contents of the key macro, which will still retain its dependence on the press and release events for its normal contents.

```lua

-- A single key macro. Pressing the key presses "x" and releasing the key releases "x"
k.m3 = "x"

-- A single key buffer. 
-- If m4 is pressed once, followed by m3, "a" and "x" are pressed together, once m3 is released both "a" and "x" are released as well. 
k.m4 = {"a", type="keybuffer"}

-- A multi key buffer.
-- If m5 is pressed, followed by m3 "bc" is typed out immediately, then "x" is pressed. Like before, "x" is released together with the m3 button.
k.m5 = {"bc", type="keybuffer"}

-- A single character consisting of multiple keys.
-- If m6 is pressed, followed by m3, "shift+d" is pressed AND released immediately, then "x" is pressed, releasing when the m3 button is also released.
k.m6 = {"D", type="keybuffer"}

```

## Resolving Key Names

The content of the key buffer is parsed separately from the content of the actual output when it comes to resolving key.  
For example, a key to which the string `"enter"` is assigned will press the enter key, but a key with the string `"ter"` assigned, pressed after a buffer macro with the value `"en"` which combines to `"enter` will output "enter" as text without resolving it to the key name.

## Modifier Merging
Even though regular text is resolved separately, if the key buffer ends with one or more [Quick Modifier Codes]() (such as `*`,`~`, etc) these modifiers will be applied to the first key press of the main non-buffered output.

```lua

-- Adds the "left control" modifier to the buffer.
k.m3 = { "*", type="keybuffer", scope="global"}

-- Because of the escape character "/" this key adds the literal asterisk to the buffer.
k.m4 = { "/*", type="keybuffer", scope="global"}

-- Normally this key outputs "c"
-- If m3 was pressed, the key will press ctrl + c the next time it is pressed.
-- If m4 was pressed, the key will ouptut "*c" the next time it is pressed.
k.m5 = "c"

```

## Outputting Only the buffer
Sometimes you might want to construct a buffered key sequence and then simply output the contents of the buffer without adding any additional input.  
This can be achieved by triggering the buffer output via an empty string. While normally keys or sequences to which an empty string is assigned will not do anything, it is technically still counted a key output, even if it consists of nothing, so the buffer can be prepended.

The modifier merging and single key behavior still applies in this special case, but by getting merged with *nothing* the modifier keys are simply pressed by themselves.

```lua

-- An empty key macro, by itself it does nothing when pressed.
k.m3 = ""


k.m3 = {"a", type = "keybuffer"}
k.m3 = {"*", type = "keybuffer"}

```

Also note that key buffers are only prepended directly in front of key outputs.  
For example if you have a cycle macro that starts with a 500ms pause followed by a key output and you prepend some buffered keys, the keys will be pressed **after** the pause, before the sequence's normal output.
# Options
Besides the [General Macro Options]() the Key Buffer Macro offers the following options to customize behavior:
## scope
Description
* **`"global"`** *(default)* = 
* **`"family"`** = 
* **`"key"`** =  

```lua

k.m3 = 

```
Multiple buffer scopes may apply to the same macro, if this happens all buffers are applied in order of specificity: Key Buffer then Device Family Buffer, then Global Buffer.

```lua

k.m3 = {"c" ,type="keybuffer", scope="global"}

k.m4 = {"b" ,type="keybuffer", scope="family"}

k.m5 = { {"a" ,type="keybuffer", g=0}, {"",type="key", g=1} }

```

## exclusive
If this option is set to `true`, its value will override and replace any existing value in the targeted buffer.
* **default value:** `false`
```lua

-- This buffer is exclusive. Even if m4 has been pressed before and the contents of the global buffer are currently "b" (or multiple "b"s), they will be overridden with a single "a".
k.m3 = {"a", type ="keybuffer", exclusive = true}

-- This buffer is non-exclusive, if m3 was pressed before its content will simply be appended.
k.m4 = {"b", type ="keybuffer"}

```
### Buffer Clearing
kk