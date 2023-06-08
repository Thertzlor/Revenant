local rv = ... ---@type Revenant
local remove, type, insert, next, abs, pairs, error, rep = table.remove, type, table.insert, next, math.abs, pairs, error, string.rep
-- TODO: more annotations
---@alias UpdateMethod  "replace"|"insert"|"delete"|"listreplace"|"listinsert"
--[[=============================================================]] --
---@class _InstanceOptions:MacroOptions
---@field update UpdateDefinition #Definition object for a modification of the instance
---@field newType MacroType #change the macro type of the created instance
---@field noDefaults boolean #don't inherit default options of the profile/scope
--[[=============================================================]] --
---@class UpdateDefinition
---@field source? string #The name of the macro the update data is sourced from
---@field selector table<number, string|number>
---@field s? table<number, string|number> #shorthand for `selector`
---@field method UpdateMethod #The type of update to be performed on the macro
--[[=============================================================]] --
---@class __InstanceShorthands
---@field u UpdateDefinition #shorthand for "update"
--[[=============================================================]] --
---Assign a macro that creates a new independent instance of another macro, optionally modifying its functionality.
---@alias AssignInstance _InstanceOptions | MacroInitDefinition | __InstanceShorthands|mt<"instance"|"i">
--[[=============================================================]] --
---A macro that creates a new independent instance of another macro, optionally modifying its functionality.
---@class InstanceMacro:MacroDefinition
---@field options _InstanceOptions
---@field command string
---@field originalDefaults MacroInitDefinition
local InstanceMacro = rv:classImport("MacroDefinition"):new()

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

---@generic S string|integer
---@param selector table<number,S>
---@param target table
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
function InstanceMacro:updateMain(update, target)
   local total = #update
   local processed = 0

   ---@param subject table<string,any>|number
   ---@param selector table<number,string|number>
   ---@param mode UpdateMethod
   local function processContent(mode, selector, subject)
      if type(selector[#selector]) == "string" then
         if numericMethods[mode] then
            error("update method " .. mode .. " can only be applied to numeric keys. Current target is property key " .. selector[#selector])
         elseif mode == "delete" and subject then
            error("positional deletions are only valid for numeric keys.")
         end
      end
      local tab, key = _walkTable(selector, target)
      if mode == nil or mode == "replace" then
         tab[key] = subject
      elseif mode == "insert" then
         insert(tab, key, subject)
      elseif mode == "listinsert" then
         for i = 1, #subject do insert(tab, key, subject[#subject - i + 1]) end
      elseif mode == "listreplace" then
         remove(tab, key)
         for i = 1, #subject do insert(tab, key, subject[#subject - i + 1]) end
      elseif mode == "delete" then
         if type(key) == "string" then
            tab[key] = nil
         else
            subject = subject or 0
            remove(tab, key)
            for _ = 1, abs(type(subject) == "number" and subject or 0) do remove(tab, (key - ((subject > 0 and 1) or 0))) end
         end
      end
   end

   ---@param updateInput UpdateDefinition
   local function advancedUpdate(updateInput)
      local method = updateInput.method
      local rawSelector = updateInput.selector and updateInput.selector or updateInput.s
      local selector = type(rawSelector) == "table" and rawSelector or {rawSelector} ---@cast selector table
      local subject = updateInput[1]
      local source = updateInput.source
      if subject and type(source) == "string" and type(subject) ~= "table" then
         subject = {subject}
      else
         source = nil
      end
      if source then
         local referencedMacro = rv.profile.macroIndex[self:awaitId(source)]
         local tab, dex = _walkTable(subject, referencedMacro.raw)
         subject = tab[dex]
      end
      if rv.tbl:isSingleTypeTable(selector, "table") then
         for i = 1, #selector do processContent(method, selector[i], subject) end
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
function InstanceMacro:finalize(newRaw)
   if self.init then return end
   local subClass = rv.tbl:getMacroClass(newRaw)
   if not subClass then error("Could not construct Macro for instance") end
   local defaultOptions = self.options
   if not self.options.noDefaults then newRaw = rv.tbl:intersectSimple(newRaw, defaultOptions) end
   local subId = subClass:new(newRaw, rv.profile.assign.scopeDefaults, self.sourceDevice, self.stack):awaitOwnId()
   self.subMacros[#self.subMacros + 1] = subId
   self.pID = subId;
   self:finishInit(true)
end

---@protected
function InstanceMacro:parseInstructions()
   self.command = self.rawCommand[1]
   local target = rv.profile.macroIndex[self:awaitId(self.command)]
   self.originalDefaults = target.defaults
   if not next(self.options) then
      self:finalize(rv.utils.deepCopy(rv.tbl:intersect({}, target.raw)))
   else
      local myUpdate = self.options.update
      local newType = self.options.newType
      self.options.newType = nil
      self.options.update = nil
      local newRaw = rv.utils.deepCopy(rv.tbl:intersect({}, target.raw))
      if newType then newRaw.type = newType end
      if myUpdate then
         local updates = myUpdate.selector ~= nil and {myUpdate} or myUpdate
         self:updateMain(updates, newRaw)
      else
         self:finalize(newRaw)
      end
   end
end

---After initialiting instance macros re-route the current event to the created instance.
---@param event Event
function InstanceMacro:execute(event) rv.profile.macroIndex[self.subMacros[1]]:run(event) end

---@param depth integer
function InstanceMacro:export(depth)
   depth = depth or 0
   local indent = rep("  ", depth) or ""
   return indent .. self.titleExport .. "New instance of macro \"" .. self.command .. "\""
end

return InstanceMacro
