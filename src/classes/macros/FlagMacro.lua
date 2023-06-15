local rv = ... ---@type Revenant
local type, concat = type, table.concat

--[[=============================================================]] --
---Assign a macro to toggle flag values that can be used in conditionals on other macros.
---@alias AssignFlag MacroInitDefinition|mt<"flag","f">
--[[=============================================================]] --
---A macro to toggle flag values that can be used in conditionals on other macros.
---@class FlagMacro:MacroDefinition
---@field command l<string>
local FlagMacro = rv.importer:classImport("MacroDefinition"):new()
FlagMacro.lintProperties = { ---@type OptionsLintPreset
   __none = {}
}
FlagMacro.lintCommand = {type = {"string", "table"}, tableKeys = "number", tableTypes = "string"}

function FlagMacro:execute()
   local cmd = self.command -- a flag macro may toggle one or multiple flags.
   if type(cmd) == "string" then
      rv.states.scriptStates.flags[cmd] = not rv.states.scriptStates.flags[cmd]
   else -- the second value in every flag is the value of a flag. For now, this has to be a string
      for i = 1, #cmd, 2 do
         local cm, cmNext = cmd[i], cmd[i + 1]
         if cmNext then
            rv.states.scriptStates.flags[cm] = cmNext
         else
            rv.states.scriptStates.flags[cm] = not rv.states.scriptStates.flags[cm]
         end
      end
   end
end

---@protected
function FlagMacro:parseInstructions()
   self.singleTrigger = (self.type == "toggleflag") -- this is the only difference between flag and toggleflag
   self:finishInit()
end

---@param depth? integer
function FlagMacro:export(depth)
   local cmd = self.command
   return self:indent(depth) .. self.titleExport .. (self.singleTrigger and "set" or "toggle") .. " flag" .. (type(cmd) == "string" and "" or "s") .. " " .. (type(cmd == "string" and cmd or concat(cmd --[[ @as string[] ]] , ", ")))
end

return FlagMacro
