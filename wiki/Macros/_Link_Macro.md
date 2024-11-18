A link Macro allows macros to be executed on a different button or a different context by referencing it by name.  
It can be assigned with the `type` value of `link` or `l`.  

### Complete Syntax:
>`{ type="link"|"l", <target> [, override=<boolean>] }`
```lua

-- Defining a macro with a name
k.m3 = { "x", name ="x key" }

-- This key does whatever the macro named "x key" does.
k.m4 = { type = "link", "x key" }

```
# Functionality
Link macros make it possible to define functionality once and reuse it throughout the profile.
Links are references, not copies and any link macro will act exactly as if it was triggered normally.  
When deciding if a linked macro should run, Revenant first checks any trigger conditions on the link macro itself and then checks any condition on the target macro.  
In cases where link and target have mutually exclusive conditions this can lead to the macro never running but this can be bypassed using the [override option](#override).

Identical execution also means that the macro and link share the same state which can be easily demonstrated using [Cycles]():
```lua

k.m3 = { type = "cycle", "a", "b", "c" name = "example cycle" }

k.m4 = { type = "link", "example cycle" }
--both buttons share the same cycle state, using any button to advance the cycle one step will also cause the next press of the other button to continue from that step.

```
To create copies of macros with individual states you can use the more advanced [Instance Macro]().

The one option that the target of a link macro will ignore is the [blocking]() option, since it would be nonsensical to block macro execution on a button that was not actually pressed.  
Instead the `blocking` option needs to be set on the link directly:
```lua

-- "b" is never triggered because of the 'blocking' setting on the "target" macro.
k.m3 = {
   { "a", name = "target", blocking = true  },
   "b"
}

-- Pressing this button executes both the "target" macro and the "c" key because blocking option of the link target only applies to the button m3.
k.m4 = {
   { type = "link", "target" },
   "c"
}

-- by manually enabling the blocking option on the link we recreate the exact me behavior as on the m3 button ("d" is blocked).
k.m4 = {
   { type = "link", "target", blocking = true },
   "d"
}

```
# Options
Besides the [General Macro Options]() the Link Macro offers the following options to customize behavior:
## override
* shorthand: `o`

As mentioned above if the link macro and its target have contradictory conditions the target macro cannot trigger. For this reason the `override` option can be set on the link which causes all trigger conditions on the target macro to be skipped, essentially overriding them with the conditions on the link macro.

```lua

-- here  macros only trigger if gshift is not active by default
profile.config = { defaultShift = 0 }

-- macro that runs on g-shift is active. 
k.m3 = { "a", gshift = 1, name = "shifted" }

-- This DOES NOT work as the link macro only triggers if G-shift is off but "shifted" only plays when G-shift is on.
k.m4 = { type = "link", "shifted" }

-- here the "gshift = 1" property of the "shifted" macro is overridden, so the macro actually triggers.
k.m5 = { type = "link", "shifted", override = true }

```
