This macro advances the text displayed on your LCD screen to the next page.
`type` value `group` or `g`

### Complete Syntax:
>`{ type="page"|"pg" }`

Example:

```lua

--- Displaying a log message on the lCD screen
k.m3 = {"This macro outputs text to the LCD screen, and because this sentence is rather long the LCD display will have to break it up into multiple pages." , type="log"}

---Press m4 to advance the page.
k.m4 = {type="page"}

```

# Basic Functionality
This macro is used to advance to the next page of the LCD message. When reaching the last page, the next press will reset the message to page 1.

Pressing a multi page `log` macro multiple times will also advance through its pages, but the `page` macro can advance through any active log macro, which is preferrable if for example a macro logs a message after triggering another macro with side effects that you don't want to trigger again.

# Options
*None*, other than the [General Macro Options]().