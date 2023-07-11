local rv = ... ---@type Revenant
local super = rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _LinkOptions:MacroOptions
---@field override boolean #Overrides the target's activation triggers.
--[[=============================================================]] --
---@class __LinkShorthands
---@field o boolean #Shorthand for `override`
--[[=============================================================]] --
---Assign a Macro that references another macro, triggering its execution when activated.
---@alias LinkDefinition _LinkOptions|__LinkShorthands | MacroInitDefinition<"link","l">|string[]
--[[=============================================================]] --
---A Macro that references another macro, triggering its execution when activated.
---@class LinkMacro:MacroDefinition
---@field command string
---@field options _LinkOptions
---@field private rawCommand string[]
local LinkMacro = super:new()
LinkMacro.type = "link"
LinkMacro.lintProperties = { ---@type OptionsLintPreset
   override = {type = "boolean"}
}
LinkMacro.shorthands = {o = "override"}
LinkMacro.lintCommand = {type = "string"}
LinkMacro.terminus = false

---@protected
---@async
function LinkMacro:parseInstructions()
   local rawName = self.rawCommand[1]
   self:replaceWithReferenceId(rawName, "command", self) -- getting the ID of the macro we're actually targetting
   self:finishInit()
end

---@param event Event
---@async
function LinkMacro:execute(event)
   event.link = true
   if self.options.override then -- this will skip the target's conditions, but the condition on the link itself still apply.
      rv.profile.macroIndex[self.command]:runFree(event)
   else
      rv.profile.macroIndex[self.command]:run(event)
   end
end

---@param depth? integer
function LinkMacro:export(depth) return self:indent(depth) .. self.titleExport .. "Link to macro \"" .. self.rawCommand[1] .. "\"" end

return LinkMacro
