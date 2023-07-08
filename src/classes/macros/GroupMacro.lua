local rv = ... ---@type Revenant
local concat, super = table.concat, rv.importer:classImport("MacroDefinition")

--[[=============================================================]] --
---@class _GroupOptions:MacroOptions
---@field allowEmpty boolean # do not discard this group even if there are no members
--[[=============================================================]] --
---Assign a macro that groups multiple other macros. Does not need to have a "type" field, a table of multiple other macros automatically results in a group.
---@alias AssignGroup MacroInitDefinition|_GroupOptions|mt<"group","g">
--[[=============================================================]] --
---A macro that groups multiple other macros. Does not need to have a "type" field, a table of multiple other macros automatically results in a group.
---@class GroupMacro:MacroDefinition
---@field private allowEmpty boolean # do not discard this group even if there are no members
---@field options _GroupOptions # do not discard this group even if there are no members
local GroupMacro = super:new()
GroupMacro.type = "group"
GroupMacro.lintProperties = { ---@type OptionsLintPreset
   __all = true
}
---@async
function GroupMacro:parseInstructions()
   local processed = 0
   self.allowEmpty = self.options.allowEmpty
   self.options.allowEmpty = nil

   if #self.command == 0 and self.allowEmpty then
      self.pID = self:genId()
      return self:finishInit()
   end

   ---Instantiating submacros and storing their id.
   ---@param class MacroDefinition
   ---@async
   local function subFetch(class)
      local classID = class:awaitOwnId()
      if classID then self.subMacros[#self.subMacros + 1] = classID end
      processed = processed + 1 -- We initialize ourselves, once we have received all ids
      if processed == #self.command then
         if self:checkNecessity() then self.pID = self:genId() end
         self:finishInit()
      end
   end

   for i = 1, #self.command do
      local entry = self.command[i]
      local macroClass = rv.tbl:getMacroClass(entry)
      if macroClass then -- finding the right macro class for each sub macro
         local subClass = macroClass:new(entry, self.options, self.sourceDevice, self.stack, self.scope)
         self:async(subFetch, subClass)
      end
   end
end

---The export of a group macro simply lists the export output of its members.
---@param depth? integer
function GroupMacro:export(depth)
   local indent = self:indent(depth)
   local subTable = {} ---@type string[] # fetching sub macro exports and storing them for output.
   for i = 1, #self.subMacros do subTable[#subTable + 1] = rv.profile.macroIndex[self.subMacros[i]]:export((depth or 0) + 1) end
   local content = #subTable == 0 and false or "\n" .. concat(subTable, ",\n")
   return indent .. self.titleExport .. " {" .. (content or "") .. "\n" .. indent .. "}"
end

---In some cases we know the group is never referenced.
---@private
function GroupMacro:checkNecessity()
   if #self.subMacros > 1 then
      return true
   elseif #self.subMacros == 0 and self.allowEmpty then
      return true
   elseif #self.subMacros == 0 then
      return false
   end -- ignoring empty groups
   local entry = rv.profile.macroIndex[self.subMacros[1]] -- if there's only one member the group isn't neccesary if doesn't have a name.
   if self.name and entry.name then return self.name ~= entry.name end
   return false
end

---@param event Event
---@async
function GroupMacro:run(event)
   if self.disabled then return end
   ---If we have manually defined documentation, we won't let docMode iterate over sub macros, we just output rigth away.
   if rv.states.scriptStates.docMode and self.manualDocumentation then return rv.lcd:displayOnLCD(self.pID, 1) end
   local linked = event.link
   event.link = nil
   self:execute(event)
   self:blockNext(event, linked)
end

---In "free" execution mode group macros don't do any checks whatsoever.
---@param event Event
---@async
function GroupMacro:runFree(event) self:run(event) end

---Executing a group macro simply iterates over all members
---@param event Event
---@async
function GroupMacro:execute(event)
   local entries = self.subMacros
   for i = 1, #entries do
      if self.blocked then break end
      local entry = entries[i]
      rv.profile.macroIndex[entry]:run(event)
   end
   self.blocked = false
end

return GroupMacro
