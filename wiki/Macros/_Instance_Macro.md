An advanced macro that copies the contents of another macro but is treated as an independent instance instead of a reference. The Instance macro can dynamically alter parts of the copied macro, allowing different instances to have different states and functionality.

`type` value `instance` or `i`

### Complete Syntax:
>`{ type="instance"|"i", <target>  [, update=<option>, substitute=<option>, <... any options for the target macro type>] }`
```lua

-- A sequence macro outputting the string "This is a green button."
k.m3 = { type="sequence", "This is a ","green"," button.", name="macro_green" }

-- An instance derived from "macro_green", adding a "loop" option and changing the text to "This is a yellow button."
k.m4 = { type="instance", "macro_green", loop=2, update={ "yellow", selector=2, method="replace" } }

```
# Functionality
Binding the same functionality to multiple buttons is usually achieved with the [Link Macro](), but since links are only references, they are limited to reproducing the exact functionality bound to the same shared state.  
Instances on the other hand are parsed and processed from scratch, allowing them to have any number of different contents or properties and they do not share a state with the original macro.

For most simple use cases Link macros should be sufficient as using instances can get obtuse and technical fairly quickly. But in exchange they offer a great amount of flexibility, allowing macros to inherit content and functionality from each other akin to a simplified OOP class (or rather prototype) system.

```lua

-- The target macro
k.m3 = { type="cycle", "a", "b", "c", "d", name = "macro_a" }

-- A link macro.
-- If the state, such as the current position of the cycle changes, this change is reflected on both m3 and m4.
-- This is because under the hood there is only one macro triggered by both buttons.
k.m4 = { type="link", "macro_a" }

-- The instance macro also has the exact same functionality as the target, but is an new macro with an independent state.
-- Here, the cycle on m5 can be in a different position than the one on m3. 
k.m5 = { type="instance", "macro_a" }

```
## Option Overrides
Any option specified on the Instance macro will *always* override that option on the target macro regardless if the target previously had that option set to something else.
```lua

-- Target sequence with 200ms actionDelay.
k.m3 = { type="sequence", "test", actionDelay=200, name="macro_a" }

-- The derived instance now has an actionDelay of 50ms.
-- This would not be possible with a link macro. 
k.m4 = { type="instance", "macro_a", actionDelay=50 }

```
## Instances of Instances
Instances can be chained. When one Instance Macro has another Instance Macro set as its target, the target instance is processed first and any alterations 
are applied to the final compiled result of the first instance, not its instance definition (meaning you can't change the content of the first instance's `update` option, because at that update is already applied).

```lua

--Real world example for Chrome: open a new tab and navigate to "www.google.com"
b.m3 = { "*t", 200, "www.google.com", "\n", type = "sequence", actionDelay = 0, name = "google" }

-- An instance, which replaces the url part with "www.github.com". 
b.m4 = { "google", type = "instance", u = {"www.github.com", selector = 3, method = "replace"}, name = "git" }

-- An instance of "git", which appends "/security" after "www.github.com".
b.m5 = { "git", type = "instance", update = {"//security", selector = 4, method = "insert"} }

```

## Working with Template Macros
The `template` macro option is specifically designed to work with instance macros, as a macro with this option set cannot be executed without being *instantiated* via an Instance Macro first.

All other references to templates such as Link or Control macros, are ignored. 

```lua

profile.library = { 
   -- A macro set to be a template
   example_template =  { type="cycle", "a","b","c", template = true }
 } 

-- Instantiating the template on this button.
k.m3 = { type = "instance", "example_template", name= "inst" } 

-- This linked button works, because it is pointing to the finished instance.
k.m5 = { type = "link", "inst" } 

-- This linked button DOES NOTHING, because it references the template that hasn't been instantiated.
k.m4 = { type = "link", "example_template" }

```

Since they don't have to be able to run, template macros are not checked or linted by revenant meaning they can contain settings or command list elements that are technically invalid, allowing for placeholder names or values.  
Only the *result* of the resolved Instance is actually processed, and via the [substitute](#substitute) and [update](#update) functions of the Instance Macro the placeholders can be replaced with their final valid values.

```lua

-- This macro should normally throw an error because "_val" is not a valid value for the "loop" option which expects a number.
-- However, as it is designated as a template it isn't checked.
k.m3 = { type = "sequence", "test", 300 , name = "example_macro", template = true, loop = "_val" } 

-- The substitute option of the instance macro replaces the placeholder value "_val" with something more sensible (5).
-- When the resolved macro is checked and processed all values are valid: { "test", 300 , type = "sequence", loop = 5 } 
k.m4 = { type = "instance", "example_macro", substitute = {_val = 5} } 

```

# Options
Besides the [General Macro Options](), the Instance macro accepts any options that its target macro would accept, applying them to the new instance. See [Option Overrides](#option-overrides).  

Additionally it offers the following options for advanced modifications:
## newType
An option to assign a new macro type to the created instance, since this cannot be achieved via [Option Overrides](#option-overrides) (as the regular `type` option needs to be `"instance"/"i"`).

Note that if the compiled instance inherits command structures or options from the target that are not compatible with the new type, the new instance will fail to compile.
```lua

-- The macro copied by the new instance.
k.m3 = { type="sequence", "a", "b", "c", name = "macro_a" }

-- The new instance, which is now a cycle between "a", "b" and "c" instead of an sequential output.
k.m4 = { type="instance", "macro_a", newType="cycle" }

```
## substitute
* shorthand: `sub`

This option accepts a table. The table's keys are compared to all values within the target macro and values that match, are substituted with the value assigned to that key.
Only exact matches count.

```lua

-- The target macro.
-- The placeholder value does not need an underscore, it's just used for clarity.
k.m3 = { type="sequence", "_placeholder", "b", "c", name = "macro_a" }

-- In this instance, "_placeholder" is replaced with "a".
-- The final resolved macro: { type="sequence","a", "b", "c" }
k.m4 = { type="instance", "macro_a", substitute = {_placeholder = "a"} }

```
The replacement applies to all values of the target macro, including the content of child macros and options, and will replace multiple instances of the value, if present.  

```lua

-- An example template macro with a nested child macro.
k.m3 = { type="cycle", {type="sequence","_a",500, "b","c"}, "_a", cancel = "_cancel" , template=true, name="macro_a"}

-- An instance for macro_a with substitution.
-- Note how both the "_a" value is replaced with "x" both directly on the macro as well as the child sequence macro.
-- Also note how the value of the "cancel" option ("_cancel") is replaced with the value 1000.
-- The resolved macro: { type="cycle", {type="sequence","x",500, "b","c"}, "x", cancel = 1000  }
k.m4 = { type="instance", "macro_a", substitute={ _a="x", _cancel = 1000 } }

-- A macro with repeated placeholders.
k.m5 = { type="sequence", "a", "_pause", "b", "_pause", "c", "_pause", name = "macro_b" }

-- Every occurrence of "_pause" is replaced with the number 500, for a 500ms pause.
-- The resolved macro: { type="sequence","a", 500, "b", 500, "c", 500, name = "macro_b"}
k.m6 = { type="instance", "macro_b", substitute = {_pause = 500} }

```
However the replacement does not apply to a macros that are merely referenced via a link or instance macros.

```lua

-- A sequence macro 
k.m3 = { type="sequence", "_a","b", name="sub_seq" }

-- this sequence executes our "sub_seq" macro twice, once as a named link (analogous to { type="link","sub_seq" }), once as a new instance, and appends another "_a"
k.m4 = { type="sequence", {"sub_seq"} , {type="instance", "sub_seq"}, "_a", name ="example_seq" } 

-- This instance replaces the value "_a" with "x".
-- Note that the "_a" remains untouched during the both of the "sub_seq" executions.
-- Only the third "_a" is replaced, as it was defined directly on the "example_seq" macro.
-- The resolved macro: { type="sequence", {"sub_seq"} , {"sub_seq", type="instance"}, "x" } 
k.m5 = { type="instance", "example_seq", substitute = {_a =  "x"} }

```

### non-standard keys

The substitution table can have any sort of keys, including numbers or strings with spaces and special characters.  
Lua requires these values to be put in square brackets.

```lua
-- The target macro
k.m3 = { type="sequence", "$a b\n", 300, "c", name="macro_a" }

-- Instance macro substituting with both numeric and complex string keys.
-- The resolved macro: { type="sequence","x", 1000, "c" }
k.m4 = { type="instance", "macro_a", substitute={ ["$a b\n"] = "x", [300] = 1000 } }

```

Technically a value without a key *is* a value with a numeric index, so `{"value"}` is equivalent to `{[1]="value"}`. But since this sacrifices clarity this implicit notation isn't advised for the substitution table and won't be used in any examples.

## update
* shorthand: `u`

This option performs one or more targeted updates on the target macro. Compared to the `substitute` option ,`update` is more flexible and the selector allows for more exact targeting than the "replace all" behavior of `substitute`.  
If an Instance Macro has both a `update` and a `substitute` value, the update functionality is executed first.

The value of this option can be one or more **update definitions**.

The syntax for an update definition is as follows:
> `{ <value> , method=<option>, s/selector=<option> [, source=<string] }`

The `method` property defines which kind of update happens, the `selector` defines which part of the macro is affected. Different methods


Valid values for the `selector` option are:
* A **numeric index** for selecting a position in the target macro's command list. Any index smaller than 1 is interpreted as an offset from the end (`0` will select the last position, `-1` the one before the last, etc).
* A **string/key** for selecting a property/option of the target macro (90% of the time you should use [Option Overrides](#option-overrides) instead).
* A **list of numbers and/or strings** to select arbitrarily deep nested child objects of the target macro's commands or options. Just like the single selector types, numbers select positions in list and strings select properties of objects.

```lua

-- A target macro with multiple nested child macros to demonstrate deep selection.
k.m3 = { type="sequence", {type="cycle", "a","b","c", limit=3, finish={type="keytoggle", "k"} }, "d","e", loop=2, name="example_sequence" }

-- An instance with a single simple update definition. The macro in the first position of the sequence is replaced with the string "c".
-- The resolved macro: { type="sequence", "c", "d","e", loop = 2}
k.m4 = { type="instance", "example_sequence",  update={"c", selector = 1, method="replace" } }


-- Another instance, this time with multiple updates and advanced selectors.
-- The resolved macro: { type="sequence", {type="cycle", "a","b","c", limit=3, finish={type="key", "k"} }, "d","e", loop = 3 }
k.m5 = { type="instance", "example_sequence", update = { 
   -- A key based update setting the "loop" option to 3.
   -- Selecting an option with a single string, (meaning it's on the top level of the target macro), is technically the same as an option override for that property.
   { 3, selector = "loop", method="replace" }, 

   -- A deeper selector.
   -- We are setting the "type" property of the "finish" object on the first position of the target macro to "key".
   { "key" , selector = { 1, "finish", "type" }, method="replace" }

   }
}

```
The `method` option accepts the following values:
* **`"replace"`** = Replace the contents of a list at either a specific index or a specific property with the `<value>` of the update object.
* **`"insert"`** = insert the `<value>` of the update object into a list at a specified index. Modifies the position of the other elements in the list.
* **`"delete"`** = Delete a property or an entry at a specified index. Modifies the position of the other elements in the list. For this method the `<value>` of the update object can be a number, which is interpreted as the number of additional elements to remove before the index (defaulting to 0).
* **`"listreplace"`** = replace one or more elements in a list with the `<value>` of the update object (which has to be another list) starting at a specified index.
* **`"listinsert"`** = insert the `<value>` of the update object (which has to be a list) into another list at a specified index.

Updates are always executed in the order they are defined on the macro. If an update changes the number or order of elements in a table through deleting or inserting elements, the next update will operate on those new positions, which has to be kept in mind when using numeric selectors.
```lua

-- Macro used as target
k.m3 = { type="cycle", "a","b","c", name="t_macro" }

-- For this instance we replace the first entry of the command list with "x".
-- The resolved macro: { type="cycle", "x","b","c" }
k.m4 = { type="instance", "t_macro", update={ "x", selector=1, method="replace" } }

-- For this instance we insert the value "x" at the second position of the command list.
-- The resolved macro: { type="cycle", "a","x","b","c" }
k.m5 = { type="instance", "t_macro", update={ "x", selector=2, method="insert" } }

-- For this instance, we delete the second element of the command list. 
-- The resolved macro: { type="cycle", "a","c" }
k.m6 = { type="instance", "t_macro", update={ selector=2, method="delete" } }

-- For this instance, we delete the second element of the command list AND one preceding element. 
-- The resolved macro: { type="cycle", "c" }
k.m7 = { type="instance", "t_macro", update={1, selector=2, method="delete" } }

-- For this instance, we override the entries of the command list with our list contents ("x", "y"), starting at position 2. 
-- This is different from the regular "replace" method, which would have overridden "b" with the entire list object.
-- The resolved macro: { type="cycle", "a","x","y" }
k.m8 = { type="instance", "t_macro", update={ {"x","y"}, selector=2, method="listreplace" } }

-- For this instance, we insert the the list contents "x" and "y", into the command list starting at position 2. 
-- This is different from the regular "insert" method, which would have inserted the entire list object at position 2.
-- The resolved macro: { type="cycle", "a","x","y","b","c" }
k.m9 = { type="instance", "t_macro", update={ {"x","y"}, selector=2, method="listinsert" } }

```
Finally, the `source` option accepts the name of a macro. If the `source` option is set, the `<value>` of the update definition is interpreted the same as the `selector` option, but applied to the macro pointed at by the `source` property and whatever value is selected on that macro is used as the new `<value>` of the update object.
```lua

-- Macro used as source
k.m3 = { type="cycle", "x","y","z", name="s_macro" }
-- Macro used as target
k.m4 = { type="cycle", "a","b","c", name="t_macro" }

-- An instance with source based updates.
-- Here we select the third entry of the command in "t_macro" ("c"),
-- replacing it with the second entry of the command in "s_macro" ("y").
-- The resolved macro: { type="cycle", "a","b","y" }
k.m5 = { type="instance", "t_macro", update = {2, selector = 3, source="s_macro", method="replace"} }

-- It's allowed to have target and source macro be the same.
-- Here we use two update definitions to create an instance where the first and third entries of "t_macro" are switched.
-- Note that when selecting values from the same macro, we always operate on the macro's original unmodified state.
-- The resolved macro: { type="cycle", "c","b","a" }
k.m6 = { type="instance", "t_macro", update = {
   {1, selector = 3, source="t_macro", method="replace"},
   {3, selector = 1, source="t_macro", method="replace"}
   } 
}

```