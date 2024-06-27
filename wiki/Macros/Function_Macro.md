This macro lets a button run an arbitrary lua function.  
`type` value `func` or `f`

### Complete Syntax:
>`{ <function/name>  [, <arguments[]> ] , type="func"|"f" [, async=<boolean>] }`

Example:
```lua
--This enables access to the lua libraries and logitech API
rv.utils.developerMode()

-- A simple global function that logs a message to the Logitech lua window
function customFunction()
OutputLogMessage("Hello World")
end

-- Passing the function as a name
k.m3 = { "customFunction"  type="func"}
```

# Functionality

The macro receives one or two commands. The first being either the name of a global function or simply a directly defined function. The second command is an table of arguments that will be passed to the function when it is called.

Example:
```lua
--This enables access to the lua libraries and logitech API
rv.utils.developerMode()


-- Defining a function directly on the macro
k.m3 = { function() OutputLogMessage("direct function")  end ,  type="func"}

-- Another simple function
function addingFunction(a,b)
   OutputLogMessage("I am doing maths: "..a.. "+"..b.."="..(a+b))
end

-- Passing a list of 2 parameters as the second command
-- This will output ""I am doing maths: 2+4=6"
k.m4 = { "addingFunction", {2,4} ,  type="func"}
```

# Options
Besides the [General Macro Options]() the Function Macro offers the following options to customize behavior:
## async
For functions that involve complex or continuos computations, we can run a function asynchronous (for lua that means in a coroutine), so that the rest of the profile won't be blocked.

Default value: `false`

Example:
```lua
k.m3 = { 
   function() 
      OutputLogMessage("direct function")  
   end 
   , async=true,  type="func"}
```