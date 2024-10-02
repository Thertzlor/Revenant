This is an advanced key macro that adds one or more keys to a "buffer". The key will not be pressed at this point, but the next time *another* macro presses a key all buffered keys are prepended to that output.  
Buffers can be scoped to apply globally to a specific hardware family or the currently pressed key.

`type` value `keybuffer` or `kb`

### Complete Syntax:
>`{ <arg>, type="keybuffer"|"kb" [, scope=<option>, exclusive=<boolean>] }`
```lua

--Adds the key "b" to the global key buffer
k.m3 = { "b", type="keybuffer", scope="global"}

--Adds the key "r" to the global key buffer
k.m4 = { "r", type="keybuffer", scope="global"}

-- This macro outputs the string "each"
-- if m3 was pressed first it will output "beach" 
-- If m4 was pressed first the output is "reach"
-- m3 is pressed followed by m4 and then m5, the output will be "breach"
k.m5 = "each"

```
# Functionality
The key buffer exists to "compose" key combinations without actually pressing them. Instead, the queued up key presses are executed together with the *next* key output.  
After this happens the buffer is cleared.

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

The modifier merging behavior still applies in this special case, but by getting merged with *nothing* the modifier keys are simply pressed by themselves.
```lua

k.m3 = 

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
The `exclusive` 
* **default value:** `false`
```lua

k.m3 = 

```