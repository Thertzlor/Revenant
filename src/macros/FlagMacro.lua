local rv = ... ---@type Revenant
local type, concat, super = type, table.concat, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---Assign a macro to toggle flag values that can be used in conditionals on other macros. <br>[Documentation](https://github.com/Thertzlor/Revenant/wiki/Flag-Macro)
---@alias AssignFlag MacroInitDefinition<"flag","f",_FlagOptions,(l<string>)[]>
--[[=============================================================]] --
---@class _FlagOptions:MacroOptions
---@field toggle? boolean #true if the flag should only be toggled on key down
--[[=============================================================]] --
---A macro to toggle flag values that can be used in conditionals on other macros.
---@class (exact) FlagMacro:MacroDefinition
---@field command table
---@field setValues table<string,any>
---@field options _FlagOptions
---@field explicitSetter boolean
local FlagMacro = super:new()
FlagMacro.type = "flag"
FlagMacro.lintProperties = { --
   toggle = {type = "boolean"}
}
FlagMacro.lintCommand = { --
   type = {"string", "boolean"},
   tableKeys = "number",
   tableTypes = {"string"}
}

function FlagMacro:execute()
   local cmd = self.command -- a flag macro may toggle one or multiple flags.
   if not self.explicitSetter then
      for i = 1, #cmd do
         local fl = cmd[i] ---@type string
         local val = rv.states.scriptStates.flags[fl]
         self.setValues[fl] = val
         rv.states.scriptStates.flags[fl] = not val
         rv.states.scriptStates.lastAccess['f_' .. fl] = self.pID
      end
   else -- the second value in every flag is the value of a flag. For now, this has to be a boolean
      for i = 1, #cmd, 2 do
         local cm, cmNext = cmd[i], cmd[i + 1] ---@type string , boolean
         local val = rv.states.scriptStates.flags[cm]
         self.setValues[cm] = val
         rv.states.scriptStates.flags[cm] = cmNext
         rv.states.scriptStates.lastAccess['f_' .. cm] = self.pID
      end
   end
end

---When a flag macro times out, it unsets the flags it previously set.
function FlagMacro:onTimeout()
   local cmd = self.command
   local accessor = rv.states.scriptStates.lastAccess
   local iteratorValue = self.explicitSetter and 2 or 1
   for i = 1, #cmd, iteratorValue do
      local fl = cmd[i] ---@type string
      if (accessor['f_' .. fl] or self.pID) == self.pID then rv.states.scriptStates.flags[fl] = self.setValues[fl] end
   end
end

---@protected
---@async
function FlagMacro:parseInstructions()
   local tog = self.options.toggle
   self.setValues = {}
   self.singleTrigger = tog -- this is the only difference between flag and toggleflag
   local cmd = self.command ---@cast cmd table
   if #cmd == 1 and type(cmd[1]) == "table" then
      self.explicitSetter = true
      local subtable = cmd[1] ---@type (string|boolean)[]
      local mes = "an explicit assignment table needs to consist of string-boolean pairs"
      if #subtable % 2 ~= 0 then error(mes) end
      for i = 1, #subtable, 2 do if type(subtable[i]) ~= "string" or type(subtable[i + 1]) ~= "boolean" then error(mes) end end
      self.command = subtable
   elseif not rv.tbl:isSingleTypeTable(cmd, "string") then
      error("All flag names need to be strings")
   end
   self:finishInit()
end

---@param depth? integer
function FlagMacro:stringify(depth)
   local cmd = self.command
   ---@type string[]
   local strcmd = {}
   if type(cmd) == "table" then for i = 1, #cmd do strcmd[#strcmd + 1] = tostring(cmd[i]) end end
   return self:indent(depth) .. self.titleExport .. (self.singleTrigger and "set" or "toggle") .. " flag" .. (type(cmd) == "string" and "" or "s") .. " " .. (type(cmd == "string" and cmd or concat(strcmd, ", ")))
end

return FlagMacro