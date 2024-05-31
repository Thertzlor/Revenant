The Group Macro is the simplest form of macro organization. It's often used implicitly.  
Group macros technically have the `type` value `group` or `g`, but in fact any list of one or more macros is automatically parsed as a group macro.

### Complete Syntax:
>`{ <macro...> [, type = "group"|"g", allowEmpty=<boolean>] }`

Example:
```lua
-- Explicitly declared group macro. Note how both string and object based macros can be contained.
k.m3 = { { "a", type = "key" },  "b", type = "group" }

-- An implicit group macro.
k.m3 = { { "c", type = "key" },  "d" }
```

# Functionality
When a group macro is executed it simply executes all its child macros.  
Macros inside a group will always be triggered in the order they are listed.

This might beg the question about what makes groups different from sequences apart from customization. The most basic difference is that group macros do not force their child macros to run in the same coroutine which means for example that if a group macro contains two sequence macros both sequences will run concurrently, one simply *starts* a few milliseconds earlier.

# Options
Besides the [General Macro Options]() there is only [one option](#allowempty) for the group macro itself, however the group macro accepts all options for any other macro type for the purpose of [option propagation](#option-propagation) as explained in the next section.

## allowEmpty
Normally a group macro is discarded if it contains no macros.
Setting the `allowEmpty` option forces Revenant to process an empty group anyway, allowing it to be referenced by other macros.

Example:
```lua
-- Group without members
k.m3 = { type="group", name="empty group 1"}

-- Group without members, with allowEmpty set
k.m4 = { type="group", name="empty group 2" , allowEmpty=true }

-- this reference results in an error message because the empty group was not processed.
k.m5 = { "empty group 1" type = "link" }

-- this reference works because allowEmpty forced the second empty group to be processed.
k.m6 = { "empty group" type = "link" }
```
---
# Option Propagation
Any macro option that is defined on a group macro is passed down to all child macros.  
Any option that is directly set on a child macro will override the value propagated from the parent.

This makes grouping macros a good way to define many similar macros without having to repeat the same options definition over and over.

Options excluded from propagation are `type` and `name`.

Example:
```lua
-- In this example the child macros inherit the values of the 'loop', 'actionDelay' and 'play' options.
-- The value for 'gshift' is overridden on the child macros themselves, the value for 'type' is never propagated. 
k.m3= {
   type = "group", gshift = 2, loop= 5, actionDelay = 200, play = "toggle",
   { "abcde", type = "sequence", gshift = 0 },
   { "fghij", type = "sequence", gshift = 1 }
}
```