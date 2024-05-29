Although Revenant mostly aims at cutting out the need for lua programming, it would be a shame to disadvantage people with lua skills.  
The framework offers multiple of ways of 
# Accessing the Revenant class inside a Profile
For anyone implementing their own logic within their profiles Revenant exposes a multitude of modules and functions. Accessing Revenant from your profile is easy:  
Any external profile is loaded via the `loadfile` function, injecting the Assignment object as its first parameter. The `Revenant` class itself is passed as the second parameter, although it is not assigned to a variable in the default profile preset:
```lua
local profile = ... ---@type ProfileTemplate#, Revenant
```
You might have already noticed that there is a second commented out type definition at the very end of the docstring. To access all Revenant modules and functions with full intellisense simply assign a second variable (here called `rv`) and remove the hash in the comment:
```lua
local profile,rv = ... ---@type ProfileTemplate, Revenant
```
The full power of Reventant is now at your disposal.
# Activating Developer Mode
By default Profile definitions run in a sandboxed lua context that disables all the built in global variables and functions. This is to prevent anyone building profiles without lua knowledge from accidentally referencing a variable, triggering a function or otherwise interacting with lua in a way they did not intend while building the assignment table.  
To regain access the profile needs to enable "developer mode" which is accessible through the `utils` module of the `Revenant` class:
```lua
local profile,rv = ... ---@type ProfileTemplate, Revenant

rv.utils.developerMode()
```
After invoking this function in the top level of the file, the core lua libraries (that is, to the subset included in Logitech's lua engine) can now be used.
# Working with Hooks
The core of Revenant involves intercepting and processing the Logitech button events. A natural way to extend or modify is through hooks which allow you to run your logic just when Revenant triggers its own.

Six types of hooks are provided: [onEventHook](#oneventhook), [onEventHookAsync](#oneventhookasync), [onInitHook](#oninithook),[onInitHookAsync](#oninithookasync),[onPollHook](#onpollhook) and [onRandom](#onrandom).

All can be accessed through the `hooks` property of the `ProfileTemplate` object.

> **Hint:** Only use hooks if you're *really* need to. Consider if a function for the `onEvent` hook could be put on a [function macro]() instead. 

## onEventHook
Define a function that runs every time Revenant receives a non-polling event. Triggers before any macro run and regardless if any macro is assigned for this particular event. 

This hook receives three arguments which are identical to the ones received by the Logitech `OnEvent` function: The type of the event, the number of the key and the family of the device. For more details about those parameters you can consult the Logitech API documentation.
## onEventHookAsync
Async version of the onEventHook, for use in cases where the computation could take some time but we don't want to block the execution of any other macros.
## onInitHook
> **Hint:** If you do not plan on modifying Revenant's core functionalities your logic would probably better stored ina  Function Macro on the profile's *start* binding.

## onInitHookAsync

## onPollHook
A function invoked on every poll event.
If anything super complex here it there's risk of slowing down macro execution and general responsiveness, so handle with care.

There is no async version of the `onPollHook` because the polling itself defines the scheduling logic through which async tasks are managed.
## onRandom
This hook is invoked whenever Revenant requests a random number such as for `actionVariation` and `keyVariation`
The output of this function will be used in place of the generic logic using lua's `math.random`.  
This hook receives no arguments and must return a number, between 0 and 1.