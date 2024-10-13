A Macro that executes different actions, key outputs or any other kind of macro, depending on how long the button has been pressed down.

`type` value `holdkey` or `h`

### Complete Syntax:
>`{ <entries...>, type="holdkey"|"h" [, holdTime=<number>, init=<boolean>, holdMode=<option>, release=<option> ] }`
```lua

k.m3 = { type=""}

```
# Functionality
Explanation

# Options
Besides the [General Macro Options]() the Hold Key Macro offers the following options to customize behavior:
## holdTime
Description
```lua

k.m3 = 

```
## init
If this option is set to `true`, the first action of the macro's command will be executed when the button is pressed down, while the hold time logic decides which action will be performed when the button is released.  
This of course means that the macro performs two actions in total.
* **default value:** `false`
```lua

--default hold key logic.
-- Nothing happens when the button is pressed.
-- The key outputs "a", "b", or "c" if the button has been held for less than 200ms, 400ms or 600ms respectively
k.m3 = {"a","b","c", holdTime= 200, type="holdkey"}

-- With the "init" option set "a" is immediately typed when this button is pressed.
-- The button then outputs either "b" when held for less than 200ms otherwise the output is "c" 
k.m4 = {"a","b","c", holdTime= 200, type="holdkey", init=true}

```
## holdMode
This option controls how manually defined timing values are interpreted.

* **`"relative"`** *(default)* = Any manual timing value is interpreted as the number of milliseconds since the last action step.
* **`"absolute"`** = Any manual timing value is interpreted as the number of milliseconds since the button has been pressed down.
* **`"additive"`** = Any manual timing value is interpreted as a number of milliseconds to be added to the default hold time of the macro. Can be negative.
 
```lua

k.m3 = 
k.m3 = 
k.m3 = 

```
## release
This option controls the Hold Key Macro's auto release functionality. The autorelease works by 

* **`"auto"`** *(default)* = Once the button has been pressed long enough to trigger the macro's final action, that action will be executed immediately without waiting for the button to be released. 
* **`"hold"`** = 


```lua

k.m3 = 

```