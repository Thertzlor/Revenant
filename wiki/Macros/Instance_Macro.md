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

(For most simple use cases Link macros should be sufficient, using instances can get obtuse and technical fairly quickly)

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
are applied to the final compiled result of the first instance, not its definition (meaning you can't change the content of the first instance's `update` option, because at that update is already applied)

## Working with Template Macros
The `template` macro option is specifically designed to work with instance macros, as a macro with this option set cannot be executed without being *instantiated* via an Instance Macro first.

Since they don't have to be able to run, template macros are not checked or linted by revenant, they can contain invalid settings or command contents that are technically invalid, such as placeholder names or values.  
Only the *result* of the resolved Instance is actually processed, and via the [substitute](#substitute) and [update](#update) functions of the Instance Macro the placeholders can be replaced with their final valid values.

```lua

-- This macro should normally throw an error because "_val" is not a valid value for the "loop" option which expects a number.
-- However, as it is designated as a template it isn't checked.
k.m3 = { "test", 300 , type = "sequence", name = "example_macro", template = true, loop = "_val" } 

-- The substitute option of the instance macro replaces the placeholder value "_val" with something more sensible (5).
-- When result of the instantiation is checked and processed all values are valid.
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

Description
```lua

k.m3 = 

```
## update
* shorthand: `u`

Description
```lua

k.m3 = 

```
