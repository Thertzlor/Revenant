A basic Macro that simply presses keyboard keys. In order to offer maximum versatility it comes in four different variants, [Standard](#standard-key), [Key Down](#key-down), [Key Up](#key-up) and [Key Toggle](#key-toggle).

### Complete Syntax:
> `<name>`  
> or:  
>`{ <name...> , type="key"|"keyup"|"keydown"|"keytoggle"|"k"|"u"|"d"|"kt" [, allKeys=<boolean>, unreverse=<boolean> ad/actionDelay=<number>, kd/keyDelay=<number>, av/actionVariance=<number>, kv/keyVariance=<number>] }`

# Standard Key
As the basic building blocks of any key binding, the standard key macro is used so often that by default any string or list consisting of a single string is interpreted as a key macro automatically.

The key macro only needs to be actually declared for [key combinations](#key-combinations), in which case the `type` value is `key` or `k` in short.

If the assignment consists of a single key name (full list of key names recognized by LGS [here]()) or a single key combination, the down and up actions are bound directly to the button press. The key is pressed when the mouse button is pressed and stays down until the button is released.

When the assigned string is a key sequence, e.g. any string that is not a key name, it is simply typed out, each component key is pressed and released in sequence. In this case nothing happens when the button is released.

Example:
```lua
-- 'enter' is a valid key name, so this mouse button acts as the enter key.
k.m3 = "enter"

-- 'abc' is not a valid key name, so it is interpreted as a string to be typed out once the button is pressed
k.m4 = "abc"
```

Besides the regular key macro there are three subtypes:

* **[Key-Down Macro](#key-down)** assigned with `keydown` or `d` 
* **[Key-Up Macro](#key-up)** assigned with `keyup` or `u` 
* **[Key-Toggle Macro](#key-toggle)** assiggned with `keytoggle` or `kt` 

## Key combinations
Listing more than one key name results in a combined button press.
This means that when the button is pressed all keys in the list are pressed from left to right and when the button is released the key release happens in reverse. In the below example this would be:  
`lctrl down -> a down -> waiting for mouse button release -> a up -> lctrl up`  
The [unreverse](#unreverse) option can be used to change this behavior.

Key combinations are supported by all key macro subtypes like [keydown](#key-down), [keyup](#key-up) and [keytoggle](#key-toggle) as well as the [Key Wrap Macro](). 
  
```lua
-- Presses left ctrl and a together, release in reverse order
k.m3 = { "lctrl", "a" , type = "key" }
```
only key lists explicitly designated as a single key macro are interpreted as key combinations.  
Without a defined type they are seen as a group of independent key macros. Although this means that the keys will still be pressed in the same order, the key release will *not* happen in reverse and specific key timings might not be respected.

# Key Down
A Key Down macro is assigned with the `type` value `keydown` or `d`.

It presses one key or multiple keys in sequence without releasing them. The lack of key release makes the behavior of key combinations and key sequences identical in this mode. 

Example:
```lua
-- Presses the "a" key.
k.m3 = { "a" , type = "keydown" }
```

# Key Up
A Key Down macro is assigned with the `type` value `keyup` or `u`.

It releases one key or multiple keys in sequence. Key release events can only be detected if the key is actually pressed, so releasing a key that is not actually down has no effect whatsoever.  
Just like when releasing a standard key macro, key combinations are released in reverse order.

Example:
```lua
-- Releases the "a" key IF it is currently pressed.
k.m3 = { "a" , type = "keyup" }
```

# Key Toggle
A Key Down macro is assigned with the `type` value `keytoggle` or `kt`.

It presses keys down when the button is pressed but does nothing when the button is released. Instead keys are released the next time the button is pressed down again. As usual key release of combinations are in reverse order.

Example:
```lua
-- Toggles the "a" key on or off every time the button is pressed.
k.m3 = { "a" , type = "keytoggle" }
```

# General Options
Besides the [General Macro Options]() the following options can be used to further modify key behavior:

## unreverse
With the `unreverse` option enabled key combinations are released in the same order as they are pressed.

Example:
```lua
-- lctrl down -> a down -> waiting for mouse button release -> a up -> lctrl up
k.m3 = { "lctrl", "a" , type = "key" }

-- lctrl down -> a down -> waiting for mouse button release -> lctrl up -> a up
k.m4 = { "lctrl", "a" , type = "key", unreverse = true }
```

## allKeys
The `allKeys` option can be used to create a key macro that instead of triggering a specific key, triggers all supported keys on the keyboard.  
While pressing all the keys is usually *not* a good idea, releasing all possible keys can be useful as a failsafe against stuck keys when designing a complex new mouse profile without needing to restart the whole program.

```lua
-- Releases all virtually held keys.
k.m3 = { allKeys = true, type = "keyup" }
```

# Timing Options
Key macros that print a string are in essence miniature [Sequence Macros]() which is why key macros can accept the same timing options as sequences and behave according to the [Timing Configurations set for the Profile](#timing-configurations).  
A detailed description of these options can be found [here]().