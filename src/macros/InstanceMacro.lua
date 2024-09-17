local rv = ... ---@type Revenant
local remove, type, insert, next, abs, pairs, error = table.remove, type, table.insert, next, math.abs, pairs, error
---Different ways of modifying a table
---@alias UpdateMethod
---|"replace" # Replace the contents of a list at either a specific index or a specific property.
---|"insert" # insert an element into a list at a specified index. Modifies the position of the other entries in the list.
---|"delete" # Delete a property or an entry at a specified index.
---|"listreplace" # replace one or more entries in a list with the content of another list starting at a specified index.
---|"listinsert" # insert the contents of one list into another list at a specified index.
--[[=============================================================]] --
---@class _InstanceOptions:MacroOptions
---@field update? UpdateDefinition #Definition object for a modification of the instance
---@field newType? MacroType #change the macro type of the created instance
---@field noDefaults? boolean #don't inherit default options of the profile/scope
---@field substitute? table<number|string,any> # Every key in the target macro (including child macros) corresponding to a key of this table will be substituted with the key's value.
--[[=============================================================]] --
---@class UpdateDefinition:{[1]:any}
---@field source? string #The name of the macro the update data is sourced from
---@field selector table<number, string|number>|string|number #K
---@field s? table<number, string|number> #shorthand for `selector`
---@field method UpdateMethod #The type of update to be performed on the macro
--[[=============================================================]] --
---@class __InstanceShorthands
---@field u? UpdateDefinition #shorthand for "update"
---@field sub? table<number|string,any> #shorthand for "substitute"
--[[=============================================================]] --
---Assign a macro that creates a new independent instance of another macro, optionally modifying its functionality.
---@alias AssignInstance MacroInitDefinition<"instance","i",_InstanceOptions|__InstanceShorthands>
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
   substitute = {type = "table", tableKeys = {"number", "string"}},
   noDefaults = {type = "boolean"},
   __all = true
}
InstanceMacro.lintCommand = {type = "string"}
InstanceMacro.shorthands = {u = "update", sub = "substitute"}
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
---@param update UpdateDefinition[]
---@param target MacroInitDefinition
---@param substitutions? table<number|string,any>
---@async
function InstanceMacro:updateMain(update, substitutions, target)
   local total = #update
   local processed = 0

   ---@param mode UpdateMethod
   ---@param selector table<number,string|number>
   ---@param content table<string,any>|number
   local function processContent(mode, selector, content)
      if type(selector[#selector]) == "string" then
         if numericMethods[mode] then -- making sure the key types and methods match up
            error("update method " .. mode .. " can only be applied to numeric keys. Current target is property key " .. selector[#selector])
         elseif mode == "delete" and content then
            error("positional deletions are only valid for numeric keys.")
         end
      end
      local tab, key = _walkTable(selector, target) ---@type table<any,any>, integer
      if mode == nil or mode == "replace" then -- replacing a specific key
         tab[key] = content
      elseif mode == "insert" then -- adding a key to to an object
         insert(tab, key, content)
      elseif mode == "listinsert" then -- inserting an entry into a list at a specific index
         for i = 1, #content do insert(tab, key, content[#content - i + 1]) end
      elseif mode == "listreplace" then -- replace an entry in a list
         remove(tab, key)
         for i = 1, #content do tab[key + (i - 1)] = content[i] end
      elseif mode == "delete" then -- delete an entry from a list or object
         if type(key) == "string" then
            tab[key] = nil
         else
            content = content or 0
            remove(tab, key)
            for _ = 1, abs(type(content) == "number" and content or 0) do remove(tab, (key - ((content > 0 and 1) or 0))) end
         end
      end
   end

   ---Advanced selector based update procedure
   ---@async
   ---@param updateInput UpdateDefinition
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
      if processed == total then self:finalize(target, substitutions) end
   end
   for i = 1, total do self:async(advancedUpdate, update[i]) end
end

---@private
---@param newRaw MacroInitDefinition|{n?:string}
---@param subs? table<number|string,any>
---@async
function InstanceMacro:finalize(newRaw, subs)
   if self.init then return end
   if subs then self:substitute(newRaw, subs) end
   local subClass = rv.tbl:getMacroClass(newRaw) -- the new macro could be of another type than before
   if not subClass then error("Could not construct Macro for instance") end
   local defaultOptions = self.options
   if not self.options.noDefaults then newRaw = rv.tbl:intersectSimple(newRaw, defaultOptions) end
   if self.name then newRaw.name = self.name end
   newRaw.n = nil
   local generated = subClass:new(newRaw, rv.utils.deepCopy(rv.profile.assign.scopeDefaults), self.sourceDevice, rv.utils.deepCopy(self.stack), self.scope)
   local subId = generated:awaitOwnId() -- constructing the new Macro and saving it.
   self.subMacros[#self.subMacros + 1] = subId
   self.pID = subId;
   self:finishInit(true)
end

---@private
---@param tab table<any,any>
---@param subtab? table<string|number,any>
function InstanceMacro:substitute(tab, subtab)
   local sub = subtab or self.options.substitute or {}
   for k, v in next, tab do
      if sub[v] ~= nil then
         tab[k] = sub[v]
      elseif type(v) == "table" then
         self:substitute(tab[k], sub)
      end
   end
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
      local substitutes = self.options.substitute
      self.options.newType = nil
      self.options.update = nil
      self.options.substitute = nil
      local newRaw = rv.utils.deepCopy(rv.tbl:intersect({}, target.raw)) -- making sure we get a 'clean' table
      newRaw.template = nil -- the result of an instance table is no longer a template.
      if newType then newRaw.type = newType end
      if myUpdate then
         local updates = (myUpdate.selector ~= nil or myUpdate.s ~= nil) and {myUpdate} or myUpdate
         self:updateMain(updates, substitutes, newRaw) -- updating the instance, option overrides don't require upating.
      else
         self:finalize(newRaw, substitutes)
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
