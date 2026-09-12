In the end, every mouse profile comes down to pressing keyboard keys. Sometimes we want to press a specific key, sometimes we want to type out a string made out of multiple key presses. Here we will go over how strings and key names are processed.

In general Revenant should be able to produce any character on the keyboard, plus uppercase letters and on a German keyboard accented letters like `ò`, `Á` and so on.  
If you want to know the exact keys supported, you can look through the key-map files for each of the currently included locales which are are [en-US](), [en-GB]() and [de-DE](), more perhaps coming later.

Extended unicode characters are not yet supported as characters need to be able to be produced by the keyboard and unicode input is rather inconsistent.

# Quick Modifier Prefixes
Since pressing a modifier key together with another key is often utilized in keybindings, Revenant aims to make modifier combinations easier to construct by repurposing a number of generally rarely used keys as modifier codes that can be prepended to other inputs:

 * **`*`**: control
 * **`~`**: shift
 * **`#`**: alt
 * **`|`**: gui (`win` on windows `cmd` on mac)

```lua
-- "ctrl+a" , short notation
k.m3 =  "*a"
-- "ctrl+a" , expanded manual notation
k.m4 = { 'lctrl' 'a' ,type="key"}
```
Multiple modifier prefixes can be stacked. The combination `*~a` resolves to `control+shift+a`, with the order of the modifier codes determining which key is pressed down first.

Modifier prefixes only apply to the next non-modifier key. This means that `#~ab` resolves to `alt+shift+a` followed by a normal input `b` without any modifiers pressed. To wrap longer key sequences in modifiers the [expanded key macro notation]() or the [key wrap macro]() can be used.

The quick modifiers will always use the *left* version of the modifier left-shift, left-alt and so on. Combinations the right positioned modifiers needs to be done with the expanded notation using `rcontrol`, `ralt` etc.

In order to use any of the modifier codes as their normal key inputs like asterisk, tilde, and so on, simply escape them with a forward slash:

```lua
-- asterisk key followed by shift+a
k.m3 =  "/*~a"
-- ctrl+shift+a
k.m4 =  "*~a"
```

# Escape Sequences
In order to interpolate special or normally non-printable keys into sequences without needing to break up strings, Revenant provides escape sequences for pretty much all of those keys.
For example if we want to input the key sequence `up-down-enter-insert`, we can do so using a simple string of escape sequences instead of a list of logitech key calls (see [Logitech Key Names](#logitech-key-names)).

```lua
-- Short version using escape sequences
k.m3 =  "/u/d\n/i"
-- long, expanded notation
k.m4 = { {"up",t="k"},{"down",t="k"},{"enter",t="k"},{"insert",t="k"} ,type="sequence"}
```

## Standard escape sequences

* **`\t`** = Tab
* **`\n`,`\r`** = Enter

## Additional escape sequences
The following special escape sequences are provided, note that those are escaped with forward slashes:

### Mouse Actions
* **`/1` - `/5`** : The numbers 1 through 5 escaped with a forward slash stand for the mouse buttons 1 through 5; Left, Right, Middle, Forward and Back.

* **`/6`, `/7`** : Mouse wheel up/down movement grouped as the 6th and 7th "pseudo" keys of the mouse. Because there is no press/release state of a mouse wheel click, only the "press" action can be performed, release commands will be ignored.

### F-Keys
* **`/01` - `/24`**: Any number from 01 to 24 escaped with a forward slash and formatted with **two** digits stands for the F-keys F1 to F24.

### Modifier Keys
* **`/c` , `/C`**: Control key. lowercase for left control uppercase for right control
* **`/a` , `/A`**: Alt Key. Lowercase for left Alt, uppercase for right Alt
* **`/s` , `/S`**: Shift Key. Lowercase for left Shift, uppercase for right shift.
* **`/w` , `/W`**: "gui" key; win for windows, cmd for mac. Lowercase for left gui, uppercase for right gui.

### Other Keys
* **`/e`** : escape
* **`/b`** : backspace
* **`/u`, `/d`, `/l`, `/r`** : Shorthands for the arrow keys; Up, Down, Left, Right.
* **`/L`** : Capslock
* **`/N`** : Numlock
* **`/p`** : Print
* **`/i`** : insert
* **`/h`** : home
* **`/D`** : page-down
* **`/U`** : page-up
* **`/E`** : end
* **`/m`** : app
* **`/n`** : enter (numpad)
* **`/-`** : minus (numpad)
* **`/+`** : plus (numpad)
* **`/.`** : period (numpad)


# Logitech key names
This section lists all key names recognized by the logitech API for key presses.  
When using a normal key macro any string equal to one of the logitech key names will be interpreted as that key, any Revenant defined escape sequence can of course also be used.  
Note that when used in a [Sequence Macro](), the string is *not* resolved to a key but read as key sequence.

```lua
-- Logitech notation
k.m4={"escape" ,type="key"}

-- Revenant notation
k.m4={"/e" ,type="key"}

-- prints the string "escape"
k.m4={"escape" ,type="sequence"}
```

The only keys that can only be accessed through their logitech names are the numpad digits (`num0` - `num9`), `numslash` and `non_us_slash`.

* **`tilde`**
* **`minus`**
* **`equal`**
* **`lbracket`**
* **`rbracket`**
* **`backslash`**
* **`capslock`**
* **`semicolon`**
* **`quote`**
* **`comma`**
* **`period`**
* **`slash`**
* **`escape`**
* **`enter`**
* **`tab`**
* **`spacebar`**
* **`up`**
* **`left`**
* **`down`**
* **`right`**
* **`backspace`**
* **`lshift`**
* **`rshift`**
* **`lctrl`**
* **`rctrl`**
* **`lalt`**
* **`ralt`**
* **`lgui`**
* **`rgui`**
* **`f1`**
* **`f2`**
* **`f3`**
* **`f4`**
* **`f5`**
* **`f6`**
* **`f7`**
* **`f8`**
* **`f9`**
* **`f10`**
* **`f11`**
* **`f12`**
* **`f13`**
* **`f14`**
* **`f15`**
* **`f16`**
* **`f17`**
* **`f18`**
* **`f19`**
* **`f20`**
* **`f21`**
* **`f22`**
* **`f23`**
* **`f24`**
* **`delete`**
* **`home`**
* **`insert`**
* **`pause`**
* **`pagedown`**
* **`pageup`**
* **`printscreen`**
* **`scrolllock`**
* **`appkey`**
* **`non_us_slash`**
* **`numlock`**
* **`end`**
* **`num0`**
* **`num1`**
* **`num2`**
* **`num3`**
* **`num4`**
* **`num5`**
* **`num6`**
* **`num7`**
* **`num8`**
* **`num9`**
* **`numslash`**
* **`numminus`**
* **`numplus`**
* **`numenter`**
* **`numperiod`**