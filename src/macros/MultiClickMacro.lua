local rv = ... ---@type Revenant
local type, concat, super = type, table.concat, rv.importer:classImport("MacroDefinition")
---@class _MultiClickOptions:MacroOptions
---@field timer? integer #Number of milliseconds during which subsequent clicks count as multi-clicks
---@field timeMode? "relative"|"absolute" #`"absolute"` requires all clicks to happen within the `timer` value, `"relative"` resets the timer after each click.
---@field triggerMode? "normal"|"stack" #`"normal"` triggers only the macro of the latest multiClick, `"stack"`´activates all previous ones as well.
--[[=============================================================]] --
---@class MultiClickState:MacroStatContainer
---@field multiClick integer #The current number of registered clicks
--[[=============================================================]] --
---Assign a macro for triggering different activities depending how many times a button has been pressed within a short timespan.
---@alias AssignMultiClick MacroInitDefinition<"multiclick","t",_MultiClickOptions,(MacroGeneric|string|integer)[]>
--[[=============================================================]] --
---A macro for triggering different activities depending how many times a button has been pressed within a short timespan.
---@class (exact) MultiClickMacro:MacroDefinition
---@field options _MultiClickOptions
---@field waiting boolean
---@field timerId string
---@field state MultiClickState
---@field keyData l<KeyObject>[]
local MultiClickMacro = super:new()
MultiClickMacro.type = "multiclick"
MultiClickMacro.lintProperties = { --
   timer = {type = "number", range = {0}},
   triggerMode = {type = "string", values = {"normal", "stack"}},
   timeMode = {type = "string", values = {"relative", "absolute"}}
}

---@protected
---@async
function MultiClickMacro:parseInstructions()
   self.keyData = {}
   self.options.timer = self.options.timer or rv.profile.config.multiClickTime
   self.options.timeMode = self.options.timeMode or "relative" -- relative is the default because it's more intuitive.
   local processed = 0
   local offset = 0
   local command = {} ---@type [string][]
   ---@async
   local function finalIteration()
      if self.init then return end
      self.command = command
      self.timerId = self.pID .. "_timer"
      self.terminus = self.options.triggerMode == "stack" -- if we stack macros we have to document all of them.
      self:finishInit()
   end

   ---@async
   ---@param tNum integer
   ---@param class MacroDefinition
   local function fetcher(tNum, class)
      local initId = class:awaitOwnId()
      if initId then self.subMacros[#self.subMacros + 1] = initId end
      command[tNum] = {initId}
      processed = processed + 1 -- we call finalIteration once all sub-macros have been created.
      if processed == #self.rawCommand then finalIteration() end
   end

   for i = 1, #self.rawCommand do
      local cmd = self.rawCommand[i]
      local commandType = type(cmd)
      if commandType == "table" and (not rv.tbl:hasProperties(cmd)) and #cmd == 1 and type(cmd[1]) == "string" then cmd.type = "link" end
      if commandType == "table" then -- for other tables we need to figure out the type of macro.
         local elClass ---@type MacroDefinition|false
         if rv.tbl:isSingleTypeTable(cmd, "string") then cmd.type = "key" end -- default key macro as fallback
         local tableType = rv.tbl:identifyTableType(cmd)
         if tableType == "group" then
            elClass = rv.importer:classImport("GroupMacro")
         elseif tableType == "macro" then -- other generic macro
            elClass = rv.tbl:getMacroClass(cmd)
         end
         if not elClass then return end
         local elInstance = elClass:new(cmd, nil, self.sourceDevice, rv.utils.deepCopy(self.stack), self.scope)
         self:async(fetcher, (i - offset), elInstance) -- asynchronously parsing the sub-macro
      elseif commandType == "string" then -- normal strings are parsed as sequences
         if commandType == "string" then self.keyData[i - offset] = rv.keys:keyParser(cmd) end
         command[i - offset] = cmd
         processed = processed + 1
      else
         offset = offset + 1
         processed = processed + 1
      end
      if processed == #self.rawCommand then finalIteration() end
   end
end

---@private
---Method that resets the multiClick value after a certain time.
---@param waitTime integer
---@param event Event
---@async
function MultiClickMacro:timer(waitTime, event)
   local cmd = self.command
   local state = self.state
   local stack = self.options.triggerMode == "stack"
   rv.threading:wait(waitTime);
   local click = state.multiClick
   state.multiClick = nil
   if stack then -- see timer events
      for i = 1, click do self:subRun(cmd[i], event, i) end
   else -- executing the final event
      self:subRun(cmd[click], event, click)
   end
   return -1
end

---timing function for multi-click keys
---@param event Event
---@async
function MultiClickMacro:execute(event)
   local options, cmd, fam, num = self.options, self.command, event.family, event.keyNum
   local interval = options.timer
   local state = self.state
   if not state.multiClick then
      state.multiClick = 1 -- First click
      rv.threading:taskRun(self.timerId, fam, num, self.timer, self, interval, self:virtualize(event, 5)) -- Event fires after the interval times out without any further click
   else
      state.multiClick = state.multiClick + 1
      if state.multiClick == #cmd then -- If we're at the last click, we fire the event immediately and cancel the timer
         local click = state.multiClick
         rv.threading:taskAbort(self.timerId)
         if options.triggerMode == "stack" then
            for i = 1, click do self:subRun(cmd[i], event, i) end -- If the mode is set to stack all previous click events are fired as well
         else
            self:subRun(cmd[click], event, click)
         end -- ...If not we just fire the current event.
         state.multiClick = nil
      elseif options.timeMode == "relative" then -- In "relative" mode not all clicks have to within a single interval, rather each click resets the interval
         rv.threading:taskAbort(self.timerId)
         rv.threading:taskRun(self.timerId, fam, num, self.timer, self, interval, self:virtualize(event, 5))
      end
   end
   return -1
end

---generic function for either typing a string or launching a su-macro
---@private
---@param evStr l<string>
---@param event Event
---@param index number
---@async
function MultiClickMacro:subRun(evStr, event, index)
   if type(evStr) == "table" then
      rv.profile.macroIndex[evStr[1]]:run(event)
   else
      rv.keys:typingDelegator(self.keyData[index], self:keyPress(event), self.pID .. "_" .. index)
   end
   return -1
end

---@async
function MultiClickMacro:parseDocs()
   if self.manualDocumentation then
      rv.lcd:parseToTextDisplay(self.manualDocumentation, self.pID)
   else
      for i = 1, #self.command do
         local cmd = self.command[i] ---@type any
         if type(cmd) == "string" then rv.lcd:parseToTextDisplay(cmd, self.pID .. "_" .. i) end
      end
   end
end

---@param depth? integer
function MultiClickMacro:stringify(depth)
   local indent = self:indent(depth)
   local subTable = {} ---@type string[]
   for i = 1, #self.command do
      local cmd = self.command[i]
      subTable[#subTable + 1] = type(cmd) == "string" and ("\"" .. rv.str:unbreak(cmd) .. "\"") or rv.profile.macroIndex[cmd[1]]:export((depth or 0) + 1)
   end
   local content = #subTable == 0 and false or "\n" .. indent .. concat(subTable, ",\n" .. indent)
   return indent .. self.titleExport .. "MultiClick: (" .. (content or "") .. "\n" .. indent .. ")"
end

return MultiClickMacro
