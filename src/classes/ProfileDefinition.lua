local rv = ... ---@type Revenant
local type, setmetatable, pairs, insert, sub, concat, gsub, error, assert, next, match = type, setmetatable, pairs, table.insert, string.sub, table.concat, string.gsub, error, assert, next, string.match
local ConfigDefinition = rv.importer:classImport("ConfigDefinition")

--[[=============================================================]] --
---@alias AssignmentTable table<string,(__DefaultAssign|MacroGeneric|string|LogiKeyName)|string[]|>|FlexObject<MacroTable|table<string,string>>
---@alias GroupSetter fun(self:ProfileDefinition,currentTable:table<any,any>,newTableState:table<any,any>,previousTableState:MacroOptions,singleKey?:string):FlexTuple
---@alias MacroTable table<string,MacroGeneric>
---@alias MacroLibTable table<string,MacroGeneric>
---@alias MacroGeneric MacroInitDefinition<MacroType,MacroShortType>|MacroGeneric[]|string[]|integer
---@class FlexObject<T>:{mode_0?:T,mode_1?:T,mode_2?:T,mode_3?:T,shift_0?:T,shift_1?:T,shift_2?:T}
---@alias __DefaultAssign
---| `{}` #Assign a macro
---| "" #Single characters are mapped to their keys, and other arbitrary strings are typed out.<br> Below is a list of the standard Logitech key mappings.
---@alias StackMode "append"|"prepend"
---@alias StackMethod "custom"|"shift"|"mode"
---@alias SortMode "standard"|"reverse"|integer[]
---@alias FlexTuple { [1]: table<string,MacroInitDefinition>, [2]: MacroOptions }
--[[=============================================================]] --
---Template from which a profile will be generated
---@class (exact) ProfileTemplate
---@field key AssignmentTable #Here all keybindings will be defined
---@field documentation table<string,string> #A collection of macro names with a docstring for each macro or key name
---@field config OptionsCollection #The options for this profile
---@field exit MacroInitDefinition<MacroType,MacroShortType> #Macro(s) played when Revenant is shutting down
---@field library MacroLibTable #A collection of named macros that are not bound directly to keys but may be referenced
---@field scopeDefaults MacroOptions #Option defaults for any macros on this profile
---@field scopeOverride MacroOptions #Option overrides for any macros on this profile
---@field hooks HookCollection #For advanced users only
---@field start MacroInitDefinition<MacroType,MacroShortType> #Macro(s) that execute right after the profile loads
--[[=============================================================]] --
---@class (exact) HookCollection #A number of functions that can inject code at various points during script execution
---@field onPollHook? fun() #a function executed on each polling event
---@field onEventHook? fun(event?:EventType, arg?:integer, family?:HardwareFamily) #a function that executes at each keyEvent before the macros run
---@field onInitHook? fun() #A function that runs right after Revenant initializes
---@field onEventHookAsync? async fun(event?:EventType, arg?:integer, family?:HardwareFamily):number #Same as as onEventHook but async. needs to return a number.
---@field onInitHookAsync? async fun():number #Same as as onInitHook but async. needs to return a number.
---@field onRandom? fun():number #called on every randomization call, can be used to inject custom RNG
--[[=============================================================]] --
---@class (exact) PathDefinition
---@field path? string
---@field suffix? string
---@field prefix? string
---@field name? string
--[[=============================================================]] --
---@class (exact) GlobalState #A global state for all devices
---@field maxMode? integer #The highest mode that can be reached on any device
---@field shift? integer #global g-shift state if activated in options
---@field sKey? boolean #Does this profile support G-shift?
---@field wrapperContentUp? KeyObject[] # A list of keys that will be released as part of a key wrap.
---@field wrapperContentDown? KeyObject[] # A list of keys that will be pressed as part of a key wrap.
---@field maxKeys? integer #The maximum number of keys supported by this profile
---@field singleDevice? FamilyToken #If there's only a single device registered for the profile its name is saved here
--[[=============================================================]] --
---The main Revenant Profile class
---@class (exact) ProfileDefinition:BaseClass
---@field new fun(self:self,path:string|nil,name:string,stack:string[]|nil,init?:boolean)
---@field deviceState table<FamilyToken,HardwareDefinition> | {lastMod:integer} #Information about all registered devices
---@field config InternalOptions #The configuration of the current profile
---@field globalState GlobalState #Device independent state of the profile
---@field bindings table<string,string> #collection of key/macro-id pairs
---@field documentation table<string,string> #fully assembled documentation data of the profile
---@field nameMap table<string,string> #collection of name/macro-id pairs
---@field unRename table<string,string> #maps renamed keys to their orignal designations
---@field macroIndex table<string,MacroDefinition> #collection of macro-ids and their corresponding macros
---@field macroStates table<string,MacroStatContainer> # Macro Play states
---@field typedIndex table<string,string[]> #collection of macro types with collection of each type's macro ids
---@field awaiting table<string,{waiting:string[],queue:thread[],waitNum?:integer}> #table of macro names awaiting their ids
---@field waitList table<string,number> #table of macro names awaiting their ids as numbers
---@field reserved table<string,true> #table of macro names that are already waiting
---@field unbound table<string,table> #buttons that are no longer bound to any key
---@field totalWaits integer #exact number of macros waiting for id
---@field assign ProfileTemplate #Keys and functionality assigned by the user
---@field name string #The name of the profile
---@field hasUnstableCycles boolean #Does the profile contain any cycle macros cancelable via other input?
---@field hasUnstableThreadMacros boolean #Does the profile contain any sequence macros cancelable via other input?
---@field toggledMacroKeys table<string,1> #Keeps track of which key macros are currently toggled on
---@field hooks HookCollection #powerful functions for advanced users
---@field private configObject ConfigDefinition #The initialized class based on the configuration
---@field private assignFlattened MacroTable #key bindings with each key compiled into a single macro group
---@field private init boolean #key has the profile finished compiling?
---@field private first boolean? #is this the first profile in the stack?
---@field private autoKeys boolean #automatically generate subtables at runtime
---@field private parentDirectory string
---@field private parents ProfileDefinition[]
---@field private path string
---@field stack string[]
---@field private logiSet fun(assign: ProfileTemplate)
local ProfileDefinition = rv.baseClass:new()

---@protected
---@param path? string #filepath of the external profile
---@param name string #name of the profile
---@param stack? string[] #array of parent profiles
---@param init? boolean #true if this is the final profile to load
function ProfileDefinition:constructor(path, name, stack, init)
   self.stack = stack or {}
   for i = 1, #self.stack do if self.stack[i] == path then error("Circular inheritance detected: " .. concat(self.stack, "->") .. "->" .. path) end end
   self.path = path or "origin"
   self.totalWaits = 0
   self.parentDirectory = rv.utils.parentPath(self.path)
   self.init = false ---has the profile finished compiling?
   self.first = init
   self.hooks = {}
   self.hasUnstableCycles = false
   self.hasUnstableThreadMacros = false
   self.autoKeys = true ---Enable autofilling tables in assignment object
   self.awaiting = {}
   self.waitList = {}
   self.reserved = {}
   self.unbound = {}
   self.parents = {}
   self.nameMap = {}
   self.macroIndex = self:indexTable()
   self.macroStates = {}
   self.config = {} --[[@as any]]
   self.documentation = {}
   self.toggledMacroKeys = {} ---@private
   self.deviceState = {}
   self.globalState = {shift = 0, modus = 1, mBeforeG = 1, lastModN = 0, lastMod = 0}
   self.unRename = {} ---@private
   self.typedIndex = {__continuous = {}, __unstableCycles = {}, __unstableThreadMacros = {}}
   local baseTable = {library = {}, scopeDefaults = {}, documentation = {}} ---@cast baseTable ProfileTemplate
   self.logiSet = rv.paths.profile ---@private assignments from LGS
   self.assign = self:autoTable(baseTable)
   if path then self:profileImport() end
   if init then self.logiSet(self.assign) end
   self.autoKeys = false
   -- TODO: we need to check if really no path was found
   if not next(self.assign) then error("could not load file at" .. path .. " or no keys were assigned.") end
   self.name = (init and rv.paths.profileName) or name
   self:fetchConfigs()
   if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
   self.stack[#self.stack + 1] = self.path
   rv.hardware:defineDevices(self)
   self:compileAssignments()
   local extensions = self.config.extends
   if extensions and extensions ~= "" then -- importing external parent profile data
      if type(extensions) ~= "table" then extensions = {extensions} end
      for i = 1, #extensions do
         local x = rv.importer:resolvePath(extensions[i], self.parentDirectory) -- inheriting profiles sequentially
         if x ~= "" then self.parents[#self.parents + 1] = ProfileDefinition:new(x, x, self.stack, false) end
      end
      for i = 1, #self.parents do self:extendParent(self.parents[i]) end
   end
   self:fetchDocs()
   if self.first and self.config.defaultKeys then for k, v in pairs(self.config.defaultKeys) do self.assignFlattened[k] = self.assignFlattened[k] or v end end
end

---Generic import function for config and documentatation files
---@param importType "doc"|"config" #Are we importing a documentation or configuration file?
---@return string? #path to the external file for documentation or configuration
---@private
function ProfileDefinition:getDefaultPath(importType)
   if rv.paths.externalProfile == false then return nil end
   local term = ({doc = "defaultDocPath", config = "defaultConfigPath"})[importType]
   local def = rv.paths[term] --[[@as PathDefinition]]
   local path = "" -- compiling the path to load external files from
   if def then path = ((def.path and def.path ~= "" and def.path) or "") .. (def.prefix or "") .. ((def.name and def.name ~= "" and def.name) or self.name or "") .. (def.suffix or "") end
   return path
end

---@protected
---Error handler which saves profile information with every message
---@param msg string #the error message to save
function ProfileDefinition:errorHandler(msg) rv.states.scriptStates.errors[#rv.states.scriptStates.errors + 1] = "profile " .. self.name .. " failed to initialize:\n  " .. msg end

---Return the name property of a table, if it's a macro
---@param tab any #table that may or may not be a macro
---@return string? #macro name or nil if not found
---@private
local function getMacroName(tab)
   if type(tab) ~= "table" then return end
   return tab.name or tab.n
end

---Blocks extension if table has no name
---@param tab any #the table to check
---@return boolean
---@private
---@overload fun(tab:any):false
---@overload fun(tab:table):boolean
function ProfileDefinition:blockExtend(tab)
   local macName = getMacroName(tab)
   if not macName then return false end
   local preventions = self.config.preventInheritance or {}
   for i = 1, #preventions do if macName == preventions[i] then return true end end
   return false
end

---recursively add named macros to the library for future reference
---@param tab table<string|any,any> #a table that is or contains references to macros
---@private
function ProfileDefinition:storeNamed(tab)
   if type(tab) ~= "table" then return end
   local currentName = getMacroName(tab)
   if currentName then
      local lib = self.unbound -- assign macro to libary if it has a name and isn't already included
      if (not tab.__autoName) and not lib[currentName] then lib[currentName] = tab end
   else
      for _, v in pairs(tab) do if type(v) == "table" then self:storeNamed(v) end end -- repeat for child macros
      for i = 1, #tab do
         local v = tab[i]
         if type(v) == "table" then self:storeNamed(v) end
      end
   end
   tab.__autoName = nil
end

---Generate a table with "fake" macros that log error messages when run
---@return table #table in which nonexistent keys act as macros
---@private
function ProfileDefinition:indexTable()
   return setmetatable({}, {
      __index = function(_, key) -- autofilling for nonexistent keys
         if not self.init then return nil end
         return {run = function() rv:put("macro " .. key .. " does not exist.") end}
      end
   })
end

---Fetch macros by their type(s) or id(s)
---@param group? l<string> #name of a macro group
---@param id? l<string> #one or more macro ids
---@return MacroDefinition[] #The index table containing the IDs of all macros of different types
function ProfileDefinition:macrosByIdOrType(group, id)
   if id then -- dealing with id based requests
      if type(id) ~= "table" then -- it's simple when it's a single id
         local mac = self.macroIndex[id]
         return mac and {mac} or {}
      end
      local res = {} ---@type MacroDefinition[]
      for i = 1, #id do
         local mac = self.macroIndex[id[i]]
         if mac then res[#res + 1] = mac end
      end
      return res
   end
   local res = {} ---@type MacroDefinition[]
   if type(group) ~= "table" then group = {group} end -- dealing with requests for macros of one or multiple types
   for i = 1, #group do
      local macroGroup = self.typedIndex[group[i]] ---@type MacroDefinition[]
      for n = 1, #macroGroup do res[#res + 1] = self.macroIndex[macroGroup[n]] end
   end
   return res
end

---Fetches one or more external config files for the current profile
---@private
function ProfileDefinition:fetchConfigs()
   local defaultPath = self:getDefaultPath("config") -- getting the relative or absolute path depending on settings
   if not self.assign.config then self.assign.config = {} end ---@class OptionsCollection
   local externalConf = self.assign.config.externalConfigs
   if defaultPath ~= "" then
      local configDef = rv.importer:import(defaultPath, function() end, self.parentDirectory)
      if configDef then
         if externalConf then -- importing parent configs but not initializing them yet
            if type(externalConf) ~= "table" then self.assign.config.externalConfigs = {externalConf} end
            insert(self.assign.config.externalConfigs --[[@as table]], 1, configDef)
         else
            self.assign.config.externalConfigs = {configDef}
         end
      end
   end -- we leave the actual merging to the ConfigDefinition class
   self.configObject = ConfigDefinition:new(self.assign.config, nil, rv.utils.parentPath(self.path), self.first)
   self.config = self.configObject:outputFinalized()
end

---Fetches one or more external documentation file for the current profile
---@private
function ProfileDefinition:fetchDocs()
   local doc = self.assign.documentation or {}
   local extConfig = self.config.externalDocs ---The location(s) of doc files
   local definitionPath = self:getDefaultPath("doc")

   local defDoc = definitionPath and rv.importer:lenientLoad(definitionPath, nil, self.parentDirectory) ---@type table<string,string>
   local docTable = defDoc and {defDoc} or {} ---@type string[]
   if extConfig then -- creating a table of paths to load
      if type(extConfig) == "string" then extConfig = {extConfig} end
      for i = 1, #extConfig do docTable[#docTable + 1] = extConfig[i] end
   end
   for i = 1, #docTable do
      local path = docTable[i] -- importing all documentation files in order
      local imported = (type(path) == "table" and path) or rv.importer:lenientLoad(path, false, self.parentDirectory)
      if not imported then rv:put("could not import " .. path) end -- not finding any files in the location
      if imported then doc = rv.tbl:intersectSimple(doc, imported, self.config.preventDocOverride) end -- merging documentations
   end
   self.documentation = doc
end

---Combine two profiles, keeping all named macros in the current profile's library
---@param parent ProfileDefinition #Profile that will be merged into the current one
---@private
function ProfileDefinition:extendParent(parent)
   if self.config.mergeScopeDefaults then self.assign.scopeDefaults = rv.tbl:intersectSimple(self.assign.scopeDefaults, parent.assign.scopeDefaults) end
   local selfResolve = rv.tbl:optionResolver(self)
   local determinants = rv.presets.stringPresets.determinants
   local noMerge = self.config.noMacroExtension
   ---check trigger conditions, might fail for more complex ones.
   ---@param m1 table #first macro
   ---@param m2 table #second macro
   ---@return boolean #true if both have the same trigger conditions
   local function sameTrigger(m1, m2)
      for i = 1, #determinants do
         local d = determinants[i]
         if not rv.tbl:sameContent(selfResolve(m1, d), selfResolve(m2, d), true) then return false end
      end
      return true
   end

   for key, bindings in pairs(parent.assignFlattened) do
      local currentButton = self.assignFlattened[key] ---the current "top" macro of a key
      if not self:blockExtend(bindings) then ---@cast bindings table
         local parentGroup = rv.tbl:isActualGroup(bindings)
         bindings.__inherited = true
         if currentButton then ---@cast currentButton table<any,any>
            local buttonAdded = false
            local currentGroup = rv.tbl:isActualGroup(currentButton)
            if not parentGroup then -- if the macro is not a user defined group, it can be taken apart
               for i = 1, #bindings do
                  local parentBinding = bindings[i] --[[@as table]]
                  bindings.__inherited = true
                  if not self:blockExtend(parentBinding) then
                     if currentGroup then -- if the current top macro is a user defined group it needs to be compared directly
                        if noMerge or sameTrigger(parentBinding, currentButton) then
                           self:storeNamed(parentBinding)
                        else -- adding the parent macro to the key's top group if it has different trigger conditions
                           if not buttonAdded then -- create a group if our key is not yet a group
                              self.assignFlattened[key] = {currentButton}
                              if currentButton.__autoName then
                                 currentButton.__autoName = nil ---@type string?
                                 self.assignFlattened[key].name = currentButton.name -- keeping names for direct reference
                                 currentButton.name = nil -- deleting duplicate names
                              end
                              buttonAdded = true
                           end
                           self.assignFlattened[key][#self.assignFlattened[key] + 1] = parentBinding -- adding bindings
                        end
                     else
                        for n = 1, #currentButton do
                           local currentBinding = currentButton[n] --[[@as table]] -- for generated groups all containing macros are checked
                           if noMerge or sameTrigger(parentBinding, currentBinding) then
                              self:storeNamed(parentBinding)
                           else
                              currentButton[#currentButton + 1] = parentBinding
                           end -- if no identical trigger conditions are found the binding is appended
                        end
                     end
                  end
               end
            else -- handling the case of the parent macro being a user defined group
               if currentGroup then -- both macros are user defined in this case
                  if noMerge or sameTrigger(currentButton, bindings) then
                     self:storeNamed(bindings)
                  else -- basically a direct replacement
                     self.assignFlattened[key] = {currentButton, bindings}
                     if currentButton.__autoName then
                        currentButton.__autoName = nil
                        self.assignFlattened[key] = {currentButton, bindings, name = currentButton.name}
                        currentButton.name = nil
                     end
                  end
               else -- checking members of autogenerated group, see same logic above
                  for i = 1, #currentButton do
                     local currentBinding = currentButton[i] --[[@as table]]
                     if noMerge or sameTrigger(bindings, currentBinding) then
                        self:storeNamed(bindings)
                     else
                        currentButton[#currentButton + 1] = bindings
                     end
                  end
               end
            end
         else
            bindings._scope = parent.path
            self.assignFlattened[key] = bindings
         end -- If there was no current binding on the key the parent binding is assigned unchanged.
      end
   end -- now only libraries and documentation needs to be merged
   if self.config.mergeDocumentation then self.assign.documentation = rv.tbl:intersectSimple(self.assign.documentation, parent.assign.documentation) end
   for k, v in pairs(parent.assign.library) do if not self.assign.library[k] and not self:blockExtend({n = k}) then self.assign.library[k] = v end end
end

---Import the content of the external profile file.
---@return string
function ProfileDefinition:profileImport()
   local p = gsub(gsub(self.path, "%.lua$", ""), "$", ".lua")
   rv:put("importing " .. p, self.parentDirectory); -- importing the file, at this point autoTables are active
   (assert(rv.importer:lenientLoad(p, true, self.parentDirectory), "Error importing '" .. p .. "': File not found/syntax error"))(self.assign, rv)
   return p
end

---@async
function ProfileDefinition:deLag()
   local steps = (self.config.maxLagSamples * 2) + 1
   if steps == 0 then return end
   local function deLag() for _ = 1, steps do rv.threading:wait(30, 0, false, 5) end end ---@async
   rv.threading:taskRun("deLag", nil, 0, deLag)
end

---@param key string
---@param value any
---@param currentTable MacroTable #The table to simplify
---@param tablePresets MacroOptions
---@param mergedResult table<string,MacroInitDefinition>
---@param subType StackMethod #possible values: "custom", "shift" or "mode"
---@param isSingle? boolean
---@private
function ProfileDefinition:extractionHandler(key, value, currentTable, tablePresets, mergedResult, subType, isSingle)
   ---@type table<string,table<any,any>>
   local collector = self.assign.key --[[@as any]] or {}
   local stackingMode = self.config[subType .. "Stack"] ---@type StackMode
   if isSingle then collector[key] = nil end
   if type(key) == "string" and self.unRename[key] ~= nil then -- extracting all properties that map to keys
      if type(value) ~= "table" then value = {value} end -- automatically converting to groups
      local tableType = rv.tbl:identifyTableType(value)
      if collector[key] == nil then
         if tableType == "macro" then
            value._inherit = tablePresets -- the _inherit property keeps track of defaults
         else
            value = rv.tbl:intersectSimple(value, tablePresets)
         end -- options already defined on the macro are kept
         collector[key] = value
      else
         if type(collector[key]) ~= "table" then collector[key] = {collector[key]} end -- value needs to be a group
         if rv.tbl:hasProperties(collector[key]) then collector[key] = {collector[key]} end -- already an inheritance group?
         if tableType == "macro" or (tableType == "group" and rv.tbl:hasProperties(value)) then
            if tableType == "macro" then
               value._inherit = tablePresets -- passing on default values
            else
               value = rv.tbl:intersectSimple(value, tablePresets)
            end
            if stackingMode == "prepend" then
               insert(collector[key], 1, value) -- prepending or appending the new macro
            else
               collector[key][#collector[key] + 1] = value
            end
         elseif tableType ~= "empty" then -- Here we handle groups without properties
            for w = 1, #value do
               if type(value[w]) ~= "table" then value[w] = {value[w]} end
               value[w] = rv.tbl:intersectSimple(value[w], tablePresets) -- handling nested inheritance groups
            end
            for u = 1, #value do
               local h = u
               if stackingMode == "prepend" then -- handling prepend edge case
                  if self.config.stackAutoReverse then h = #value - u + 1 end
                  insert(collector[key], 1, value[h])
               else
                  collector[key][#collector[key] + 1] = value[h]
               end
            end
         end
      end
      currentTable[key] = nil
   elseif type(currentTable[key]) == "table" and key ~= "key" then
      mergedResult[key] = value
      currentTable[key] = nil
   end
end

---Extract button functionality and put it into the main table
---@param currentTable MacroTable #The table to simplify
---@param presets MacroOptions #Inherited presets
---@param subType StackMethod #possible values: "custom", "shift" or "mode"
---@param singleKey? string #name of the single key processed
---@return FlexTuple #The table for the next iteration
---@private
function ProfileDefinition:extractFromTable(currentTable, presets, subType, singleKey)
   local mergedResult = {} ---@type table<string,MacroInitDefinition>
   local tablePresets = rv.tbl:intersect({}, presets or {}) ---@type MacroOptions
   if singleKey then
      self:extractionHandler(singleKey, currentTable, currentTable, tablePresets, mergedResult, subType, true)
   else
      for key, value in pairs(currentTable) do self:extractionHandler(key, value, currentTable, tablePresets, mergedResult, subType) end
   end
   return {mergedResult, tablePresets}
end

---unify macro groups from mode groups
---@private
---@type GroupSetter
function ProfileDefinition:setMode(currentTable, newTableState, previousTableState, singleKey)
   local returnValue = {} ---@type FlexTuple[]
   for k = 0, self.globalState.maxMode do
      local j = k -- iterating through all possible modes
      if self.config.modeSort == "reverse" then
         j = self.globalState.maxMode - k
      elseif type(self.config.modeSort) == "table" and #self.config.modeSort == self.globalState.maxMode + 1 then
         j = self.config.modeSort[k + 1]
      end
      if currentTable["mode_" .. j] ~= nil then -- checking if there's mode based bindings defined
         local modeTable = currentTable["mode_" .. j] ---@type table<string,any>
         newTableState.mode = j -- inheriting mode option
         returnValue[#returnValue + 1] = self:extractFromTable(modeTable, newTableState, "mode", singleKey)
         currentTable["mode_" .. j] = nil -- we no longer need the original group
      end
      newTableState.mode = previousTableState.mode
   end
   return returnValue
end

---unify macro groups from shift state groups
---@private
---@type GroupSetter
function ProfileDefinition:setShift(currentTable, newTableState, previousTableState, singleKey)
   if not self.globalState.sKey then return {} end
   local returnValue = {} ---@type FlexTuple[]
   for h = 0, 2 do
      local j = h -- shift values are 0, 1 and 2
      if self.config.shiftSort == "reverse" then
         j = self.globalState.maxMode - h
      elseif type(self.config.shiftSort) == "table" and #self.config.shiftSort == 3 then
         j = self.config.shiftSort[h + 1]
      end
      if currentTable["shift_" .. j] ~= nil then -- finding shift grouped bindings
         local shiftTable = currentTable["shift_" .. j]
         newTableState.gshift = j -- passing down shift state
         returnValue[#returnValue + 1] = self:extractFromTable(shiftTable, newTableState, "shift", singleKey)
         currentTable["shift_" .. j] = nil -- we no longer need the original group
      end
      newTableState.gshift = previousTableState.gshift
   end
   return returnValue
end

---unify macros from custom groups
---@private
---@type GroupSetter
function ProfileDefinition:setCustom(currentTable, _, previousTableState, singleKey)
   local returnValue = {} ---@type FlexTuple[]
   for r = 1, #self.config.customSort do
      local customGroupName = self.config.customSort[r]
      local customGroupTableState = {} ---@type table<string,any>
      local groupTable = currentTable[customGroupName] ---@type table<string,any>
      if groupTable and type(groupTable) == "table" then -- If there's a manually defined order, we iterate it here
         for d, m in pairs(groupTable) do if type(d) == "string" and not self.unRename[d] then customGroupTableState[d] = m end end
         returnValue[#returnValue + 1] = self:extractFromTable(groupTable, rv.tbl:intersect(previousTableState, customGroupTableState, 1), "custom", singleKey)
         currentTable[customGroupName] = nil
      end
   end -- if any custom tables were not in the sort table they will be picked up now anyway
   ---@type string[]
   local foundNames = {}
   for h, p in pairs(currentTable or {}) do
      if sub(h, 1, 2) == "_c" and type(p) == "table" then foundNames[#foundNames + 1] = h end
   end

   for i = 1, #foundNames do
      local h = foundNames[i]
      local p = currentTable[h]
      local privs = {} ---@type table<string,any>
      if sub(h, 1, 2) == "_c" and type(p) == "table" then -- custom groups always begin with "_c"
         ---@cast p table <string,any>
         for d, m in pairs(p) do if type(d) == "string" and self.unRename[d] == nil then privs[d] = m end end
         returnValue[#returnValue + 1] = self:extractFromTable(p, rv.tbl:intersect(previousTableState, privs, 1), "custom", singleKey)
         currentTable[h] = nil -- deleting the original table after processing
      end
   end
   return returnValue
end

---recursively retrieve key definitions from array
---@param currentTable table<any,any>
---@param previousTableState? MacroOptions #options inherited from parent groups
---@param singleKey? string #options inherited from parent groups
function ProfileDefinition:resolveHierachy(currentTable, previousTableState, singleKey)
   local groupings = {} ---@type FlexTuple[][]
   previousTableState = previousTableState or {}
   local newTableState = rv.tbl:intersect({}, previousTableState)

   local commandTable = {custom = self.setCustom, mode = self.setMode, shift = self.setShift} ---@type table<string,GroupSetter>
   for g = 1, #self.config.stackOrder do
      local l = g -- in this part we make sure that the different groups are traversed in the order set in the options
      if self.config.stackAutoReverse and self.config.modeStack == "prepend" and self.config.shiftStack == "prepend" and self.config.customStack == "prepend" then l = #self.config.stackOrder - g + 1 end
      groupings[#groupings + 1] = commandTable[self.config.stackOrder[l]](self, currentTable, newTableState, previousTableState, singleKey) -- deciding if we are processing "custom", "mode" or "shift" first
   end
   if rv.tbl:hasContent(groupings) then
      for u = 1, #groupings do
         local group = groupings[u]
         for o = 1, #group do
            local x = group[o]
            self:resolveHierachy(x[1], x[2], singleKey) -- interating through everything in the final order
         end
      end
   end
   for key, v in pairs(currentTable) do if type(v) == "table" and self.unRename[key] then self:resolveHierachy(v, {}, key) end end
end

---@private
---Since buttons can be defined in many ways on a profile template, everything is unified into a simpler structure here.
function ProfileDefinition:compileAssignments()
   ---@type table<string,table<any,any>>
   local collector = self.assign.key --[[@as any]] or {}
   self:resolveHierachy(self.assign.key)
   for k, v in pairs(collector) do
      if type(v) ~= "table" then v = {v} end
      v.name = (v.name or v.n)
      if not v.name and k then -- making sure top level macros can be called by key name
         v.__autoName = true
         v.name = k
      end
      v._scope = self.path
      collector[k] = v
   end
   for k, v in pairs(self.unRename) do
      if k ~= v then -- making sure that keys have their original names for easy processing
         local valueContent, valueKey = collector[v], collector[k]
         collector[v] = valueKey
         collector[k] = valueContent
      end
   end
   self.assignFlattened = collector -- all finished
end

---Generate a visual representation of a profile
---@return string #The stringified profile, exporting all contained macros
function ProfileDefinition:buildTree()
   -- since export is recursive we only need to export the main group for each key
   local exportTable = {} ---@type string[]
   for k, v in pairs(self.bindings) do if not self.macroIndex[v].disabled then exportTable[#exportTable + 1] = "{" .. k .. "} " .. self.macroIndex[v]:export() end end
   if next(self.assign.library) then exportTable[#exportTable + 1] = "\nLibrary Macros:" end -- also exporting unbound library macros
   for k in pairs(self.assign.library) do
      local validName ---@type string
      for i = 1, #self.stack do
         validName = self.nameMap[self.stack[i] .. ":" .. k]
         if validName then break end
      end
      if validName then exportTable[#exportTable + 1] = self.macroIndex[validName]:export() end
   end
   return concat(exportTable, "\n\n")
end

---Adds macros to their different groups.
---@private
---@param key string
---@param macro MacroDefinition
function ProfileDefinition:addToIndices(key, macro)
   -- classifying macro by type for better selection options
   local t = macro.type ---@type MacroType
   if t then
      local typeIndex = self.typedIndex[t]
      if typeIndex then
         typeIndex[#typeIndex + 1] = key
      else
         self.typedIndex[t] = {key}
      end
      if (t == "cycle" or macro.continuous) and macro.unstable then
         local term = t == "cycle" and "Cycles" or "ThreadMacros"
         if not self["hasUnstable" .. term] then self["hasUnstable" .. term] = true end ---@type boolean
         self.typedIndex["__unstable" .. term][#self.typedIndex["__unstable" .. term] + 1] = key
      end
   end -- indexing continuous macros for macro controls
   if macro.continuous then self.typedIndex.__continuous[#self.typedIndex.__continuous + 1] = key end
end

---Parse the user defined bindings into the finalized executable form.
---@async
function ProfileDefinition:parseBindings()
   local fallbackFamily = rv.str:token(self.config.globalModeFamily) --[[@as FamilyToken]]
   self.bindings = {}
   local processed = (0 + ((self.assign.exit and 1) or 0) + ((self.assign.start and 1) or 0))
   local total = 0 ---Total number of top level macros in the profile, if all are parsed the profile is ready.
   for _ in pairs(self.assignFlattened) do total = total + 1 end
   for _ in pairs(self.assign.library) do total = (total + 1) --[[@as integer]] end
   ---@param class MacroDefinition #The macro to be bound
   ---@param key? string #The name of the key
   ---@async
   local function getBinding(class, key)
      local classID = class:awaitOwnId()
      if classID and key then self.bindings[key] = classID end
      processed = processed + 1
      if processed == total then -- last macro was parsed
         for k, v in pairs(self.macroIndex) do self:addToIndices(k, v) end
         self.init = true
      end
   end

   ---@param list table<string,table>
   ---@async
   local function iterateUnbound(list)
      for _, b in pairs(list) do
         local class = rv.tbl:getMacroClass(b)
         if class then self:async(getBinding, class:new(b, self.assign.scopeDefaults, self.deviceState[fallbackFamily], nil, b._scope or self.path)) end
      end
   end

   for i = 1, 2 do
      local word = i == 1 and "start" or "exit"
      if self.assign[word] then -- handling start and exit bindings
         local class = rv.tbl:getMacroClass(self.assign[word])
         if class then self:async(getBinding, class:new(self.assign[word], self.assign.scopeDefaults, self.deviceState[fallbackFamily], nil, self.path), word) end
      end
   end

   for name, libraryBinding in pairs(self.assign.library) do ---@cast libraryBinding table<any,table|string>
      local bindingClass = rv.tbl:getMacroClass(libraryBinding)
      if bindingClass then
         if type(libraryBinding) ~= "table" then libraryBinding = {libraryBinding} end
         (libraryBinding).n = nil -- If a library has a name shorthand or claims to have a different name, it is overwritten here
         libraryBinding.name = name
         local bindingInstance = bindingClass:new(libraryBinding, self.assign.scopeDefaults, self.deviceState[fallbackFamily], nil, self.path)
         self:async(getBinding, bindingInstance, nil)
      end
   end

   local bufferedGroups = {} ---@type table<string,GroupMacro>
   for i = 1, #self.stack do
      local s = self.stack[i]
      for key, bindingTable in pairs(self.assignFlattened) do ---@cast bindingTable table<any,any>
         local path = bindingTable._scope or self.path
         if path == s or bufferedGroups[key] then
            local bindingClass = bufferedGroups[key] or rv.tbl:getMacroClass(bindingTable)
            if bindingClass then -- here we get the correct macro class for each macro, then compile it
               local fam ---@type FamilyToken
               if self.deviceState[rv.str:token(key) or "null"] then fam = rv.str:token(key) end
               local isMixed = bufferedGroups[key] ~= nil
               if (not isMixed) and bindingClass.type == "group" then
                  for j = 1, #bindingTable do
                     if bindingTable[j] and bindingTable[j].__inherited then
                        isMixed = true
                        break
                     end
                  end
               end
               if isMixed then
                  local mixGroup = bufferedGroups[key]
                  local entries, options = rv.tbl:splitEnumerable(bindingTable)
                  if not mixGroup then
                     options.allowEmpty = true
                     mixGroup = bindingClass:new(options, self.assign.scopeDefaults, self.deviceState[fam], nil, self.path) --[[@as GroupMacro]]
                     bufferedGroups[key] = mixGroup
                  end
                  for k = 1, #entries do
                     local entry = entries[k]
                     local subPath = (type(entry) == "table" and entry._scope or nil) or path
                     if subPath == s then
                        local subClass = rv.tbl:getMacroClass(entry)
                        if subClass then mixGroup.subMacros[#mixGroup.subMacros + 1] = subClass:new(entry, mixGroup.options, self.deviceState[fam], mixGroup.stack, subPath):awaitOwnId() end
                     end
                  end
                  if #entries == #mixGroup.subMacros then self:async(getBinding, mixGroup, key) end
               else
                  local bindingInstance = bindingClass:new(bindingTable, self.assign.scopeDefaults, self.deviceState[fam], nil, self.path)
                  self:async(getBinding, bindingInstance, key)
               end
            end
         end
      end
   end

   for i = 1, #self.parents do iterateUnbound(self.parents[i].unbound) end
   iterateUnbound(self.unbound)

   if self.assign.hooks then self.hooks = self.assign.hooks end

   local resIteration = 0
   while self.totalWaits ~= 0 do
      resIteration = resIteration + 1
      rv:put("resolving references, iteration " .. resIteration)
      local resolved = 0 ---@type integer
      for k, n in pairs(self.waitList) do
         if n ~= 0 then
            local foundId ---@type string|nil
            for i = 1, #self.stack do
               foundId = self.nameMap[self.stack[i] .. ":" .. k]
               if foundId then break end
            end
            if foundId then
               for i = 1, #self.stack do
                  local waitTable = self.awaiting[self.stack[i] .. ":" .. k]
                  if waitTable then
                     local mac = self.macroIndex[foundId]
                     local sameScope = {} ---@type thread[]
                     local otherScope = {} ---@type thread[]
                     for j = 1, #waitTable.queue do -- we always resolve a waiting macro first for any macro within the same scope.
                        if waitTable.waiting and match(waitTable.waiting[j] or "", "^" .. self.stack[i] .. ":") then
                           sameScope[#sameScope + 1] = waitTable.queue[j]
                        else
                           otherScope[#otherScope + 1] = waitTable.queue[j]
                        end
                     end
                     for m = 1, #sameScope do
                        mac:async(sameScope[m], foundId)
                        resolved = resolved + 1
                     end
                     for m = 1, #otherScope do
                        mac:async(otherScope[m], foundId)
                        resolved = resolved + 1 --[[@as integer]]
                     end
                  end
               end
            end
         end
      end
      if resolved == 0 or resIteration > self.config.maxResolveIterations then break end
   end
   if self.totalWaits ~= 0 then
      rv:put("Warning: some macro ids could not be resolved:")
      for key, value in pairs(self.waitList) do if value ~= 0 then rv:put(" - " .. key) end end
   end
   for _, v in pairs(self.bindings) do self.macroIndex[v]:setAssigned() end
end

return ProfileDefinition