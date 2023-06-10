local rv = ... ---@type Revenant
local type, running, huge, ceil, pairs, concat, rep = type, coroutine.running, math.huge, math.ceil, pairs, table.concat, string.rep
-- TODO: Annotations
---@class _SequenceOptions:MacroOptions
---@field play "normal"|"toggle"|"hold"|"phold"|"ptoggle"
---@field actionDelay integer #The number of milliseconds to wait between actions such as keypresses
---@field keyDelay integer #The number of milliseconds to wait between key-down and key-up
---@field keyVariance integer #Maximum range of random variation in the keyDelay in milliseconds
---@field actionVariance integer #Maximum range of random variation in the actionDelay in milliseconds
---@field stack 0|1|2 #Set stacking mode
---@field loop integer #number of times to play the sequence
--[[=============================================================]] --
---@class __SequenceShorthands
---@field ad integer #Shorthand for "actionDelay"
---@field kd integer #Shorthand for "keyDelay"
---@field av integer #Shorthand for "actionVariance"
---@field kv integer #Shorthand for "keyVariance"
---@field l integer #Shorthand for "loop"
---@field p "normal"|"toggle"|"hold"|"phold"|"ptoggle" #Shorthand for "play"
--[[============================================================]] --
---Assign a macro to play multiple other macros sequentially, heavily configurable.
---@alias AssignSequence _SequenceOptions|__SequenceShorthands|MacroInitDefinition|mt<"sequence"|"s">
--[[=============================================================]] --
---A macro to play multiple other macros sequentially, heavily configurable.
---@class SequenceMacro:MacroDefinition
---@field options _SequenceOptions
---@field command {[1]:any[],[2]:any[]}
---@field rawCommand any[]|string
local SequenceMacro = rv.importer:classImport("MacroDefinition"):new()

SequenceMacro.lintProperties = { ---@type OptionsLintPreset
   actionDelay = {type = "number", range = {0}},
   actionVariance = {type = "number", range = {0}},
   keyVariance = {type = "number", range = {0}},
   keyDelay = {type = "number", range = {0}},
   loop = {type = "number", range = {-1}},
   play = {type = "string", values = {"hold", "toggle", "normal", "phold", "ptoggle"}}
}

SequenceMacro.shorthands = {l = "loop", p = "play", av = "actionVariance", ad = "actionDelay", kv = "keyVariance", kd = "keyDelay"}

---@protected
function SequenceMacro:parseInstructions()
   self.command = {{}, {}}
   self.options.play = self.options.play or "normal"
   self.options.stack = self.options.stack or rv.profile.config.defaultStacking
   local offset = 0
   local processed = 0
   local tempCommand = {}
   local sequenceDelays = {}
   local delayTable = {}
   local defOrder = {"actionDelay", "keyDelay", "actionVariance", "keyVariance"}
   for i = 1, #defOrder do
      local def = defOrder[i]
      sequenceDelays[def] = self.options[def] or rv.profile.config[def]
   end
   ---@param str string
   ---@param defaults table<string,string>
   local function stringOutputGenerator(str, defaults)
      local keyData = rv.keys:keyParser(str)
      ---@param press KeyPress
      ---@param export? boolean
      return function(press, export)
         if export then return str end
         for k, v in pairs(defaults) do press[k] = v end
         rv.keys:typingDelegator(keyData, press)
      end
   end

   ---@param time integer
   ---@param variance integer
   local function delayGenerator(time, variance)
      return function(_, export)
         if export then
            return time
         else
            rv.threading:wait(time, variance)
         end
      end
   end

   local function finalIteration()
      if self.init then return end
      local waitCache = 0
      for i = 1, #tempCommand do
         local cmd, cmdNext = tempCommand[i], tempCommand[i + 1]
         if type(cmd) == "table" and type(cmd[1]) == "number" then
            waitCache = waitCache + cmd[1]
            if not cmdNext or type(cmdNext) ~= "table" or type(cmdNext[1]) ~= "number" or not rv.tbl:sameContent(cmd[2], cmdNext[2]) then
               self.command[1][#self.command[1] + 1] = delayGenerator(waitCache, cmd[2])
               self.command[2][#self.command[2] + 1] = delayTable[i]
               waitCache = 0
            end
         else
            self.command[1][#self.command[1] + 1] = cmd
            self.command[2][#self.command[2] + 1] = delayTable[i]
         end
      end
      for i = 1, #self.command[1] do
         local finCm = self.command[1][i]
         if type(finCm) ~= "function" and finCm._ref then
            local ref = finCm._ref
            self.command[1][i] = {ref}
            self:async(self.replaceWithReferenceId, self, ref, i, self.command[1], true)
         end
      end
      self:finishInit()
   end

   local rc = self.rawCommand
   if type(rc) == "string" then
      self.command = {{stringOutputGenerator(rc, sequenceDelays)}, sequenceDelays}
      return finalIteration()
   end

   ---@param tNum integer
   ---@param class MacroDefinition
   local function fetchSubMacro(tNum, class)
      local initId = class:awaitOwnId()
      if initId then self.subMacros[#self.subMacros + 1] = initId end
      tempCommand[tNum] = {initId}
      processed = processed + 1
      if processed == #self.rawCommand then finalIteration() end
   end

   for i = 1, #self.rawCommand do
      local el = self.rawCommand[i]
      delayTable[i] = rv.tbl:intersectSimple(sequenceDelays, {})
      if type(el) == "table" then
         if #el == 1 and type(el[1]) == "string" and not rv.tbl:hasProperties(el) then
            processed = processed + 1
            tempCommand[i - offset] = {_ref = el[1]}
         elseif not (rv.tbl:isSingleTypeTable(el, "number") and not rv.tbl:hasProperties(el)) then
            if (rv.tbl:isSingleTypeTable(el, "string") and not rv.tbl:hasProperties(el)) then el.type = "key" end
            local currentCLass ---@type MacroDefinition|false
            local tableType = rv.tbl:identifyTableType(el)
            if tableType == "group" then
               if (el.loop or el.l) then
                  currentCLass = rv.importer:classImport("SequenceMacro")
               else
                  currentCLass = rv.importer:classImport("GroupMacro")
               end
            elseif tableType == "macro" then
               currentCLass = rv.tbl:getMacroClass(el)
            end
            if not currentCLass then return end
            local elInstance = currentCLass:new(el, rv.tbl:intersectSimple(sequenceDelays, self.defaults), self.sourceDevice, self.stack)
            self:async(fetchSubMacro, (i - offset), elInstance)
         elseif rv.tbl:isSingleTypeTable(el, "number") and not rv.tbl:hasProperties(el) then
            offset = offset + 1
            processed = processed + 1
            for n = 1, #defOrder do
               local def = defOrder[n]
               if el[n] and el[n] >= 0 then
                  sequenceDelays[def] = el[n]
               elseif el[n] == -1 then
                  sequenceDelays[def] = self.options[def] or rv.profile.config[def]
               elseif el[n] == -2 then
                  sequenceDelays[def] = rv.profile.config[def]
               end
            end
            delayTable[i] = rv.tbl:intersectSimple(sequenceDelays, {})
         end
      elseif type(el) == "number" then
         tempCommand[i - offset] = {el, sequenceDelays.actionVariance}
         processed = processed + 1
      elseif type(el) == "string" then
         processed = processed + 1
         tempCommand[i - offset] = stringOutputGenerator(el, sequenceDelays)
      else
         offset = offset + 1
         processed = processed + 1
      end
      if processed == #self.rawCommand then finalIteration() end
   end
end

---Main function for executing macro sequences
---@param event Event
---@return integer
function SequenceMacro:execute(event)
   local id = self.pID
   local dir = event.direction
   local vir = event.virtualType
   local fam = event.family
   local mos = event.keyNum
   local descPlay = self.direction
   local sequence = self.command[1]
   local delays = self.command[2] ---@type OptionsCollection
   local descDir = descPlay or "normal"
   local mode = self.options.play
   local press = self:keyPress(event)
   if ((mode == "normal" or mode == "toggle" or mode == "ptoggle") and (dir ~= nil and dir ~= "down") and descDir ~= "up") or (descDir == "up" and dir == "down") then return -1 end

   local stackMode = self.options.stack
   local buttonNo = mos or 0
   local taskState = rv.threading:taskStatus(id)
   local taskActive = taskState ~= 0
   if taskActive then
      if mode == "toggle" or mode == "hold" then
         rv.threading:taskAbort(id)
      elseif (mode == "ptoggle" or mode == "phold") and taskState == 1 then
         rv.threading:multiPause(id)
      elseif (mode == "ptoggle" or mode == "phold") then
         rv.threading:taskResume(id)
      elseif mode == "normal" and taskState == 1 then
         if stackMode == 0 then
            rv.threading:taskAbort(id)
            rv.threading:taskRun(id, fam, buttonNo, self.execute, self, self:virtualize(event, 1))
         elseif stackMode == 2 then
            rv.threading:sequenceQueue(id, fam, nil, dir, descDir, buttonNo, vir, fam)
         elseif stackMode == 1 then
            rv.threading:taskAbort(id)
         end
      elseif mode == "normal" then
         rv.threading:taskResume(id)
      end
      return -1
   elseif dir == "up" and descDir ~= "up" then
      return -1
   end
   local subSequence = running()
   -- ^^ dealing with toggling sequences
   ---TODO:What is so special about state 3 but not 2?
   if subSequence == nil and vir ~= 1 and vir ~= 3 and (not taskActive) and not rv.states.scriptStates.exitingScript then -- launching coroutines
      rv.threading:taskRun(id, fam, buttonNo, self.execute, self, self:virtualize(event, 1))
      return -1
   end
   if subSequence then rv.threading:addSubtask(id) end
   local virtualEvent = self:virtualize(event, 1)
   local looper = self.options.loop or 1
   local loopNum = #sequence * looper
   local loopStart = (self.state.seqPosition) or 1
   if looper == 0 then
      return -1
   elseif looper < 0 then
      loopNum = huge
   end
   for g = loopStart, loopNum do
      local i = g - (#sequence * (ceil((g / #sequence - 1) + 1) - 1))
      local obj = sequence[i]
      if i ~= 1 then rv.threading:wait(delays[i].actionDelay, delays[i].actionVariance) end
      if type(obj) == "table" then
         rv.profile.macroIndex[obj[1]]:run(virtualEvent)
      elseif type(obj) == "function" then
         obj(press)
      end
   end
   if subSequence then rv.threading:removeSubtask(id) end
   return -1
end

---@param depth integer
function SequenceMacro:export(depth)
   depth = depth or 1
   local indent = rep("  ", depth)
   local subTable = {} ---@type string[]
   local function desig(input) return indent .. (type(input) == "number" and "delay: " .. input or "\"" .. rv.str:unbreak(input) .. "\"") end

   for i = 1, #self.command[1] do
      local cmd = self.command[1][i]
      subTable[#subTable + 1] = type(cmd) == "string" and ("\"" .. rv.str:unbreak(cmd) .. "\"") or type(cmd) == "function" and (indent .. desig(cmd(nil, true))) or rv.profile.macroIndex[cmd[1]]:export(depth + 1)
   end
   local content = #subTable == 0 and false or "\n" .. indent .. concat(subTable, ",\n" .. indent)
   return indent .. self.titleExport .. "Sequence: (" .. indent .. (content or "") .. "\n" .. indent .. ")"
end

return SequenceMacro
