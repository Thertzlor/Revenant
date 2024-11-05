local rv = ... ---@type Revenant
local type, huge, ceil, pairs, concat, super = type, math.huge, math.ceil, pairs, table.concat, rv.importer:classImport("MacroDefinition")
---@alias DelayDefinition {actionDelay:integer, keyDelay:integer, actionVariance:integer, keyVariance:integer}
--[[=============================================================]] --
---@class (exact) _SequenceOptions:ThreadedMacroOptions
---Decide when and how the macro will play
---@field actionDelay? integer #The number of milliseconds to wait between actions such as keypresses
---@field keyDelay? integer #The number of milliseconds to wait between key-down and key-up
---@field keyVariance? integer #Maximum range of random variation in the keyDelay in milliseconds
---@field actionVariance? integer #Maximum range of random variation in the actionDelay in milliseconds
---Set stacking mode which applies when more than one of the *same* sequence is triggered multiple times.
---@field loop? integer #number of times to play the sequence. <br> Set to `-1` to loop indefinitely.
--[[=============================================================]] --
---@class (exact) __SequenceShorthands
---@field ad? integer #Shorthand for "actionDelay"
---@field kd? integer #Shorthand for "keyDelay"
---@field av? integer #Shorthand for "actionVariance"
---@field kv? integer #Shorthand for "keyVariance"
---@field l? integer #Shorthand for "loop"
---Shorthand for "play"
---@field p?
---|"normal" # Play when the button is pressed
---|"toggle" # Play when the button is pressed, cancel when pressed again.
---|"hold" # Play while the button is held, cancel on keyup
---|"ptoggle" # Play while the button is pressed, pause when pressed again
---|"phold" # play while the button is held, pause on keyup.
--[[============================================================]] --
---Assign a macro to play multiple other macros sequentially, heavily configurable.
---@alias AssignSequence MacroInitDefinition<"sequence","s",_SequenceOptions|__SequenceShorthands,(MacroGeneric|integer|string)[]>
--[[=============================================================]] --
---A macro to play multiple other macros sequentially, heavily configurable.
---@class (exact) SequenceMacro:MacroDefinition
---@field options _SequenceOptions
---@field unstable boolean
---@field command {[1]:any[],[2]:any[]}
---@field private rawCommand any[]|string
local SequenceMacro = super:new()
SequenceMacro.type = "sequence"
SequenceMacro.lintProperties = { --
   actionDelay = {type = "number", range = {0}},
   actionVariance = {type = "number", range = {0}},
   keyVariance = {type = "number", range = {0}},
   keyDelay = {type = "number", range = {0}},
   loop = {type = "number", range = {-1}},
   cancel = {type = "boolean"}
}

SequenceMacro.continuous = true

SequenceMacro.shorthands = {l = "loop", p = "play", av = "actionVariance", ad = "actionDelay", kv = "keyVariance", kd = "keyDelay"}

---@protected
---@async
function SequenceMacro:parseInstructions()
   self.command = {{}, {}}
   if self.options.interrupts == nil then self.options.interrupts = rv.profile.config.defaultThreadInterrupt end
   self.unstable = rv.profile.config.defaultThreadCancel
   if self.options.cancel ~= nil then self.unstable = self.options.cancel end
   self.options.play = self.options.play or "normal"
   self.options.stack = self.options.stack or rv.profile.config.defaultStacking
   local offset = 0
   local processed = 0
   local tempCommand = {} ---@type any[]
   local sequenceDelays = {} ---@type DelayDefinition
   local delayTable = {} ---@type DelayDefinition[]
   local defOrder = {"actionDelay", "keyDelay", "actionVariance", "keyVariance"}
   for i = 1, #defOrder do
      local def = defOrder[i]
      sequenceDelays[def] = self.options[def] or rv.profile.config[def]
   end
   ---factory function for key events
   ---@param str string
   ---@param defaults table<string,integer>
   local function stringOutputGenerator(str, defaults)
      local keyData = rv.keys:keyParser(str)
      ---@param press KeyPress
      ---@param export? boolean
      ---@async
      return function(press, export)
         if export then return str end -- for documentation mode and output
         for k, v in pairs(defaults) do
            press[k] = v ---@type integer
         end -- overriding with defaults
         rv.keys:typingDelegator(keyData, press) -- typing our string
      end
   end

   ---factory function for wait events
   ---@param time integer
   ---@param variance integer
   local function delayGenerator(time, variance)
      ---@async
      return function(_, export)
         if export then
            return time -- for documentation mode and output
         else
            rv.threading:wait(time, variance) -- actual waiting function
         end
      end
   end

   ---@async
   local function finalIteration()
      if self.init then return end
      local waitCache = 0
      for i = 1, #tempCommand do -- in the final iteration all the structures have been resolved and we can replace them with functions
         local cmd, cmdNext = tempCommand[i], tempCommand[i + 1]
         if type(cmd) == "table" and type(cmd[1]) == "number" then ---@cast cmd any[]|{[1]:integer}
            waitCache = waitCache + cmd[1] -- this merges multiple sequential wait commands into one.
            if not cmdNext or type(cmdNext) ~= "table" or type(cmdNext[1]) ~= "number" or not rv.tbl:sameContent(cmd[2], cmdNext[2]) then
               self.command[1][#self.command[1] + 1] = delayGenerator(waitCache - delayTable[i].actionDelay, cmd[2])
               self.command[2][#self.command[2] + 1] = {actionDelay = 0, keyDelay = 0, actionVariance = 0, keyVariance = 0}
               waitCache = 0 -- resetting the "saved" waiting time
            end
         else
            self.command[1][#self.command[1] + 1] = cmd
            self.command[2][#self.command[2] + 1] = delayTable[i]
         end
      end
      self:finishInit()
   end

   local rc = self.rawCommand
   if type(rc) == "string" then -- if all we have is a string we can skip the rest of the parsing logic
      self.command = {{stringOutputGenerator(rc, sequenceDelays)}, sequenceDelays}
      return finalIteration()
   end

   ---@param tNum integer
   ---@param class MacroDefinition
   ---@async
   local function fetchSubMacro(tNum, class)
      local initId = class:awaitOwnId()
      if initId then self.subMacros[#self.subMacros + 1] = initId end
      tempCommand[tNum] = {initId}
      processed = processed + 1 -- we call finalIteration once every single sub-macro is initialized.
      if processed == #self.rawCommand then finalIteration() end
   end

   for i = 1, #self.rawCommand do
      local el = self.rawCommand[i]
      delayTable[i] = rv.tbl:intersectSimple(sequenceDelays, {}) -- saving the state of delays at this point in the macro
      if type(el) == "table" then
         if #el == 1 and type(el[1]) == "string" and not rv.tbl:hasProperties(el) then el.type = "link" end -- a single string is always a reference
         if not (rv.tbl:isSingleTypeTable(el, "number") and not rv.tbl:hasProperties(el)) then
            if (rv.tbl:isSingleTypeTable(el, "string") and not rv.tbl:hasProperties(el)) then el.type = "key" end
            local currentClass ---@type MacroDefinition|false
            local tableType = rv.tbl:identifyTableType(el) -- figuring out what sort of macro to initialize
            if tableType == "group" then
               currentClass = rv.importer:classImport((el.loop or el.l) and "SequenceMacro" or "GroupMacro")
            elseif tableType == "macro" then
               currentClass = rv.tbl:getMacroClass(el)
            end
            if not currentClass then return end -- initializing the macro with our default settings
            local elInstance = currentClass:new(el, rv.tbl:intersectSimple(sequenceDelays, self.defaults), self.sourceDevice, rv.utils.deepCopy(self.stack), self.scope)
            self:async(fetchSubMacro, (i - offset), elInstance)
         elseif rv.tbl:isSingleTypeTable(el, "number") and not rv.tbl:hasProperties(el) then -- dealing with a delay modifier table
            offset = offset + 1
            processed = processed + 1
            for n = 1, #defOrder do
               local def = defOrder[n]
               if el[n] and el[n] >= 0 then
                  sequenceDelays[def] = el[n] -- overriding one or both delay values
               elseif el[n] == -1 then -- resetting a value to the macro's default delays, if applicable
                  sequenceDelays[def] = self.options[def] or rv.profile.config[def]
               elseif el[n] == -2 then -- resetting a value to the profile's default value
                  sequenceDelays[def] = rv.profile.config[def]
               end
            end
            delayTable[i] = rv.tbl:intersectSimple(sequenceDelays, {})
         end
      elseif type(el) == "number" then
         tempCommand[i - offset] = {el, sequenceDelays.actionVariance}
         processed = processed + 1
      elseif type(el) == "string" then -- strings need to be converted in order to remember their delays
         processed = processed + 1
         tempCommand[i - offset] = stringOutputGenerator(el, sequenceDelays)
      else -- skipping unidentifiable tables
         offset = offset + 1
         processed = processed + 1
      end
      if processed == #self.rawCommand then finalIteration() end
   end
end

---Main function for executing macro sequences
---@param event Event
---@async
function SequenceMacro:execute(event)
   local sequence = self.command[1]
   local delays = self.command[2] ---@type OptionsCollection
   local press = self:keyPress(event)
   local virtualEvent = self:virtualize(event, 1)
   local looper = self.options.loop or 1
   local loopNum = #sequence * looper
   local loopStart = (self.state.seqPosition) or 1
   if looper == 0 then -- if there's no loop, we just return
      return -1
   elseif looper < 0 then
      loopNum = huge -- anything smaller then 0 loops forever
   end
   for g = loopStart, loopNum do -- repeating as many loops as we need
      local i = g - (#sequence * (ceil((g / #sequence - 1) + 1) - 1))
      local obj = sequence[i]
      if i ~= 1 then rv.threading:wait(delays[i].actionDelay, delays[i].actionVariance) end
      if type(obj) == "table" then -- any tables that are left are sub-macros
         rv.profile.macroIndex[obj[1]]:run(virtualEvent)
      elseif type(obj) == "function" then
         obj(press) -- executing the pause or keypress functions
      end
   end
end

---@param depth integer
function SequenceMacro:stringify(depth)
   depth = depth or 1
   local indent = self:indent(depth)
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
