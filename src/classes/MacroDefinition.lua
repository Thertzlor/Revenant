local rv = ... ---@type Revenant
local pairs, concat, yield, type, running, rep, match, sub, error, next, remove = pairs, table.concat, coroutine.yield, type, coroutine.running, string.rep, string.match, string.sub, error, next, table.remove
local delayedTypes = rv.tbl:propsFrom{"group"}
local toMain = {{"type", "key"}, "name", {"direction", "normal"}} ---Default values

---@alias MacroInitDefinition<T,S,O,C> MacroOptions|BaseShorthands|TimingStats | {type:T,t:S}|O|C
---@alias l<T> T|T[] #One or more of `T`
---@alias DirectionValue "up"|"down" #Directions a button can activate
---@alias UnlockValue "shift"|"mode"|"mkeys"|"area"|"condition"
---@alias Condition l<string>|l<integer>|(fun():boolean)[]|_ConditionOptions
--[[=============================================================]] --
---@class KeyPress #contains data about a key action
---@field keyNum integer #numeric value of a key
---@field family FamilyToken #device family of the key
---@field actionDelay integer #The action delay value when the key was pressed
---@field keyDelay integer #the key delay value when the key was pressed
---@field actionVariance integer #the action variance value when the key was pressed
---@field keyVariance integer #the key variance value when the key was pressed
---@field forceSleep boolean #force an actual sleep call instead of an asynchronous wait.
--[[=============================================================]] --
---@class _ConditionOptions #Logical properties of a condition container
---@field logic LogicMode #The evaluation logic used for evaluating multiple conditions
---@field l LogicMode #shorthand for "logic"
--[[=============================================================]] --
---@class MacroOptions
---@field name string #A name which can be used to reference the macro in other contexts
---@field direction? DirectionValue #The direction in which the Macro should play
---@field process? fun(command:any, options:any):any,any #custom function that will run on the command once when the macro is compiled
---@field mode l<string|integer> #Restrict the macro to a specific mouse mode by selecting it by number or name. Accepts a list to enable it in multiple modes.
---@field gshift? 0|1|2 #Set to 1 to only activate macro if G-shift is active, set to 0 to activate only if it isn't. Set to 2 to run in all G-shift states.
---@field condition? Condition|fun():boolean #One or more additional conditions the macro has to clear before running.
---@field documentation? string #A description of the macro to Log and Show during Documentation mode
---@field blocking? boolean #Set to true to block all following macros on the key from executing. Make sure you know the final compiled order of the macros before using this.
---@field unlock? l<UnlockValue> #Make the macro check run conditions both on keydown and keyup. Use with caution.
---@field area? l<RectDefinition> #Restrict the activation of a macro to a specific section of the screen.
---@field mkey? string #Define modifier keys
--[[=============================================================]] --
---@class BaseShorthands
---@field n string #Shorthand for "name"
---@field b boolean #Shorthand for "blocking".
---@field doc string #Shorthand for "documentation".
---@field c string|Condition|fun():boolean #Shorthand for "condition".
---@field g 0|1|2 #Shorthand for "gshift"
---@field m l<string|integer> #Shorthand for "mode"
---@field dir DirectionValue #Shorthand for "direction"
--[[=============================================================]] --
---@class TimingStats #Timing related data
---@field actionDelay integer #Specifies the number of milliseconds to wait between each action
---@field actionVariance integer #Specifies a range of milliseconds used to randomize the action delay
---@field keyDelay integer #Specifies the number of milliseconds between pressing and releasing a key
---@field keyVariance integer #specifies a range of milliseconds used to randomize the key delay
--[[=============================================================]] --
---@class ButtonChecks #contains a "pass" property for each pre-run check
---@field shiftPass boolean #if true, skips the g-shift check
---@field modePass boolean #if true, skips the mode check
---@field mkeyPass boolean #if true, skips the modifier check
---@field areaPass boolean #if true, skips the area check
---@field testPass boolean #if true, skips the conditional check
--[[=============================================================]] --
---@class MacroStatContainer #Data keeping track of the macro's current execution status
---@field conditions ButtonChecks #Keeps track of passed checks
---@field allPassed boolean #true if all checks were previously passed
---@field matchDown boolean #true if the current button direction matches the activation direction of the macro
---@field seqPosition integer #The current position of this macro, if it is a sequence
---@field matchUp boolean #true if the current button direction matches the activation direction of the macro, if it's "up"
---@field cycleTimer integer #number of milliseconds before the position this macro resets, on a cycle macro
---@field position integer #The position of in the execution cycle for cycle macros
--[[=============================================================]] --
---Provides core functionality for all macros.
---@class MacroDefinition:BaseClass
---@field inherited boolean #Did this macro potentially inherit properties from a parent macro?
---@field direction "up"|"normal" #The key directions that will cause this macro to trigger
---@field options MacroOptions | TimingStats
---@field singleTrigger boolean #if true, the macro does not have separate actions on key down and key up
---@field subMacros string[] #Array of macro IDs that are included in this macro
---@field sourceDevice HardwareDefinition #Saves the device this macro originates from
---@field defaults MacroOptions #The default macro options inherited from the profile
---@field stack string[][] #Keeps track of the parent macros executed before this one
---@field continuous boolean #if true the macro will execute over some duration of time, not instantly
---@field assigned boolean #If not true, the macro is never used or referenced
---@field blocked boolean #True if a previous macro is currently blocking this macro's execution
---@field type string #The type of the macro
---@field name string #The display name of this macro
---@field new fun(self:MacroDefinition,macroSummary?:MacroInitDefinition, defaults?:MacroInitDefinition,  device?:HardwareDefinition,stack?:string[],scope?:string):MacroDefinition
---@field private lintProperties OptionsLintPreset #Type definition to veryify the integrity of the macro options
---@field private idThread thread #Thread on which the macro returns its own id
---@field private lintCommand LintEntry #Type definition to verify the integrity of the macro command
---@field protected manualDocumentation string #Overrides the text this macro will output in documentation mode
---@field protected shorthands  table<string,string> #Maps long option names to shorter ones.
---@field protected state MacroStatContainer
---@field protected msgDuration integer #duration in milliseconds of this macro's text display
---@field protected terminus boolean #If true, designates a macro that will not attempt to export subMacros in Documentation mode
---@field protected references string[] #Array of macro IDs referenced by this macro, even if they are not subMacros
---@field protected rawCommand table<any,any>
---@field protected refTypes? l<string>
---@field protected __inherited boolean?
---@field protected command any[]
local MacroDefinition = rv.baseClass:new()
MacroDefinition.lintProperties = {} ---@type OptionsLintPreset
MacroDefinition.shorthands = {} ---@type table<string,string>
---@protected
---@async
---Construct a new MacroDefinition
---@param macroSummary MacroInitDefinition|{_inherit:OptionsCollection, type:string, _scope?:string} #The new definition
---@param defaults MacroOptions #inherited macro options
---@param device HardwareDefinition #The Device this macro is assigned to
---@param stack? string[] #array of parent macros
---@param scope? string #array of parent macros
function MacroDefinition:constructor(macroSummary, defaults, device, stack, scope)
   if not macroSummary then return end
   self.assigned = false
   self.scope = macroSummary._scope or scope or "_" ---@protected profile scope of macro
   self.shorthands = rv.tbl:intersectSimple(self.shorthands, rv.presets.stringPresets.shorthands)
   ---Easier lookup for shorthand properties
   self.shortMap = {} ---@type {[1]:string,[2]:string}[] @protected
   for k, v in pairs(self.shorthands) do self.shortMap[#self.shortMap + 1] = {k, v} end
   self.sourceDevice = device
   self.disabled = false ---A macro may be disabled if something goes wrong during the import or parsing
   self.stack = stack or {} ---@protected
   self.init = false ---@protected Is set to true once the macro is fully parsed
   if self.terminus == nil then self.terminus = true end
   self.singleTrigger = self.singleTrigger or false ---@protected
   self.raw = macroSummary;
   self.subMacros = {} ---@protected
   self.references = {} ---@protected
   self.defaults = defaults or {}
   ---@type any,MacroOptions | {lcd:any}
   self.rawCommand, self.rawOptions = rv.tbl:splitEnumerable(macroSummary) ---@protected
   self.inherited = self.rawOptions.__inherited
   self.rawOptions.__inherited = nil ---@type boolean?
   ---@generic A any
   ---@generic B any
   ---@type fun(command:A, options:B): A,B
   local processFunction = self.rawOptions.process or function(a, b) return a, b end
   self.command, self.options = processFunction(self.rawCommand, self:keyFilter(rv.tbl:intersectSimple(rv.tbl:intersectSimple(self.rawOptions, (macroSummary._inherit or {})), self.defaults)))
   if not rv.profile.assign then rv.tbl:prettyTab(self.raw) end
   if self.type == "group" then
      self.raw.type = nil -- don't need any type info on groups
   else
      for k, v in pairs(rv.profile.assign.scopeOverride or {} --[[@as table<string,any>]] ) do
         self.options[k] = v; ---@type any
      end
   end -- applying overrides
   self:expandOptions()
   self:parseQualifiers()
   for i = 1, #toMain do
      local main, mainTab = toMain[i], (type(toMain[i]) == "table") -- transforming a few options that are named differently on the macro
      local target = (mainTab and main[1] or main)
      local renamedOpts = self.options[target] ---@type any
      if not renamedOpts and mainTab and main[2] then renamedOpts = main[2] end
      self[target] = renamedOpts ---@type any
      self.options[target] = nil ---@type nil
   end
   self.msgDuration = (self.rawOptions.lcd and type(self.rawOptions.lcd) == "number") and self.rawOptions.lcd or rv.profile.config.LCDMessageDuration
   self.titleExport = self:compileTitle() ---compiled title used when exporting contents
   if not delayedTypes[self.type] then self.pID = self:genId() end
   self:async(self.parseInstructions, self) -- asynchronously parsing instructions
   self.manualDocumentation = self.options.documentation or rv.profile.documentation[self.name]
   if (rv.profile.config.enableLinting and not rv.lint:keyOptionsLinter(self.raw, self.type, self.lintProperties, self.shorthands, self.name or self:export(), self.name ~= nil)) or (rv.profile.config.enableLinting and not rv.lint:keyCommandLinter((type(self.command) == "table" and self.command or {self.command}), self.lintCommand, self.type, (self.name or self:export()), self.name ~= nil)) and rv.profile.config.abortOnLintError then self.disabled = true end -- doing linting, and (potentially) aborting if there were any errors
end

---@async
---@protected
---executing this method signifies that the macro has now successfully parsed all data needed to execute.
---@param transient? boolean #a transient macro is not part of a profile's macroIndex
function MacroDefinition:finishInit(transient)
   if self.pID then
      if not self.state then
         if not rv.profile.macroStates[self.pID] then rv.profile.macroStates[self.pID] = {} end
         self.state = rv.profile.macroStates[self.pID]
      end
      if not transient then rv.profile.macroIndex[self.pID] = self end -- adding id to the profile
      if self.name then -- mapping the name to the id
         local realName = self.scope .. ":" .. self.name
         rv.profile.nameMap[realName] = self.pID
         if rv.profile.awaiting[realName] then
            local store = rv.profile.awaiting[realName].queue
            for i = 1, #store do self:async(store[i], self.pID) end -- forwarding the id to all macros that are waiting for it
         end
      end
   end
   if self.idThread then self:async(self.idThread, self:identify()) end -- If a macro awaits its own id, it is resolved here.
   self.init = true
   if self.inherited then self:inheritanceCheck() end
end

---Generate a title for this macro based on hardware stats and name
---@return string #The finished title
---@private
function MacroDefinition:compileTitle()
   local title = ""
   local titleCollection = {} ---@type string[]
   local modeOption = self.options.mode
   if (modeOption and rv.profile.config.defaultMode and modeOption ~= rv.profile.config.defaultMode) then titleCollection[#titleCollection + 1] = "m" .. (type(modeOption) == "table" and concat(modeOption, ", ") or modeOption) end
   if (self.options.gshift and rv.profile.config.defaultShift and self.options.gshift ~= rv.profile.config.defaultShift) then titleCollection[#titleCollection + 1] = "s" .. self.options.gshift end
   if #titleCollection ~= 0 then title = "[" .. concat(titleCollection, ",") .. "] " end
   title = title .. (self.name and self.name .. ": " or "")
   return title
end

---Filter out all properties that might not belong on the command
---@param tab table<string,any> #Table with potentially too many properties
---@return MacroOptions #cleaned up table
---@private
function MacroDefinition:keyFilter(tab)
   local newTab = {} ---@type table<string,any>
   if not tab or not next(tab) or self.lintProperties.__all then return tab or {} end
   local validProperties = rv.tbl:intersectSimple(self.lintProperties, rv.lint.genericMacroProperties)
   for k, v in pairs(tab) do if (validProperties[k] or self.shorthands[k]) then newTab[k] = v end end
   return newTab
end

---Disabling submacros if the macro is set to prevent inheritance
function MacroDefinition:inheritanceCheck()
   local preventions = rv.profile.config.preventInheritance or {}
   for i = 1, #preventions do if self.name == preventions[i] then self.disabled = true end end
   for i = 1, #self.subMacros do
      local subMacro = rv.profile.macroIndex[self.subMacros[i]]
      subMacro.inherited = true
      subMacro:inheritanceCheck()
   end
end

---@protected
---@async
---Asynchronously fetching the ID of another macro whenever it initializes, and inserting it into a table
---@param target string|MacroDefinition #The name or definition of a macro
---@param key string|number #The key or index in the table reserved for this ID
---@param parent table<any,any> #The table to insert the ID into
---@param table? boolean #deposit the found ID as a single string or in an array?
---@param func? function #A function to transform the found ID before inserting
function MacroDefinition:replaceWithReferenceId(target, key, parent, table, func)
   local fetched = self:awaitId(target, true)
   func = func or function(x) return x end ---@type fun(x:string)-> string
   self.references[#self.references + 1] = fetched
   parent[key] = (table and {func(fetched)}) or func(fetched) -- inputting the id after running the processing function
end

---@protected
---Turn a "physical" event into a virtual one for inheritance
---@param event Event #The Event to transform
---@param virtualType integer #The numeric type of "virtuatlity"
---@return Event #A virtual version of the input event
function MacroDefinition:virtualize(event, virtualType)
   local virtEvent = rv.tbl:intersectSimple(event, {})
   virtEvent.virtualType = virtualType
   virtEvent.stack = virtEvent.stack or {} ---@type string[]
   virtEvent.stack[#virtEvent.stack + 1] = self.pID -- making it known which macro spawned the event
   virtEvent.originator = virtEvent.originator or self.pID
   return virtEvent
end

---@protected
---Expands all shorthand properties in the macro options into their longhand equivalents
function MacroDefinition:expandOptions()
   local mappedTerms = self.shortMap;
   for i = 1, #mappedTerms do
      local term = mappedTerms[i]
      local primary = term[2]
      local secondary = term[1]
      if (self.options[primary] ~= nil) or (self.options[secondary] ~= nil) then ---check if at least one is set
         local finalValue ---@type any
         if (self.options[primary] ~= nil) then
            finalValue = self.options[primary] ---@type any
         else
            finalValue = self.options[secondary] ---@type any
         end
         self.options[primary] = finalValue ---@type any
         self.options[secondary] = nil ---@type any #deleting the shorthand property
      end
   end
end

---@protected
---prevent circular dependencies.
---@param name string #The name of the macro
---@param stack? string[] #The stack of previous dependencies
function MacroDefinition:circular(name, stack)
   if not rv.profile.awaiting[name] then return end
   stack = stack or {}
   local waitingMacros = rv.profile.awaiting[name].waiting
   for i = 1, #waitingMacros do
      local waiter = waitingMacros[i]
      for m = 1, #stack do
         if waiter == stack[m] then -- We abort if a macro's name is among it's own dependencies
            stack[#stack + 1] = waiter
            error("circular requirement detected: " .. concat(stack, "->"))
         end
      end
      stack[#stack + 1] = name
      self:circular(waiter, stack)
   end
end

---@protected
---@async
---Waits for a Macro to be fully initialized and then returns its ID.
---@param target string|MacroDefinition #The macro can either be targeted by its name or referenced directly
---@param refOnly? boolean #If we're only waiting for a reference we don't care if the reference is circular.
function MacroDefinition:awaitId(target, refOnly)
   if type(target) ~= "string" then return target:awaitOwnId() end
   local realTarget = self.scope .. ":" .. target
   local realName = self.name and (self.scope .. ":" .. self.name) or false
   if rv.profile.nameMap[realTarget] then
      return rv.profile.nameMap[realTarget]
   else
      rv.profile.totalWaits = rv.profile.totalWaits + 1
      rv.profile.waitList[target] = (rv.profile.waitList[target] or 0) + 1
      if rv.profile.awaiting[realTarget] then -- Checking if the profile is already awaiting this macro
         rv.profile.awaiting[realTarget].queue[#rv.profile.awaiting[realTarget].queue + 1] = running()
      else
         rv.profile.awaiting[realTarget] = {queue = {running()}}
      end -- create a new entry in the  table
      if realName then -- Adding the macro name to the list of macros waiting for this id
         if not rv.profile.awaiting[realTarget].waiting then
            rv.profile.awaiting[realTarget].waiting = {realName}
         else
            rv.profile.awaiting[realTarget].waiting[#rv.profile.awaiting[realTarget].waiting + 1] = realName
         end
         if not refOnly then self:circular(realTarget) end
      end -- Now we wait for the id to be returned via yield
      local yieldedName = yield() ---@type string
      if realName then
         local wList = rv.profile.awaiting[realTarget].waiting
         if wList then
            for i = 1, #wList do
               if wList[i] == realName then
                  remove(wList, i)
                  break
               end
            end
         end
      end
      rv.profile.totalWaits = rv.profile.totalWaits - 1
      rv.profile.waitList[target] = (rv.profile.waitList[target] or 1) - 1
      return yieldedName
   end
end

---@protected
---@generate a new KeyPress event from current data
---@param event Event #The current event
---@return KeyPress #generated KeyPress
function MacroDefinition:keyPress(event)
   return { --
      actionDelay = self.options.actionDelay or rv.profile.config.actionDelay,
      keyDelay = self.options.keyDelay or rv.profile.config.keyDelay,
      actionVariance = self.options.actionVariance or rv.profile.config.actionVariance,
      keyVariance = self.options.keyVariance or rv.profile.config.keyVariance,
      family = event.family,
      keyNum = event.keyNum,
      forceSleep = false
   }
end

---@async
---Returns the macro ID when the macro is fully initialized
---@return string #ID of the macro or replacement macro if bypassed
function MacroDefinition:awaitOwnId()
   if self.init then return self:identify() end -- If parsing has already finished we already have an id
   self.idThread = running()
   return yield() -- if not, we'll have to wait until compilation is over
end

---Block subsequent events in a group from running
---@param event Event #The current key event
---@param linked? boolean #If the macro is linked, it won't block any others
---@protected
function MacroDefinition:blockNext(event, linked)
   if event.virtualType or linked then return end -- linked macros and virtual events do not block
   local block = self.options.blocking
   if block and #self.stack ~= 0 then
      local blockTargets = self.stack -- looking for macros to block
      for i = 1, #blockTargets do
         local mac = (rv.profile.macroIndex[self.stack[i][1]] or {})
         if mac.type == "group" then mac.blocked = true end -- setting the block
      end
   end
end

---Execute the Macro after checking all conditions in its options
---@param event Event #The event triggering this macro
---@async
function MacroDefinition:run(event)
   if self.disabled then return end
   local options = self.options
   if rv.validator:validateConditions(event, options, self.pID, self.singleTrigger) then -- Here all checks take place
      if rv.states.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
      local linked = event.link
      event.link = nil -- resetting the linked status of the current Event
      self:execute(event)
      self:blockNext(event, linked) -- ...but we do need the past linked status to determine blocking capabilities
   end
end

---Execute a macro without checking conditions like modes g-shift, etc, only the actual button activation is needed.
---@param event Event #The event triggering this macro
---@async
function MacroDefinition:runFree(event)
   if self.disabled then return end
   if rv.validator:skipConditions(event, self.pID, self.singleTrigger) then
      if rv.states.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
      local linked = event.link
      event.link = nil
      self:execute(event)
      self:blockNext(event, linked)
   end
end

---@protected
---Handle errors by appending a message into the scriptState, potentially preventing the Framework from initializing
---@param msg string #The error to output
function MacroDefinition:errorHandler(msg)
   local name = self.name ---@type string
   if not name then
      for i = 1, #self.stack do
         local stn = self.stack[i][2]
         if stn then name = "Child Macro of " .. stn end
         break
      end
   else
      name = "Macro " .. name
   end -- tracing the location of the current macro
   if not name then name = "a " .. self.type .. " macro" end
   rv.states.scriptStates.errors[#rv.states.scriptStates.errors + 1] = name .. " failed to initialize:\n  " .. msg
end

---@protected
---@async
---Asynchronously parse and process everything that an be handled during compile time. finishInit needs to be called at the end of this method.
function MacroDefinition:parseInstructions() self:finishInit() end

function MacroDefinition:setAssigned()
   self.assigned = true
   for i = 1, #self.subMacros do rv.profile.macroIndex[self.subMacros[i]]:setAssigned() end
   for i = 1, #self.references do rv.profile.macroIndex[self.references[i]]:setAssigned() end
end

---Rendering the display text to be used in Documentation mode.
---@async
function MacroDefinition:parseDocs() rv.lcd:parseToTextDisplay(self.manualDocumentation or self:export(), self.pID, nil, nil, not self.manualDocumentation) end

---Renders either the default control options or custom control text to a display text instance.
---@param text? string #Is there custom text?
---@param macroId? string #Is this a control Text for a specific macro?
---@async
function MacroDefinition:parseControls(text, macroId)
   if text and macroId then return rv.lcd:parseToTextDisplay(text, self.pID .. "_" .. macroId, 1) end -- handling custom text
   local controlTypes = {{"multiPause", "Pausing"}, {"taskResume", "Resuming"}, {"taskAbort", "Canceling"}} ---@type string[][]
   for i = 1, #controlTypes do
      local con = controlTypes[i] -- generating text for all standard control actions
      rv.lcd:parseToTextDisplay(con[2] .. " macro '" .. self.name .. "'", self.pID .. "_" .. con[1], 1)
   end
end

---@private
---@async
---If the macro references modes or other macros, this will resolve their names during the compilation phase.
function MacroDefinition:parseQualifiers()
   if self.options.mode then
      local modeOption = self.options.mode
      if type(modeOption) ~= "table" then modeOption = {modeOption} end
      for i = 1, #modeOption do
         local modeCondition = modeOption[i] -- Iterating through mode conditions
         if type(modeCondition) == "string" then
            local negate = match(modeCondition, "^-")
            modeCondition = (negate and sub(modeCondition, 2)) or modeCondition
            local realMod = rv.profile.deviceState[self.sourceDevice.token].modeIndex[modeCondition]
            if not realMod then error("mode " .. modeCondition .. " not found on " .. self.sourceDevice.family) end -- Macros running in Modes that don't exist will never trigger
            modeOption[i] = realMod * ((negate and -1) or 1)
         end
      end
      self.options.mode = (#modeOption == 1 and modeOption[1]) or modeOption
   end
   if self.options.condition then -- checking conditions to references to other macros
      ---@async
      local function testReplace(el, index, parent)
         if type(el) ~= "table" then
            if type(el) == "string" then
               local prefix = sub(el, 1, 2)
               if prefix == ":" or prefix == "~" then -- getting the IDs of other macros instead or their name
                  self:async(self.replaceWithReferenceId, self, el, index, parent, function(macName) return prefix .. macName end)
               end
            end
         else
            for i = 1, #el do testReplace(el[i], i, el) end
         end
      end

      testReplace(self.options.condition, "condition", self.options)
   end
end

---Generate a text representation of this macro
---@protected
---@param depth? integer #The indentation depth to start from
function MacroDefinition:indent(depth) return rep("  ", depth or 0) or "" end

---Generate a text representation of this macro
---@param depth? integer #The indentation depth to start from
function MacroDefinition:export(depth) return self:indent(depth) .. self.titleExport .. rv.importer.classMap[self.type or "key"][1] .. " (" .. self.type .. ")" end

---The default control scheme of continuos macros
---@param option string #The control command
---@param _? table<string,any> #Additional settings from the control macro
---@param output? boolean|number #Should this control action be displayed on the LCD display?
---@param duration number #For how long will the message be displayed?
---@async
function MacroDefinition:control(option, _, output, duration, _, _)
   local controls = {pause = "multiPause", cancel = "taskAbort", resume = "taskResume", toggle = (rv.threading:taskStatus(self.pID) == 1 and "multiPause") or "taskResume"}
   local action = controls[option or "cancel"]
   rv.threading[action](rv.threading, self.pID)
   if output then rv.lcd:displayOnLCD(self.pID .. "_" .. action, 1, duration) end
end

---@protected
---Return the macro ID
---@return string #macro ID
function MacroDefinition:identify() return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil end

---Default Macro execution, does nothing by default, overwritten in child macros.
function MacroDefinition:execute(...) end

return MacroDefinition
