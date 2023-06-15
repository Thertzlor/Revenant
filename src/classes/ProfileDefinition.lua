local rv = ... ---@type Revenant
local type, setmetatable, pairs, insert, sub, concat, gsub, error, assert, next = type, setmetatable, pairs, table.insert, string.sub, table.concat, string.gsub, error, assert, next
local ConfigDefinition = rv.importer:classImport("ConfigDefinition")

--[[=============================================================]] --
---@alias MacroBase MacroInitDefinition|mt<MacroType,MacroShortType>|table<number,any>
---@alias MacroTable table<string,MacroBase>
---@alias StackMode "append"|"prepend"
---@alias StackMethod "custom"|"shift"|"mode"
---@alias SortMode "standard"|"reverse"|integer[]
---@alias FlexTuple { [1]: table<string,MacroInitDefinition>, [2]: MacroOptions }
--[[=============================================================]] --
---@class ProfileTemplate #Template from which are profile class can be generated
---@field key table<string,string|string[]|MacroBase|MacroBase[]> #Here all keybindings will be defined
---@field documentation table<string,string> #A collection of macro names with a docstring for each
---@field config OptionsCollection #The options for this profile
---@field exit MacroInitDefinition|mt<MacroType> #Macro(s) played when Revenant is shutting down
---@field library MacroTable #A collection of named macros that are not bound directly to keys but may be referenced
---@field scopeDefaults MacroOptions #Option defaults for any macros on this profile
---@field scopeOverride MacroOptions #Option overrides for any macros on this profile
---@field hooks HookCollection #For advanced users only
---@field start MacroInitDefinition|mt<MacroType> #Macro(s) that execute right after the profile loads
--[[=============================================================]] --
---@class HookCollection #A number of functions that can inject code at various points during script execution
---@field onPollHook? fun() #a function executed on each polling event
---@field onEventHook? fun(event?:string,arg?:number,family?:HardwareFamily) #a function that executes at each keyEvent before the macros run
---@field onInitHook? fun() #A function that runs right after Revenant initializes
---@field onEventHookAsync? fun(event?:string,arg?:number,family?:HardwareFamily):number #Same as as onEventHook but async. needs to return a number.
---@field onInitHookAsync? fun():number #Same as as onInitHook but async. needs to return a number.
---@field onRandom? fun():number #called on every randomization call, can be used to inject custom RNG
--[[=============================================================]] --
---@class GlobalState #A global state for all Devices
---@field maxMode integer #The highest mode that can be reached on any device
---@field shift? integer #global g-shift state if activated in options
---@field sKey boolean #Does this profile support G-shift?
---@field wrapperContent KeyObject[]
---@field maxKeys integer #The maximum number of keys supported by this profile
---@field singleDevice? FamilyToken #If there's only a single device registered for the profile its name is saved here
--[[=============================================================]] --
---The main Revenant Profile class
---@class ProfileDefinition:BaseClass
---@field deviceState table<FamilyToken,HardwareDefinition> | {lastMod:number} #Information about all registered devices
---@field config OptionsCollection #The configuration of the current profile
---@field configObject ConfigDefinition #The initialized class based on the configuration
---@field globalState GlobalState #Device independent state of the profile
---@field bindings table<string,string> #collection of key/macro-id pairs
---@field documentation table<string,string> #fully assembled documentation data of the profile
---@field nameMap table<string,string> #collection of name/macro-id pairs
---@field unRename table<string,string> #maps renamed keys to their orignal designations
---@field macroIndex table<string,MacroDefinition> #collection of macro-ids and their corresponding macros
---@field typedIndex table<string,string[]> #collection of macro types with collection of each type's macro ids
---@field awaiting table<string,{waiting:string[],queue:thread[],waitNum?:number}> #table of macro names awaiting their ids
---@field assign ProfileTemplate #Keys and functionality assigned by the user
---@field name string #The name of the profile
---@field toggledMacroKeys table<string,1> #Keeps track of which key macros are currently toggled on
---@field hooks HookCollection #powerful functions for advanced users
---@field assignFlattened MacroTable #key bindings with each key compiled into a single macro group
local ProfileDefinition = rv.baseClass:new()

---@protected
---@param path? string #filepath of the external profile
---@param name string #name of the profile
---@param stack string[] #array of parent profiles
---@param init? boolean #true if this is the final profile to load
function ProfileDefinition:constructor(path, name, stack, init)
   self.stack = stack or {} ---@private
   for i = 1, #self.stack do if self.stack[i] == path then error("Circular inheritance detected: " .. concat(stack, "->") .. "->" .. path) end end
   self.path = path or "origin"
   self.subPath = rv.utils.parentPath(self.path)
   self.init = false ---has the profile finished compiling?
   self.first = init
   self.hooks = {}
   self.autoKeys = true ---Enable autofilling tables in assignment object
   self.awaiting = {}
   self.nameMap = {}
   self.macroIndex = self:indexTable()
   self.config = {}
   self.documentation = {}
   self.toggledMacroKeys = {} ---@private
   self.deviceState = {}
   self.globalState = {shift = 0, modus = 1, mBeforeG = 1, lastModN = 0, lastMod = 0}
   self.unRename = {} ---@private
   self.typedIndex = {__continuous = {}}
   local baseTable = {library = {}, scopeDefaults = {}, documentation = {}} ---@type table
   self.logiSet = rv.paths.profile ---*@private* assignments from LGS
   self.assign = self:autoTable(baseTable)
   if path then self:profileImport() end
   if init then self.logiSet(self.assign) end
   self.autoKeys = false
   self.name = (init and rv.paths.profileName) or name
   self:fetchConfigs()
   if self.config.defaultModeTarget == "self" then self.config.defaultModeTarget = nil end
   self.stack[#self.stack + 1] = self.path
   rv.hardware:defineDevices(self)
   self:compileAssignments()
   local extensions = self.config.extends
   if extensions and extensions ~= "" then -- importing external parent profile data
      if type(extensions) ~= "table" then extensions = {extensions} end
      local parents = {} ---@type ProfileDefinition[]
      for i = 1, #extensions do
         local x = extensions[i] -- inheriting profiles sequentially
         if x ~= "" then parents[#parents + 1] = ProfileDefinition:new((rv.paths.absoluteParentPaths and "" or self.subPath) .. x, x, self.stack, false) end
      end
      for i = 1, #parents do self:extendParent(parents[i]) end
   end
   self:fetchDocs()
   if self.first and self.config.defaultKeys then for k, v in pairs(self.config.defaultKeys) do self.assignFlattened[k] = self.assignFlattened[k] or v end end
end

---Generic import function for config and documentatation files
---@param importType "doc"|"config" #Are we importing a documentation or configuration file?
---@return string? #path to the external file for documentation or configuration
function ProfileDefinition:getDefaultPath(importType)
   if rv.paths.fileLocation == 0 then return nil end
   local term = ({doc = "defaultDocPath", config = "defaultConfigPath"})[importType] ---@type string
   local definitionPath = rv.paths[term]
   local path = "" -- compiling the path to load external files from
   if definitionPath then path = gsub(((rv.paths.absoluteProfilePaths and "") or self.subPath) .. (definitionPath.prefix or "") .. (self.name or "") .. (definitionPath.suffix or ""), "//", "/") end
   return path
end

---@protected
---Error handler which saves profile information with every message
---@param msg string #the error message to save
function ProfileDefinition:errorHandler(msg) rv.states.scriptStates.errors[#rv.states.scriptStates.errors + 1] = "profile " .. self.name .. " failed to initialize:\n  " .. msg end

---Return the name property of a table, if it's a macro
---@param tab table #table that may or may not be a macro
---@return string? #macro name or nil if not found
local function getMacroName(tab)
   if type(tab) ~= "table" then return end
   return tab.name or tab.n
end

---Blocks extension if table has no name
---@param tab table #the table to check
---@return boolean
function ProfileDefinition:blockExtend(tab)
   local macName = getMacroName(tab)
   if not macName then return false end
   local preventions = self.config.preventInheritance or {}
   for i = 1, #preventions do if macName == preventions[i] then return true end end
   return false
end

---recursively add named macros to the library for future reference
---@param tab table<string|any,any> #a table that is or contains references to macros
function ProfileDefinition:libNamed(tab)
   if type(tab) ~= "table" then return end
   local currentName = getMacroName(tab)
   if currentName then
      local lib = self.assign.library -- assign macro to libary if it has a name and isn't already included
      if (not tab.__autoName) and not lib[currentName] then lib[currentName] = tab end
   else
      for _, v in pairs(tab) do if type(v) == "table" then self:libNamed(v) end end -- repeat for child macros
      for i = 1, #tab do
         local v = tab[i]
         if type(v) == "table" then self:libNamed(v) end
      end
   end
   tab.__autoName = nil
end

---Generate a table with "fake" macros that log error messages when run
---@return table #table in which nonexistent keys act as macros
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
function ProfileDefinition:fetchConfigs()
   local defaultPath = self:getDefaultPath("config") -- getting the relative or absolute path depending on settings
   if not self.assign.config then self.assign.config = {} end
   local externalConf = self.assign.config.externalConfigs
   if defaultPath ~= "" then
      local configDef = rv.importer:import(defaultPath, function() end)
      if configDef then
         if externalConf then -- importing parent configs but not initializing them yet
            if type(externalConf) ~= "table" then self.assign.config.externalConfigs = {externalConf} end
            insert(self.assign.config.externalConfigs --[[@as table]] , 1, configDef)
         else
            self.assign.config.externalConfigs = {configDef}
         end
      end
   end -- we leave the actual merging to the ConfigDefinition class
   self.configObject = ConfigDefinition:new(self.assign.config, nil, rv.utils.parentPath(self.path))
   self.config = self.configObject:outputFinalized()
end

---Fetches one or more external documentation file for the current profile
function ProfileDefinition:fetchDocs()
   local doc = self.assign.documentation or {}
   local extConfig = self.config.externalDocs ---The location(s) of doc files
   local definitionPath = self:getDefaultPath("doc")
   local defDoc = definitionPath and rv.utils.lenientLoad(definitionPath) ---@type table<string,string>
   local docTable = defDoc and {defDoc} or {} ---@type string[]
   if extConfig then -- creating a table of paths to load
      if type(extConfig) == "string" then extConfig = {extConfig} end
      for i = 1, #extConfig do docTable[#docTable + 1] = extConfig[i] end
   end
   for i = 1, #docTable do
      local path = docTable[i] -- importing all documentation files in order
      local currentDoc = ((rv.paths.absoluteDocPaths and "") or self.subPath) .. path
      local imported = (type(path) == "table" and path) or rv.utils.lenientLoad(currentDoc)
      if not imported then rv:put("could not import " .. currentDoc) end -- not finding any files in the location
      if imported then doc = rv.tbl:intersectSimple(doc, imported, self.config.preventDocOverride) end -- merging documentations
   end
   self.documentation = doc
end

---Combine two profiles, keeping all named macros in the current profile's library
---@param parent ProfileDefinition #Profile that will be merged into the current one
function ProfileDefinition:extendParent(parent)
   if self.config.mergeScopeDefaults then self.assign.scopeDefaults = rv.tbl:intersectSimple(self.assign.scopeDefaults, parent.assign.scopeDefaults) end
   local parentResolve = rv.tbl:optionResolver(parent)
   local selfResolve = rv.tbl:optionResolver(self)
   local determinants = rv.presets.stringPresets.determinants
   ---check trigger conditions, might fail for more complex ones.
   ---@param m1 table #first macro
   ---@param m2 table #second macro
   ---@return boolean #true if both have the same trigger conditions
   local function sameTrigger(m1, m2)
      for i = 1, #determinants do
         local d = determinants[i]
         if selfResolve(m1, d) ~= parentResolve(m2, d) then return false end
      end
      return true
   end

   for key, bindings in pairs(parent.assignFlattened) do
      local currentButton = self.assignFlattened[key] ---the current "top" macro of a key
      if not self:blockExtend(bindings) then
         local parentGroup = rv.tbl:isActualGroup(bindings)
         bindings.__inherited = true
         if currentButton then
            local buttonAdded = false
            local currentGroup = rv.tbl:isActualGroup(currentButton)
            if not parentGroup then -- if the macro is not a user defined group, it can be taken apart
               for i = 1, #bindings do
                  local parentBinding = bindings[i]
                  bindings.__inherited = true
                  if not self:blockExtend(parentBinding) then
                     if currentGroup then -- if the current top macro is a user defined group it needs to be compared directly
                        if sameTrigger(parentBinding, currentButton) then
                           self:libNamed(parentBinding)
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
                           local currentBinding = currentButton[n] -- for generated groups all containing macros are checked
                           if sameTrigger(parentBinding, currentBinding) then
                              self:libNamed(parentBinding)
                           else
                              currentButton[#currentButton + 1] = parentBinding
                           end -- if no identical trigger conditions are found the binding is appended
                        end
                     end
                  end
               end
            else -- handling the case of the parent macro being a user defined group
               if currentGroup then -- both macros are user defined in this case
                  if sameTrigger(currentButton, bindings) then
                     self:libNamed(bindings)
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
                     local currentBinding = currentButton[i]
                     if sameTrigger(bindings, currentBinding) then
                        self:libNamed(bindings)
                     else
                        currentButton[#currentButton + 1] = bindings
                     end
                  end
               end
            end
         else
            self.assignFlattened[key] = bindings
         end -- If there was no current binding on the key the parent binding is assigned unchanged.
      end
   end -- now only libraries and documentation needs to be merged
   if self.config.mergeDocumentation then self.assign.documentation = rv.tbl:intersectSimple(self.assign.documentation, parent.assign.documentation) end
   for k, v in pairs(parent.assign.library) do if not self.assign.library[k] and not self:blockExtend({n = k}) then self.assign.library[k] = v end end
end

---Import the content of the external profile file.
---@return nil
function ProfileDefinition:profileImport()
   local p = self.path:gsub("%.lua$", ""):gsub("$", ".lua")
   rv:put("importing " .. p) -- importing the file, at this point autoTables are active
   return (assert(rv.utils.lenientLoad(p, true), "Error importing '" .. p .. "': File not found/syntax error"))(self.assign, rv)
end

---@private
---Since buttons can be defined in many ways on a profile template, everything is unified into a simpler structure here.
function ProfileDefinition:compileAssignments()
   ---@type table<string,table<any,any>>
   local collector = self.assign.key --[[@as any]] or {}
   ---Extract button functionality and put it into the main table
   ---@param currentTable MacroTable #The table to simplify
   ---@param presets MacroOptions #Inherited presets
   ---@param subType StackMethod #possible values: "custom", "shift" or "mode"
   ---@return FlexTuple #The table for the next iteration
   local function extractFromTable(currentTable, presets, subType)
      local stackingMode = self.config[subType .. "Stack"] ---@type StackMode
      local mergedResult = {} ---@type table<string,MacroInitDefinition>
      local tablePresets = rv.tbl:intersect({}, presets or {}) ---@type MacroOptions
      for key, value in pairs(currentTable) do
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
      return {mergedResult, tablePresets}
   end

   ---recursively retrieve key definitions from array
   ---@param currentTable table
   ---@param previousTableState? MacroOptions #options inherited from parent groups
   ---@param inPlace? boolean #modify the table itself, instead of returning a new one
   local function resolveHierachy(currentTable, previousTableState, inPlace)
      local groupings = {} ---@type FlexTuple[][]
      previousTableState = previousTableState or {}
      local newTableState = rv.tbl:intersect({}, previousTableState)
      ---unify macro groups from mode groups
      local function setMode()
         local returnValue = {} ---@type FlexTuple[]
         for k = 0, self.globalState.maxMode do
            local j = k -- iterating through all possible modes
            if self.config.modeSort == "reverse" then
               j = self.globalState.maxMode - k
            elseif type(self.config.modeSort) == "table" and #self.config.modeSort == self.globalState.maxMode + 1 then
               j = self.config.modeSort[k + 1]
            end
            if currentTable["mode" .. j] ~= nil then -- checking if there's mode based bindings defined
               local modeTable = currentTable["mode" .. j]
               if inPlace and type(modeTable) ~= "table" then modeTable = {modeTable} end
               newTableState.mode = j -- inheriting mode option
               if inPlace then
                  currentTable[#currentTable + 1] = rv.tbl:intersectSimple(modeTable, newTableState)
               else
                  returnValue[#returnValue + 1] = extractFromTable(modeTable, newTableState, "mode")
               end
               currentTable["mode" .. j] = nil -- we no longer need the original group
            end
            newTableState.mode = previousTableState.mode
         end
         return returnValue
      end

      ---unify macro groups from shift state groups
      local function setShift()
         local returnValue = {} ---@type FlexTuple[]
         if self.globalState.sKey then
            for h = 0, 2 do
               local j = h -- shift values are 0, 1 and 2
               if self.config.shiftSort == "reverse" then
                  j = self.globalState.maxMode - h
               elseif type(self.config.shiftSort) == "table" and #self.config.shiftSort == 3 then
                  j = self.config.shiftSort[h + 1]
               end
               if currentTable["shift" .. j] ~= nil then -- finding shift grouped bindings
                  local shiftTable = currentTable["shift" .. j]
                  if inPlace and type(shiftTable) ~= "table" then shiftTable = {shiftTable} end
                  newTableState.gshift = j -- passing down shift state
                  if inPlace then
                     currentTable[#currentTable + 1] = rv.tbl:intersectSimple(shiftTable, newTableState)
                  else
                     returnValue[#returnValue + 1] = extractFromTable(shiftTable, newTableState, "shift")
                  end
                  currentTable["shift" .. j] = nil -- we no longer need the original group
               end
               newTableState.gshift = previousTableState.gshift
            end
         end
         return returnValue
      end

      ---unify macros from custom groups
      local function setCustom()
         local returnValue = {} ---@type FlexTuple[]
         for r = 1, #self.config.customSort do
            local customGroupName = self.config.customSort[r]
            local customGroupTableState = {}
            local groupTable = currentTable[customGroupName]
            if groupTable and type(groupTable) == "table" then -- If there's a manually defined order, we iterate it here
               for d, m in pairs(groupTable) do if type(d) == "string" and not self.unRename[d] then customGroupTableState[d] = m end end
               if inPlace then
                  currentTable[#currentTable + 1] = rv.tbl:intersectSimple(groupTable, customGroupTableState)
               else
                  returnValue[#returnValue + 1] = extractFromTable(groupTable, rv.tbl:intersect(previousTableState, customGroupTableState, 1), "custom")
               end
               currentTable[customGroupName] = nil
            end
         end -- if any custom tables were not in the sort table they will be picked up now anyway
         for h, p in pairs(currentTable or {}) do -- we don't know the names of custom tables so we iterate all keys
            local privs = {} ---@type MacroOptions
            if sub(h, 1, 2) == "_c" and type(p) == "table" then -- custom groups always begin with "_c"
               for d, m in pairs(p) do if type(d) == "string" and self.unRename[d] == nil then privs[d] = m end end
               returnValue[#returnValue + 1] = extractFromTable(p, rv.tbl:intersect(previousTableState, privs, 1), "custom")
               currentTable[h] = nil -- deleting the original table after processing
            end
         end
         return returnValue
      end

      local commandTable = {custom = setCustom, mode = setMode, shift = setShift} ---@type table<string,fun():FlexTuple>
      for g = 1, #self.config.stackOrder do
         local l = g -- in this part we make sure that the different groups are traversed in the order set in the options
         if self.config.stackAutoReverse and self.config.modeStack == "prepend" and self.config.shiftStack == "prepend" and self.config.customStack == "prepend" then l = #self.config.stackOrder - g + 1 end
         groupings[#groupings + 1] = commandTable[self.config.stackOrder[l]]() -- deciding if we are processing "custom", "mode" or "shift" first
      end

      if (not inPlace) and rv.tbl:hasContent(groupings) then
         for u = 1, #groupings do
            local group = groupings[u]
            for o = 1, #group do
               local x = group[o]
               resolveHierachy(x[1], x[2]) -- interating through everything in the final order
            end
         end
      end
   end

   for _, v in pairs(self.assign.key) do if type(v) == "table" then resolveHierachy(v, nil, true) end end
   resolveHierachy(self.assign.key)
   for k, v in pairs(collector) do
      if type(v) ~= "table" then v = {v} end
      v.name = (v.name or v.n)
      if not v.name and k then -- making sure top level macros can be called by key name
         v.__autoName = true
         v.name = k
      end
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
   for k, v in pairs(self.bindings) do exportTable[#exportTable + 1] = "{" .. k .. "} " .. self.macroIndex[v]:export() end
   if next(self.assign.library) then exportTable[#exportTable + 1] = "\nLibrary Macros:" end -- also exporting unbound library macros
   for k in pairs(self.assign.library) do exportTable[#exportTable + 1] = self.macroIndex[self.nameMap[k]]:export() end
   return concat(exportTable, "\n\n")
end

---Parse the user defined bindings into the finalized executable form.
---@async
function ProfileDefinition:parseBindings()
   local fallbackFamily = rv.str:token(self.config.globalModeFamily) --[[@as FamilyToken]]
   self.bindings = {}
   local processed = (0 + ((self.assign.exit and 1) or 0) + ((self.assign.start and 1) or 0))
   local total = 0 ---Total number of top level macros in the profile, if all are parsed the profile is ready.
   for _ in pairs(self.assignFlattened) do total = total + 1 end
   for _ in pairs(self.assign.library) do total = total + 1 end
   ---@param class MacroDefinition #The macro to be bound
   ---@param key string #The name of the key
   ---@async
   local function getBinding(class, key)
      local classID = class:awaitOwnId()
      if classID and key then self.bindings[key] = classID end
      processed = processed + 1
      if processed == total then -- last macro was parsed
         for k, v in pairs(self.macroIndex) do -- classifying macro by type for better selection options
            if v.type then
               local typeIndex = self.typedIndex[v.type]
               if typeIndex then
                  typeIndex[#typeIndex + 1] = k
               else
                  self.typedIndex[v.type] = {k}
               end
            end -- indexing continuous macros for macro controls
            if v.continuous then self.typedIndex.__continuous[#self.typedIndex.__continuous + 1] = k end
         end
         self.init = true
      end
   end

   for key, bindingTable in pairs(self.assignFlattened) do
      local bindingClass = rv.tbl:getMacroClass(bindingTable)
      if bindingClass then -- here we get the correct macro class for each macro, then compile it
         local fam ---@type FamilyToken
         if self.deviceState[rv.str:token(key) or "null"] then fam = rv.str:token(key) end
         local bindingInstance = bindingClass:new(bindingTable, self.assign.scopeDefaults, self.deviceState[fam])
         self:async(getBinding, bindingInstance, key)
      end
   end

   for name, libraryBinding in pairs(self.assign.library) do
      local bindingClass = rv.tbl:getMacroClass(libraryBinding)
      if bindingClass then
         if type(bindingClass) ~= "table" then bindingClass = {bindingClass} end
         bindingClass.n = nil -- If a library has a name shorthand or claims to have a different name, it is overwritten here
         bindingClass.name = name
         local bindingInstance = bindingClass:new(libraryBinding, self.assign.scopeDefaults, self.deviceState[fallbackFamily])
         self:async(getBinding, bindingInstance)
      end
   end

   for i = 1, 2 do
      local word = i == 1 and "start" or "exit"
      if self.assign[word] then -- handling start and exit bindings
         local class = rv.tbl:getMacroClass(self.assign[word])
         if class then self:async(getBinding, class:new(self.assign[word], self.assign.scopeDefaults, self.deviceState[fallbackFamily]), word) end
      end
   end

   if self.assign.hooks then self.hooks = self.assign.hooks end
end

return ProfileDefinition
