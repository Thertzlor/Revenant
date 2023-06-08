local rv = ... ---@type Revenant
local rep = string.rep
-- TODO: Annotations
--[[=============================================================]] --
---@class _LinkOptions:MacroOptions
---@field override boolean #Overrides activates activation triggers.
--[[=============================================================]] --
---@class __LinkShorthands
---@field o boolean #Shorthand for "override"
--[[=============================================================]] --
---Assign a Macro that references another macro, triggering its execution when activated.
---@alias LinkDefinition _LinkOptions | MacroInitDefinition | __LinkShorthands |mt<"link"|"l">
--[[=============================================================]] --
---A Macro that references another macro, triggering its execution when activated.
---@class LinkMacro:MacroDefinition
---@field command string
---@field options _LinkOptions
local LinkMacro = rv:classImport("MacroDefinition"):new()
LinkMacro.lintProperties = { ---@type OptionsLintPreset
   override = {type = "boolean"}
}
LinkMacro.shorthands = {o = "override"}
LinkMacro.lintCommand = {type = "string"}
LinkMacro.terminus = false

---@protected
function LinkMacro:parseInstructions()
   local rawName = self.rawCommand[1]
   self.command = self:awaitId(rawName, true)
   self:finishInit()
end

---@param event Event
function LinkMacro:execute(event)
   event.link = true
   if self.options.override then
      rv.profile.macroIndex[self.command]:runFree(event)
   else
      rv.profile.macroIndex[self.command]:run(event)
   end
end

---@param depth? integer
function LinkMacro:export(depth)
   depth = depth or 0
   local indent = rep("  ", depth) or ""
   return indent .. self.titleExport .. "Link to macro \"" .. self.rawCommand[1] .. "\""
end

return LinkMacro
