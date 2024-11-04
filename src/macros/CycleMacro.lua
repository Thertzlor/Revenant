local rv = ... ---@type Revenant
local type, GetRunningTime, abs, huge, concat, super = type, GetRunningTime, math.abs, math.huge, table.concat, rv.importer:classImport("MacroDefinition")

---@class _CycleOptions:MacroOptions
---choose which attributes child cycles will inherit from their parents
---@field inherit?
---|"all" #inherit both status and timing attributes
---| "none" #inherit no attributes
---| "timing" # inherit only timing attributes
---| "status" # inherit only status attributes
---@field limit? integer #How many times the macro will play normally before finishing
---@field range? {[1]:integer,[2]?:integer, [3]?:integer} #start, end and initialize the cycle at specific positions
---@field interval? integer #how many steps the macro should advance after playing
--- Decide what happens after the `limit` value of the cycle is reached.
---@field finish?
---| '"stall"' # Macro repeats the last macro of the cycle
---| '"end"' # Macro does nothing after reaching the limit
---| '"reset"' # Reset back to start of cycle
---| `{}` # A macro assignment that will replace the cycle after the limit is reached.
---@field cancel? integer #defines if and how a cycle can be cancelled.
--[[=============================================================]] --
---@class __CycleShorthands
---@field i? integer #Shorthand for "interval"
---@field cn? integer #Shorthand for "cancel"
--[[=============================================================]] --
---@class CycleState:MacroStatContainer
---@field cyclesComplete integer #the number of times this cycle already ran
--[[=============================================================]] --
---Assign a macro for assigning multiple actions to a macro, cycling through them with each subsequent press/activation
---@alias AssignCycle MacroInitDefinition<"cycle","c",_CycleOptions|__CycleShorthands,(MacroGeneric|string)[]>
--[[=============================================================]] --
---A macro for assigning multiple actions to a macro, cycling through them with each subsequent press/activation
---@class (exact) CycleMacro:MacroDefinition
---@field options _CycleOptions
---@field unstable? boolean
---@field command (string|{[1]:string})[]
---@field keyData l<KeyObject>[]
---@field private state CycleState
local CycleMacro = super:new()
CycleMacro.type = "cycle"
CycleMacro.lintProperties = { --
   limit = {type = "number", range = {0}},
   range = {type = "table", tableKeys = "number", tableTypes = "number", maxLength = 3},
   inherit = {type = "string", values = {"all", "none", "timing", "status"}},
   cancel = {type = "number"},
   interval = {type = "number"},
   finish = {type = {"table", "string"}, values = {"stall", "end", "reset"}}
}
CycleMacro.shorthands = {cn = "cancel", i = "interval"}
CycleMacro.singleTrigger = false
CycleMacro.terminus = false

---@protected
---@async
function CycleMacro:parseInstructions()
   self.keyData = {}
   if self.options.limit == 0 or not self.options.limit then self.options.limit = huge end -- by default we cycle forever.
   self.options.inherit = self.options.inherit or "status"
   self.options.cancel = self.options.cancel or 0
   self.options.finish = self.options.finish or "stall" -- upon finishing the cycle simply does nothing upon activation.
   self.unstable = (self.options.cancel == 1 or self.options.cancel < 0)
   self.command = {}
   local processed = 0
   local offset = 0
   local command = {} ---@type(string|{[1]:string})[]

   ---setting the final table values after identifying all sub macros
   ---@async
   local function finalIteration()
      if self.init then return end
      self.command = command
      self:finishInit()
   end

   ---Fetch the id of a sub-macro
   ---@param tNum integer
   ---@param class MacroDefinition
   ---@async
   local function fetcher(tNum, class)
      local initId = class:awaitOwnId()
      if initId then self.subMacros[#self.subMacros + 1] = initId end
      command[tNum] = {initId}
      processed = processed + 1
      if processed == #self.rawCommand then finalIteration() end
   end

   for i = 1, #self.rawCommand do
      local cmd = self.rawCommand[i] -- iterating through the whole commands, separating macros and actions
      local commandType = type(cmd)
      if commandType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then cmd.type = "link" end
      if commandType == "table" then -- tables are always a kind of macro
         local currentClass ---@type MacroDefinition|false
         if (not rv.tbl:hasProperties(cmd)) and rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end
         local tableType = rv.tbl:identifyTableType(cmd)
         if tableType == "group" then
            currentClass = rv.importer:classImport("GroupMacro") -- multiple macros may be grouped
         elseif tableType == "macro" then
            currentClass = rv.tbl:getMacroClass(cmd)
         end
         if not currentClass then return end
         local currentInstance = currentClass:new(cmd, nil, self.sourceDevice, rv.utils.deepCopy(self.stack), self.scope)
         self:async(fetcher, (i - offset), currentInstance)
      elseif commandType == "number" or commandType == "string" then
         if commandType == "string" then self.keyData[i - offset] = rv.keys:keyParser(cmd) end -- parsing strings to press
         command[i - offset] = cmd
         processed = processed + 1
      else -- ignoring unknwon types
         offset = offset + 1
         processed = processed + 1
      end
      if processed == #self.rawCommand then finalIteration() end
   end
end

---@async
function CycleMacro:parseDocs()
   if self.manualDocumentation then
      rv.lcd:parseToTextDisplay(self.manualDocumentation, self.pID)
   else
      for i = 1, #self.command do
         local cmd = self.command[i] -- generating displayable text for all parts of the command
         if type(cmd) == "string" then rv.lcd:parseToTextDisplay(cmd, self.pID .. "_" .. i) end
      end
   end
end

---@param event Event
---@async
function CycleMacro:execute(event)
   local cycles = self.command ---@type table<number,MacroDefinition|string|number>
   if type(cycles) ~= "table" then return end
   local dir, vir, virtParent = event.direction, event.virtualType, event.originator
   local options = self.options
   local meta = self.state
   local step = 1 -- how many positions were iterated in this execution
   local cycleLimit = options.limit
   local inherit = options.inherit
   local cancelType = options.cancel
   local parent = (virtParent and type(virtParent) ~= "number" and virtParent) or virtParent or 999
   local quitAction = options.finish
   local start = 1
   local interval = options.interval or 1
   local initPosition = start
   local numCycles = #cycles
   if type(options.range) == "table" and rv.tbl:isSingleTypeTable(options.range, "number") then
      local range = options.range or {} -- modifying our start and finish variables according to the `range` option.
      for j = 1, range do if range[j] <= 0 then range[j] = #cycles + range[j] end end
      if range[3] and range[3] < #cycles then initPosition = range[3] --[[@as integer]] end
      if range[1] < #cycles then start = range[1] end
      numCycles = range[2] or numCycles
      if numCycles > #cycles then numCycles = #cycles end
   end
   local directed = vir and 2 or 3
   local press = self:keyPress(event) ---@type KeyPress
   local parentState = rv.profile.macroStates[parent] or {}
   if meta.position == nil or (vir and dir == "down" and (parentState.position == 1) and meta.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then -- first execution of the macro
      meta.position = initPosition
      meta.cyclesComplete = 1
      meta.cycleTimer = GetRunningTime()
   elseif cancelType ~= 0 and cancelType ~= 1 and (dir == "down") and (GetRunningTime() - meta.cycleTimer > abs(cancelType)) then
      -- here, our cycle has been cancelleed, either by a timeout or by the press of another button.
      meta.position = initPosition
      meta.cyclesComplete = 1
   end
   if type(meta.cyclesComplete) == "number" and meta.cyclesComplete > cycleLimit then -- reaching the end of the cycle.
      if quitAction == "end" then
         return -- the `end` option simply aborts execution
      elseif quitAction == "reset" then -- resetting a cycle after ending. This resets to the `init` position, not to `start`.
         meta.position = initPosition
         meta.cyclesComplete = 1
      elseif type(quitAction) == "table" then -- the ending definition may be a reference to another macro to run
         rv.profile.macroIndex[quitAction[1]]:run(self:virtualize(event, directed))
         return
      end
   end
   if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
      meta.cycleTimer = parentState.cycleTimer or GetRunningTime() -- inheriting the cycle timer from the parent macro if applicable.
   else
      meta.cycleTimer = GetRunningTime()
   end -- saving our own cycle timer
   if meta.position ~= 1 or type(cycles[meta.position]) ~= "number" then
      local mac = cycles[meta.position --[[@as integer]] ]
      local macType = type(mac) -- any command is either a string to type or a macro to execute.
      if macType == "table" then
         rv.profile.macroIndex[mac[1]]:run(self:virtualize(event, directed))
      elseif macType == "string" and (meta.matchUp or meta.matchDown) then
         rv.keys:typingDelegator(self.keyData[meta.position], press, (self.pID .. "_" .. meta.position))
      end
   end
   if dir == "up" or (vir and vir ~= 2 and vir ~= 3) then -- here we calculation the real `step` based on `interval`
      while type(cycles[meta.position + ((step + interval) - 1)]) == "number" do step = step + 1 end
      meta.position = meta.position + ((step + interval) - 1)
      if meta.position <= 0 then meta.position = numCycles + meta.position end
      if meta.position > numCycles or meta.position > #cycles then -- nothing advances if we are already finished.
         if not (initPosition > numCycles and meta.position <= #cycles and meta.cyclesComplete == 1) then
            if meta.cyclesComplete < cycleLimit then -- resetting loop back to start
               meta.position = start + meta.position - numCycles - 1
               meta.cyclesComplete = meta.cyclesComplete + 1
            else -- keeping track of the number of cycles
               meta.cyclesComplete = cycleLimit + 1
               meta.position = #cycles
            end
         end
      end
   end
end

---Set the position in the current cycle
---@private
---@param position integer
---@param relative? boolean
function CycleMacro:setCyclePosition(position, relative)
   if type(position) ~= "number" then return end
   local options = self.options
   local cycleState = (options.cancel > 0) and self.state.position or false
   local targetPosition = position
   if relative then targetPosition = (self.state.position or 1) + position end
   self.state.position = rv.tbl:cycleIndex(targetPosition, #self.command, cycleState)
end

---Set the numbers of cycles seen as completed
---@param number integer
---@param relative? boolean
function CycleMacro:setCyclesCompleted(number, relative)
   if type(number) ~= "number" then return end
   local targetNumber = number
   if relative then targetNumber = self.state.cyclesComplete + number end
   self.state.cyclesComplete = targetNumber
end

---interface function for control macro.
---Unlike continuos macros, cycles can be controlled by setting their position
---and the number of completed cycles.
---@param options l<integer>
---@param settingsObject table<string,any>
---@param output boolean|number
---@param duration number
---@param controlId string
---@async
function CycleMacro:control(options, settingsObject, output, duration, controlId)
   local positionOption = options
   local completedOption ---@type integer
   if type(options) == "table" then -- with a table, both position and completion can be set at once.
      positionOption = options[1]
      completedOption = options[2]
   end ---@cast positionOption integer
   if positionOption == 0 then
      self.state.position = nil -- a value of 0 forces a complete re-initialization
   elseif positionOption then
      self:setCyclePosition(positionOption, settingsObject.relative == true)
   end
   if completedOption then self:setCyclesCompleted(completedOption, settingsObject.relative == true) end
   if output then rv.lcd:displayOnLCD(self.pID .. "_" .. controlId, 1, duration) end
end

---@param depth? integer
function CycleMacro:stringify(depth)
   local indent = self:indent(depth)
   local subTable = {} ---@type string[]
   for i = 1, #self.command do
      local cmd = self.command[i] -- fetching sub macro exports
      subTable[#subTable + 1] = type(cmd) == "string" and (indent .. "  \"" .. cmd .. "\"") or rv.profile.macroIndex[cmd[1]]:export((depth or 0) + 1)
   end
   local content = #subTable == 0 and false or "\n" .. concat(subTable, ",\n") -- exporting grouped export.
   return indent .. (self.titleExport or "") .. "Cycle: (" .. (content or "") .. "\n" .. indent .. ")"
end

return CycleMacro
