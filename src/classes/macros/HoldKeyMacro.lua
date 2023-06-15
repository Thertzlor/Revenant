local rv = ... ---@type Revenant
local remove, type, insert, GetRunningTime = table.remove, type, table.insert, GetRunningTime

--[[=============================================================]] --
---@alias TimerCommand {[1]:integer,[2]:string}|{[1]:string}
--[[=============================================================]] --
---@class _HoldKeyOptions:MacroOptions
---@field init boolean #launch the first macro immediately upon button press
---@field release "auto"|"hold" #should the last macro play when the button is released, or directly when the timer triggers
---@field holdTime integer #The default number of milliseconds between macros
---@field holdMode "absolute"| "relative"| "additive" #decide how the timing  between multiple macros is calculated
--[[=============================================================]] --
---Assign a macro that triggers different actions depending on how long a key is pressed.
---@alias AssignHoldKey _HoldKeyOptions | MacroInitDefinition | mt<"holdkey","h">
--[[=============================================================]] --
---@class HoldStats:MacroStatContainer
---@field stagTimer integer #The exact time the button was pressed
--[[=============================================================]] --
---A macro that triggers different actions depending on how long a key is pressed.
---@class HoldKeyMacro:MacroDefinition
---@field options _HoldKeyOptions
---@field state HoldStats
---@field autoTrigger? {[1]:integer,[2]:string}
---@field keyData KeyObject[]
local HoldKeyMacro = rv.importer:classImport("MacroDefinition"):new()
HoldKeyMacro.terminus = false
HoldKeyMacro.continuous = true

HoldKeyMacro.lintProperties = { ---@type OptionsLintPreset
   release = {type = "string", values = {"auto", "hold"}},
   init = {type = "boolean"},
   holdMode = {type = "string", values = {"absolute", "relative", "additive"}},
   holdTime = {type = "number"}
}

---@protected
---@async
function HoldKeyMacro:parseInstructions()
   local options = self.options
   self.keyData = {}
   options.holdTime = options.holdTime or rv.profile.config.defaultHold
   options.release = options.release or "auto" -- by default we don't wait until button release for the last macro
   options.holdMode = options.holdMode or "relative"
   local originalCommands = rv.utils.deepCopy(self.rawCommand)
   local processed = 0
   local command = {} ---@type (string|number|{_ref:string})[]
   local offset = 0

   ---Finalizing through the list of macros once all of them have been properly identified.
   ---@async
   local function finalIteration()
      if self.init then return end
      local stagMode = options.holdMode
      local defaultDelay = options.holdTime
      local lastCommand = remove(command) ---@type string|number|{_ref:string}
      local lastNum = -1
      local workTab = {} ---@type table<number,TimerCommand|{_ref:string}>
      local currentDelay = 0
      local lastDelay

      if type(lastCommand) == "number" then
         defaultDelay = lastCommand -- if the last entry is a number it's used as the default delay
         lastDelay = lastCommand
      else
         command[#command + 1] = lastCommand
      end

      if options.init then -- preparing the timing function for launching the first macro immediately
         self.terminus = true
         self.initMacro = remove(command, 1) -- separating the last macor from the list
         if type(self.initMacro) == "table" and self.initMacro._ref then
            local ref = self.initMacro._ref
            self.initMacro = {ref}
            ---@async
            self:async(function()
               local fetched = self:awaitId(ref, true)
               self.references[#self.references + 1] = fetched
               self.initMacro = {fetched}
            end)
         end
      end
      ---iterating the macro list and identifying the command types
      for i = 1, #command do
         local cmd = command[i]
         if type(cmd) == "number" then
            defaultDelay = cmd -- all following macros will be delayed by the new amount
            lastNum = i
         else
            if #workTab ~= 0 then -- handling the different types of delay definitions
               if stagMode == "absolute" then
                  currentDelay = defaultDelay
               else
                  if stagMode ~= "additive" and i ~= lastNum + 1 then defaultDelay = lastDelay or options.holdTime end
                  currentDelay = currentDelay + defaultDelay
               end
            end
            insert(workTab, {currentDelay, cmd})
         end
      end -- separate timer handling for the last macro if we are not waiting for key up
      if self.options.release == "auto" then self.autoTrigger = remove(workTab) end
      self.command = workTab
      for i = 1, #self.command do
         local finalCommand = self.command[i][2]
         if type(finalCommand) == "table" and finalCommand._ref then
            local ref = finalCommand._ref
            self.command[i] = {ref}
            self:async(self.replaceWithReferenceId, self, ref, 2, self.command[i], true)
         end
      end
      self:finishInit()
   end

   ---Getting the subMacro id for the command list
   ---@param index integer #the index at which the fetched ID will be inserterted
   ---@param class MacroDefinition #The macro to initiate
   ---@async
   local function fetcher(index, class)
      local initId = class:awaitOwnId()
      if initId then self.subMacros[#self.subMacros + 1] = initId end
      command[index] = {initId}
      processed = processed + 1 -- finalizing this macro once all sub macros are processed
      if processed == #originalCommands then finalIteration() end
   end

   for i = 1, #originalCommands do
      local cmd = originalCommands[i]
      local commandType = type(cmd)
      if commandType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then
         command[i - offset] = {_ref = cmd[1]} -- any table with only a single string inside is a macro reference.
         processed = processed + 1
      elseif commandType == "table" then -- any other table has to be a macro
         local macroClass ---@type MacroDefinition|false
         if (not rv.tbl:hasProperties(cmd)) and rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
         local tableType = rv.tbl:identifyTableType(cmd) -- getting the right macro class
         if tableType == "group" then
            macroClass = rv.importer:classImport("GroupMacro")
         elseif tableType == "macro" then
            macroClass = rv.tbl:getMacroClass(cmd)
         end
         if not macroClass then return end
         local macroInstance = macroClass:new(cmd, nil, self.sourceDevice, self.stack)
         self:async(fetcher, (i - offset), macroInstance) -- getting the final id into the command list
      elseif commandType == "string" or commandType == "number" then
         if commandType == "string" then self.keyData[i - offset] = rv.keys:keyParser(cmd) end
         command[i - offset] = cmd
         processed = processed + 1
      else -- ignoring all unknown types
         offset = offset + 1
         processed = processed + 1
      end
      if processed == #originalCommands then finalIteration() end
   end
end

---Auto execute function for staggered keys after timer runs out
---@private
---@param event Event
---@async
function HoldKeyMacro:finalStagger(event)
   local mac = self.autoTrigger
   if mac == nil then return end
   rv.threading:wait(mac[1], 0)
   if self.state.stagTimer ~= nil then
      self.state.stagTimer = nil
      self:subRun(mac[2], event, 0)
   end
   return -1
end

---Timing function for held down keys
---@param event Event
---@async
function HoldKeyMacro:execute(event)
   local fam, num, dir, cmd, pID = event.family, event.keyNum, event.direction, self.command, self.pID
   if #cmd == 0 then return end -- nothing to do if there's no command.
   local time = GetRunningTime()
   local direction = dir or rv.profile.deviceState[fam].dir
   local virtualEvent = self:virtualize(event, 4) -- virtual event to pass to sub macros
   if self.initMacro then self:subRun(self.initMacro, virtualEvent, 0) end
   if direction == "down" then -- saving the time the button was, pressed optionally running the first macro
      if self.autoTrigger then rv.threading:taskRun(pID, fam, num, self.finalStagger, self, virtualEvent) end
      self.state.stagTimer = time
   elseif direction == "up" and self.state.stagTimer ~= nil then
      local timeNow = time - self.state.stagTimer
      for g = 1, #cmd do
         local i = #cmd - g + 1
         local currentCommand = cmd[i] -- launching the first macro whose delay is smaller than the passed time.
         if currentCommand[1] < timeNow then
            self:subRun(currentCommand[2], virtualEvent, i)
            break
         end
      end
      self.state.stagTimer = nil
   end
end

---@async
function HoldKeyMacro:parseDocs()
   if self.manualDocumentation then
      rv.lcd:parseToTextDisplay(self.manualDocumentation, self.pID)
   else -- exporting docs of all sub macros
      for i = 1, #self.command do
         local cmd = self.command[i][2] ---@type string
         if type(cmd) == "string" then rv.lcd:parseToTextDisplay(cmd, self.pID .. "_" .. i) end
      end
   end
end

---@private
---Running a sub macro or typing a string
---@param evStr l<string>
---@param event Event
---@param index number
---@async
function HoldKeyMacro:subRun(evStr, event, index)
   if type(evStr) == "table" then
      rv.profile.macroIndex[evStr[1]]:run(event)
   else
      rv.keys:typingDelegator(self.keyData[index], self:keyPress(event), self.pID .. "_" .. index)
   end
end

---control macros can be used to cancel a currently held down holdkey macro
---@param event  Event
function HoldKeyMacro:control(event)
   local dir = event.direction
   if dir and dir ~= "down" then return end
   self.state.stagTimer = nil
end

return HoldKeyMacro
