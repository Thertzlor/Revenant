An advanced macro that copies the contents of another macro but is treated as an independent instance instead of a reference. The Instance macro can dynamically alter parts of the copied macro, allowing different instances to have different states and functionality.

`type` value `instance` or `i`

### Complete Syntax:
>`{ <target>, type="instance"|"i" [, update=<option>, substitute=<option>, <... any options for the target macro type>] }`
```lua

k.m3 = { type=""}

```
# Functionality
Binding the same functionality to multiple buttons is usually achieved with the [Link Macro](), but since links are only references, they are limited to reproducing the exact functionality bound to the same shared state.  
Instances on the other hand are parsed and processed from scratch, allowing them to have any number of different contents or properties and they do not share a state with the original macro.

For most simple use cases Link macros should be sufficient as using instances can get obtuse and technical fairly quickly. But in exchange they offer a great amount of flexibility, allowing macros to inherit content and functionality from each other akin to a simplified OOP class (or rather prototype) system.

```lua
-- our target macro
k.m3 = {"a", "b", "c", "d", type="cycle", name = "macro_a"}

-- A link macro.
-- If the state, such as the current position of the cycle changes, this change is reflected on both m3 and m4.
-- This is because under the hood there is only one macro triggered by both buttons.
k.m4 = {"macro_a",type="link"}

-- The instance macro also has the exact same functionality as the target, but is an new macro with an independent state.
-- Here, the cycle on m5 can be in a different position than the one on m3. 
k.m5 = {"macro_a",type="instance"}

```
## Option Overrides
Any option specified on the Instance macro will *always* override that option on the target macro regardless if the target previously had that option set to something else.
```lua

-- Target sequence with 200ms actionDelay.
k.m3 = {"test", type="sequence", actionDelay=200, name="macro_a"}

-- The derived instance now has an actionDelay of 50ms.
-- This would not be possible with a link macro. 
k.m4 = {"macro_a", type="instance", actionDelay=50}

```
## Instances of Instances
Instances can be chained. When one Instance Macro has another Instance Macro set as its target, the target instance is processed first and any alterations 
are applied to the final compiled result of the first instance, not its instance definition (meaning you can't change the content of the first instance's `update` option, because at that update is already applied).

```lua

k.m3 = 

```


## Working with Template Macros
The `template` macro option is specifically designed to work with instance macros, as a macro with this option set cannot be executed without being *instantiated* via an Instance Macro first.

All other references to templates such as Link or Control macros, are ignored. 

```lua

profile.library = { 
   -- A macro set to be a template
   example_template =  {"a","b","c", type="cycle", template = true}
 } 

-- Instantiating the template on this button.
k.m3 = {"example_template", type = "instance", name= "inst" } 

-- This linked button works, because it is pointing to the finished instance.
k.m5 = {"inst", type = "link" } 

-- This linked button DOES NOTHING, because it references the template that hasn't been instantiated.
k.m4 = {"example_template", type = "link" }

```

Since they don't have to be able to run, template macros are not checked or linted by revenant meaning they can contain settings or command contents that are technically invalid, allowing for placeholder names or values.  
Only the *result* of the resolved Instance is actually processed, and via the [substitute](#substitute) and [update](#update) functions of the Instance Macro the placeholders can be replaced with their final valid values.

```lua

-- This macro should normally throw an error because "_val" is not a valid value for the "loop" option which expects a number.
-- However, as it is designated as a template it isn't checked.
k.m3 = { "test", 300 , type = "sequence", name = "example_macro", template = true, loop = "_val" } 

-- The substitute option of the instance macro replaces the placeholder value "_val" with something more sensible (5).
-- When resolved macro is checked and processed all values are valid: { "test", 300 , type = "sequence", loop = 5 } 
k.m4 = {"example_macro", type = "instance", substitute = {_val = 5} } 

```

# Options
Besides the [General Macro Options](), the Instance macro accepts any options that its target macro would accept, applying them to the new instance. See [Option Overrides](#option-overrides).  

Additionally it offers the following options for advanced modifications:
## newType
An option to assign a new macro type to the created instance, since this cannot be achieved via [Option Overrides](#option-overrides) (as the regular `type` option needs to be `"instance"/"i"`).

Note that if the compiled instance inherits command structures or options from the target that are not compatible with the new type, the new instance will fail to compile.
```lua

-- The macro copied by the new instance.
k.m3 = {"a", "b", "c", type="sequence", name = "macro_a"}

-- The new instance, which is now a cycle between "a", "b" and "c" instead of an sequential output.
k.m4 = {"macro_a", type="instance", newType="cycle"}

```
## substitute
* shorthand: `sub`

This option accepts a table. The table's keys are compared to all values within the target macro and values that match, are subtituted with the value assigned to that key.
Only exact matches count.

```lua

-- The target macro.
-- The placeholder value does not need an underscore, it's just used for clarity.
k.m3 = {"_placeholder", "b", "c", type="sequence", name = "macro_a"}

-- In this instance, "_placeholder" is replaced with "a".
-- The final resolved macro: {"a", "b", "c", type="sequence"}
k.m4 = {"macro_a", type="instance", substitute = {_placeholder = "a"} }

```
The replacement applies to all values of the target macro, including the content of child macros and options, and will replace multiple instances of the value, if present.  

```lua

-- An example template macro with a nested child macro.
k.m3 = { {"_a",500, "b","c", type="sequence"}, "_a", cancel = "_cancel" , type="cycle", template=true, name="macro_a"}

-- An instance for macro_a with substitution.
-- Note how both the "_a" value is replaced with "x" both directly on the macro as well as the child sequence macro.
-- Also note how the value of the "cancel" option ("_cancel") is replaced with the value 1000.
-- The resolved macro: { {"x",500, "b","c", type="sequence"}, "x", cancel = 1000 , type="cycle"}
k.m4 = { "macro_a", type="instance", substitute={ _a="x", _cancel = 1000 } }

-- A macro with repeated placeholders.
k.m5 = {"a", "_pause", "b", "_pause", "c", "_pause", type="sequence", name = "macro_b"}

-- Every occurence of "_pause" is replaced with the number 500, for a 500ms pause.
-- The resolved macro: {"a", 500, "b", 500, "c", 500, type="sequence", name = "macro_b"}
k.m6 = {"macro_b", type="instance", substitute = {_pause = 500} }

```
However the replacement does not apply to a macros that are merely referenced via a link or instance macros.

```lua

-- A sequence macro 
k.m3 = {"_a","b", type="sequence", name="sub_seq"}

-- this sequence executes our "sub_seq" macro twice, once as a named link (analogous to {"sub_seq", type="link"}), once as a new instance, and appends another "_a"
k.m4 = { {"sub_seq"} , {"sub_seq", type="instance"}, "_a", type= "sequence", name ="example_seq" } 

-- This instance replaces the value "_a" with "x".
-- Note that the "_a" remains untouched during the both of the "sub_seq" executions.
-- Only the third "_a" is replaced, as it was defined directly on the "example_seq" macro.
-- The resolved macro: { {"sub_seq"} , {"sub_seq", type="instance"}, "x", type= "sequence" } 
k.m5 = { "example_seq", type="instance", substitute = {_a =  "x"} }

```

### non-standard keys

The substitution table can have any sort of keys, including numbers or strings with spaces and special characters.  
Lua requires these values to be put in square brackets.

```lua
-- The target macro
k.m3 = {"$a b\n", 300, "c", type="sequence", name="macro_a"}

-- Instance macro subtituting with both numeric and complex string keys.
-- The resolved macro: {"x", 1000, "c", type="sequence"}
k.m4 = {"macro_a", type="instance", substitute={ ["$a b\n"] = "x", [300] = 1000 } }

```

Technically a value without a key *is* a value with a numeric index, so `{"value"}` is equivalent to `{[1]="value"}`. But since this sacrifices clarity this implicit notation isn't advised for the substitution table and won't be used in any examples.

## update
* shorthand: `u`

This option performs one or more targeted updates on the target macro. Compared to the `substitute` option ,`update` is more flexible and the selector allows for more exact targeting than the "replace all" behavior of `substitute`.  
If an Instance Macro has both a `update` and a `substitute` value, the update functionality is executed first.

The value of this option can be one or more **update definitions**.

The syntax for an update definition is as follows:
> `{ <value> , method=<option>, s/selector=<option> [, source=<string] }`

The selector can be:

* A **numeric index** for targeting a part of the command of the target macro.
* A **string/key** for targeting an option of the target macro.
* A **list of numbers and/or strings** to target arbitrarily deep nested child objects of the target macros commands or options.

```lua

k.m3 = {}

```


The `method` option accepts the following values:
* **`"replace"`** = Replace the contents of a list at either a specific index or a specific property with the `<value>` of the update object.
* **`"insert"`** = insert the `<value>` of the update object into a list at a specified index. Modifies the position of the other entries in the list.
* **`"delete"`** = Delete a property or an entry at a specified index. Modifies the position of the other entries in the list. For this method the `<value>` of the update object can be a number, which is interpreted as the number of additional elements to remove after the index (defaulting to 0).
* **`"listreplace"`** = replace one or more entries in a list with the `<value>` of the update object (which has to be another list) starting at a specified index.
* **`"listinsert"`** = insert the `<value>` of the update object (which has to be a list) into another list at a specified index.


```lua

k.m3 = 

```
Finally, the `source` option accepts the name of another macro. If the `source` option is set, the `<value>` of the update definition is interpreted as a selector that is applied to the macro pointed at by the `source` property and whatever value is selected on that macro is used as the new `<value>` of the update object.
```lua

k.m3 = 

```