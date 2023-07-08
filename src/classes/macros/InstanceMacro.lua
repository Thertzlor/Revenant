local rv = ... ---@type Revenant
local remove, type, insert, next, abs, pairs, error = table.remove, type, table.insert, next, math.abs, pairs, error
---@alias UpdateMethod  "replace"|"insert"|"delete"|"listreplace"|"listinsert"
--[[=============================================================]] --
---@class _InstanceOptions:MacroOptions
---@field update UpdateDefinition #Definition object for a modification of the instance
---@field newType MacroType #change the macro type of the created instance
---@field noDefaults boolean #don't inherit default options of the profile/scope
--[[=============================================================]] --
---@class UpdateDefinition
---@field source? string #The name of the macro the update data is sourced from
---@field selector table<number, string|number>|string|number #K
---@field s? table<number, string|number> #shorthand for `selector`
---@field method UpdateMethod #The type of update to be performed on the macro
--[[=============================================================]] --
---@class __InstanceShorthands
---@field u UpdateDefinition #shorthand for "update"
--[[=============================================================]] --
---Assign a macro that creates a new independent instance of another macro, optionally modifying its functionality.
---@alias AssignInstance _InstanceOptions | MacroInitDefinition | __InstanceShorthands|mt<"instance","i">
--[[=============================================================]] --
---A macro that creates a new independent instance of another macro, optionally modifying its functionality.
---@class InstanceMacro:MacroDefinition
---@field options _InstanceOptions
---@field command string
---@field originalDefaults MacroInitDefinition
local InstanceMacro = rv.importer:classImport("MacroDefinition"):new()
InstanceMacro.type = "instance"
InstanceMacro.lintProperties = { ---@type OptionsLintPreset
   update = {type = "table", tableKeys = {"number", "string"}},
   newType = {type = "string"},
   noDefaults = {type = "boolean"},
   __all = true
}
InstanceMacro.lintCommand = {type = "string"}
InstanceMacro.shorthands = {u = "update"}
InstanceMacro.terminus = false

local numericMethods = rv.tbl:propsFrom{"insert", "listinsert", "listreplace"}
local updateTypes = {r = "replace", i = "insert", d = "delete", lr = "listreplace", li = "listinsert"};
for _, v in pairs(updateTypes) do updateTypes[v] = v end -- expanding long and short versions of types

---Iterate through a table based on a table selector
---@generic S string|integer
---@param selector table<number,S>
---@param target table<string|number,any>
---@return table<number,any>,S
local function _walkTable(selector, target)
   local current = target
   ---@param dex string|integer
   ---@return integer|string
   local function getIndex(dex) return ((type(dex) ~= "number" or dex > 0) and dex) or #current + dex end

   local key = remove(selector)
   for i = 1, #selector do current = current[getIndex(selector[i])] end
   return current, getIndex(key)
end

---@private
---Duplicating and updating a new instance of a macro
---@param update UpdateDefinition
---@param target MacroInitDefinition
---@async
function InstanceMacro:updateMain(update, target)
   local total = #update
   local processed = 0

   ---@param subject table<string,any>|number
   ---@param selector table<number,string|number>
   ---@param mode UpdateMethod
   local function processContent(mode, selector, subject)
      if type(selector[#selector]) == "string" then
         if numericMethods[mode] then -- making sure the key types and methods match up
            error("update method " .. mode .. " can only be applied to numeric keys. Current target is property key " .. selector[#selector])
         elseif mode == "delete" and subject then
            error("positional deletions are only valid for numeric keys.")
         end
      end
      local tab, key = _walkTable(selector, target) ---@type table<any,any>, integer
      if mode == nil or mode == "replace" then -- replacing a specific key
         tab[key] = subject
      elseif mode == "insert" then -- adding a key to to an object
         insert(tab, key, subject)
      elseif mode == "listinsert" then -- inserting an entry into a list at a specific index
         for i = 1, #subject do insert(tab, key, subject[#subject - i + 1]) end
      elseif mode == "listreplace" then -- replace an entry in a list
         remove(tab, key)
         for i = 1, #subject do insert(tab, key, subject[#subject - i + 1]) end
      elseif mode == "delete" then -- delete an entry from a list or object
         if type(key) == "string" then
            tab[key] = nil
         else
            subject = subject or 0
            remove(tab, key)
            for _ = 1, abs(type(subject) == "number" and subject or 0) do remove(tab, (key - ((subject > 0 and 1) or 0))) end
         end
      end
   end

   ---Advanced selector based update procedure
   ---@async
   ---@param updateInput l<UpdateDefinition>
   local function advancedUpdate(updateInput)
      local method = updateInput.method
      local rawSelector = updateInput.selector and updateInput.selector or updateInput.s
      local selector = type(rawSelector) == "table" and rawSelector or {rawSelector --[[@as string|number]] }
      local subject = updateInput[1]
      local source = updateInput.source -- potentially the name of another macro
      if subject and type(source) == "string" and type(subject) ~= "table" then
         subject = {subject}
      else
         source = nil
      end
      if source then
         local referencedMacro = rv.profile.macroIndex[self:awaitId(source)] -- resolving the selector on the targeted macro
         local tab, dex = _walkTable(subject, referencedMacro.raw) ---@type table<number,any> , number
         subject = tab[dex]
      end
      -- TODO: Can there ever be nested tables in a selector?
      if rv.tbl:isSingleTypeTable(selector, "table") then
         for i = 1, #selector do processContent(method, selector[i] --[[@as table]] , subject) end
      else
         processContent(method, selector, subject)
      end
      processed = processed + 1
      if processed == total then self:finalize(target) end
   end

   self:async(advancedUpdate, update)
end

---@private
---@param newRaw MacroInitDefinition
---@async
function InstanceMacro:finalize(newRaw)
   if self.init then return end
   local subClass = rv.tbl:getMacroClass(newRaw) -- the new macro could be of another type than before
   if not subClass then error("Could not construct Macro for instance") end
   local defaultOptions = self.options
   if not self.options.noDefaults then newRaw = rv.tbl:intersectSimple(newRaw, defaultOptions) end
   local generated = subClass:new(newRaw, rv.profile.assign.scopeDefaults, self.sourceDevice, self.stack, self.scope)
   local subId = generated:awaitOwnId() -- constructing the new Macro and saving it.
   self.subMacros[#self.subMacros + 1] = subId
   self.pID = subId;
   self:finishInit(true)
end

---@protected
---@async
function InstanceMacro:parseInstructions()
   self.command = self.rawCommand[1]
   local target = rv.profile.macroIndex[self:awaitId(self.command)]
   self.originalDefaults = target.defaults
   if not next(self.options) then -- we can skip a lot of logic if the instance isn't modified.
      self:finalize(rv.utils.deepCopy(rv.tbl:intersect({}, target.raw)))
   else
      local myUpdate = self.options.update
      local newType = self.options.newType
      self.options.newType = nil
      self.options.update = nil
      local newRaw = rv.utils.deepCopy(rv.tbl:intersect({}, target.raw)) -- making sure we get a 'clean' table
      if newType then newRaw.type = newType end
      if myUpdate then
         local updates = myUpdate.selector ~= nil and {myUpdate} or myUpdate
         self:updateMain(updates, newRaw) -- updating the instance, option overrides don't require upating.
      else
         self:finalize(newRaw)
      end
   end
end

---After initializing, the Instance macro re-routes the current event to the created instance.
---@param event Event
---@async
function InstanceMacro:execute(event) rv.profile.macroIndex[self.subMacros[1]]:run(event) end

---@param depth integer
function InstanceMacro:export(depth) return self:indent(depth) .. self.titleExport .. "New instance of macro \"" .. self.command .. "\"" end

return InstanceMacro
