local rv = ... ---@type Revenant
local type, concat, assert, super = type, table.concat, assert, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _BaseControlOptions:MacroOptions
---@field targetGroup? string #The type of macro to control
---@field lcd? integer|boolean #If and for for how long should the control action be shown on the lcd display
---@field relative? boolean # When controlling cycles, set the position relative to the current cycle state.
--[[=============================================================]] --
---Assign a macro for issuing commands to cycles or continuously running macros. <br>[Documentation](https://github.com/Thertzlor/Revenant/wiki/Control-Macro)
---@alias AssignControl MacroInitDefinition<"cyclecontrol"|"macrocontrol","cc"|"mc",_BaseControlOptions,(l<string|integer>)[]>
--[[=============================================================]] --
---A macro for issuing commands to other continuously running macros.
---@class (exact) BaseControlMacro:MacroDefinition
---@field controlTargets string[] #array of IDs that are targeted by this macro
---@field command l<string>|string[][]
---@field controlShorthands table<string,string>
---@field options _BaseControlOptions
---@field controlArguments "resume"|"cancel"|"toggle"|"pause"
---@field private assignChecked boolean
---@field private postZero boolean
---@field private targetGroup "__continuous"|"cycle"
local BaseControlMacro = super:new()
BaseControlMacro.type = "macrocontrol"
BaseControlMacro.lintProperties = { --
   lcd = {type = {"number", "boolean"}},
   targetGroup = {type = "string"},
   relative = {type = "boolean"}
}
BaseControlMacro.controlShorthands = {p = "pause", c = "cancel", r = "resume", t = "toggle"}
BaseControlMacro.singleTrigger = true

---@protected
---@async
function BaseControlMacro:parseInstructions()
   local subList = self.command[1]
   self.assignChecked = false
   self.postZero = false
   if self.options.lcd == nil then self.options.lcd = true end
   self.controlTargets = {}
   self.controlArguments = self.controlShorthands[self.command[2]] or self.command[2] or "cancel" --[[@as string]]
   local cycleTarget = self.type == "cyclecontrol" -- are we controlling a cacle macro or some other continuous macro?
   self.targetGroup = (cycleTarget and "cycle") or (self.type == "macrocontrol" and (self.options.targetGroup or "__continuous")) or "__continuous"
   local arg = self.controlArguments ---@type l<string>
   if self.type == "cyclecontrol" then
      local argType = type(arg) -- weeding out incorrect types when parsing.
      assert(argType == "number" or (argType == "table" and (not arg[1] or type(arg[1] == "number")) and (not arg[2] or type(arg[2] == "number"))), "A Cycle control needs to be either a number or a table containing two numbers.")
   end
   if subList == "all" or subList == "" or not subList then return self:finishInit() end
   local cmd = (type(subList) ~= "table" and {subList}) or subList
   ---Getting the ID of the target macro
   ---@param name string
   ---@async
   local function setSub(name)
      local foundId = self:awaitId(name, true)
      if foundId then
         local targetMacro = rv.profile.macroIndex[foundId]
         if cycleTarget then
            if not targetMacro.type == "cycle" then error("The macro '" .. name .. "' is not a cycle macro") end
            if self.options.lcd then -- outputting what the macro does on the LCD screen
               local controlText = ""
               if type(arg) ~= "table" then arg = {arg} end
               if arg[1] then controlText = arg[1] == 0 and "Resetting position of '" .. name .. "'" or "Setting position of '" .. name .. "' to " .. arg[1] end
               if arg[2] then controlText = controlText .. (arg[1] and " and s" or "S") .. "etting the number of complete cycles to " .. arg[2] .. (arg[1] and "" or " on macro '" .. name .. "'") end
               targetMacro:parseControls(controlText, self.pID)
            end
         else -- non-synchronous macros can't be controlled, so we throw an error.
            if not targetMacro.continuous then error("The macro '" .. name .. "' of type " .. targetMacro.type .. " is not continuos") end
            if self.options.lcd then targetMacro:parseControls() end
         end
         self.controlTargets[#self.controlTargets + 1] = foundId
      end
   end

   for i = 1, #cmd do self:async(setSub, cmd[i]) end
   self:finishInit()
end

---@async
function BaseControlMacro:execute()
   if not self.assignChecked and #self.controlTargets ~= 0 then
      self.assignChecked = true
      local newTargets = {} ---@type string[]
      for i = 1, #self.controlTargets do
         local c = self.controlTargets[i]
         local mac = rv.profile.macroIndex[c]
         if not mac.assigned then
            local n = mac.name
            local id ---@type string|nil
            for l = 1, #rv.profile.stack do
               local s = rv.profile.stack[l]
               local nid = rv.profile.nameMap[s .. ":" .. n]
               if nid and rv.profile.macroIndex[nid].assigned then
                  id = nid
                  break
               end
            end
            if id then newTargets[#newTargets + 1] = id end
         else
            newTargets[#newTargets + 1] = c
         end
      end
      if self.options.lcd then for i = 1, #newTargets do rv.profile.macroIndex[newTargets[i]]:parseControls() end end
      self.controlTargets = newTargets
      if #self.controlTargets == 0 then self.postZero = true end
   end
   if #self.controlTargets ~= 0 then -- targeting specific macros
      for i = 1, #self.controlTargets do
         local target = rv.profile.macroIndex[self.controlTargets[i]]
         if target then target:control(self.controlArguments, self.options, self.options.lcd, self.msgDuration, self.pID) end
      end
   elseif not self.postZero then -- if we don't have specific targets, we are issuing commands to all macros of a certain type.
      local typedList = rv.profile:macrosByIdOrType(self.targetGroup)
      for i = 1, #typedList do
         local target = typedList[i]
         if target and target.assigned then target:control(self.controlArguments, self.options, self.options.lcd, self.msgDuration, self.pID) end
      end
   end
end

---@param depth? integer
function BaseControlMacro:stringify(depth)
   local cmd = self.command[1]
   if type(cmd) ~= "table" then cmd = {cmd} end
   local exText = ""
   if self.type == "cyclecontrol" then
      local arg = self.controlArguments ---@type l<string>
      local controlText = ""
      if type(arg) ~= "table" then arg = {arg} end -- constructing export text for display
      local name = type(cmd[1]) == "string" and cmd[1] or concat(cmd[1] ", ")
      if arg[1] then controlText = arg[1] == 0 and "Resetting position of '" .. name .. "'" or "Setting position of '" .. name .. "' to " .. arg[1] end
      if arg[2] then controlText = controlText .. (arg[1] and " and s" or "S") .. "etting the number of complete cycles to " .. arg[2] .. (arg[1] and "." or " on macro '" .. name .. "'.") end
      exText = controlText
   else ---@type string
      exText = (self.controlArguments) .. (#self.controlTargets == 0 and " all " or " ") .. (self.targetGroup == "__continuous" and "macro" or self.targetGroup) .. "s" .. (#self.controlTargets == 0 and "." or ": " .. concat(cmd, ", "))
   end
   return self:indent(depth) .. self.titleExport .. exText
end

return BaseControlMacro