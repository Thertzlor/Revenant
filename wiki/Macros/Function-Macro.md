This macro lets you run an arbitrary lua function.  
`type` value `func` or `f`

### Complete Syntax:
>`{ type="func"|"f", <function/name>  [, <arguments[]> , async=<boolean>] }`
```lua

--This enables access to the lua libraries and logitech API
rv.utils.developerMode()

-- A simple global function that logs a message to the Logitech lua window
function customFunction()
OutputLogMessage("Hello World")
end

-- Passing the function as a name
k.m3 = { type="func", "customFunction" }

```
# Functionality

The macro receives one or two commands. The first being either the name of a global function or simply a directly defined function. The second command is an table of arguments that will be passed to the function when it is called.
```lua

--This enables access to the lua libraries and logitech API
rv.utils.developerMode()


-- Defining a function directly on the macro
k.m3 = { type="func", function() OutputLogMessage("direct function")  end  }

-- Another simple function
function addingFunction(a,b)
   OutputLogMessage("I am doing maths: "..a.. "+"..b.."="..(a+b))
end

-- Passing a list of 2 parameters as the second command
-- This will output ""I am doing maths: 2+4=6"
k.m4 = { type="func", "addingFunction", {2,4} }

```
# Options
Besides the [General Macro Options](./Macro-Overview#general-macro-options) the Function Macro offers the following options to customize behavior:
## async
For functions that involve complex or continuos computations, we can run a function asynchronous (for lua that means in a coroutine), so that the rest of the profile won't be blocked from receiving events and running other macros.  
Interruptions can be implemented with the rv.threading:wait method or directly with coroutine.yield (revenant expects `yield` to return a number which will be interpreted as the number of milliseconds to wait) .

Default value: `false`

```lua

--This enables access to the lua libraries and logitech API
rv.utils.developerMode()

-- A directly defined async function.
k.m3 = { 
   type="func" 
   
   function() 
      
      OutputLogMessage("this is logged immediately")

      rv.threading:wait(500)

      OutputLogMessage("this is logged after 500ms")

      rv.threading:wait(0)

      OutputLogMessage("This is logged as soon as possible but other logic could run in-between")

   end, 
   
   async=true 
}

```