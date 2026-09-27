local rv = ... ---@type Revenant
local remove, super = table.remove, rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _KeyBufferOptions:MacroOptions
---@field scope? "family"|"global"|"key" #should the key be buffered for a specific type of device or globally?
---@field exclusive? boolean #Should this buffer override any previously set buffer?
--[[=============================================================]] --
---Assign macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress. <br>[Documentation](https://github.com/Thertzlor/Revenant/wiki/Key-Buffer-Macro)
---@alias AssignKeyBuffer  MacroInitDefinition<"keybuffer","kb",_KeyBufferOptions,string[]>
--[[=============================================================]] --
---A macro that will cause on or more keys to be pressed right before the next "normally" triggered keypress.
---@class (exact) KeyBufferMacro:MacroDefinition
---@field command string
---@field keys KeyObject[]
---@field options _KeyBufferOptions
local KeyBufferMacro = super:new()
KeyBufferMacro.type = "keybuffer"
KeyBufferMacro.singleTrigger = true
KeyBufferMacro.lintProperties = { --
   scope = {type = "string", values = {"family", "global", "key"}},
   exclusive = {type = "boolean"}
}
KeyBufferMacro.lintCommand = {type = "string"}
---@protected
---@async
function KeyBufferMacro:parseInstructions()
   self.command = self.rawCommand[1]
   self.keys = rv.keys:keyParser(self.command, true)
   rv:put(self.keys)
   self.options.scope = self.options.scope or "global"
   self:finishInit()
end

---Adding a string buffer, the actual logic is done in the string module.
---@param event Event
function KeyBufferMacro:execute(event)
   if self.command == "" and not self.options.exclusive then return end
   rv.keys:addKeyBuffer(rv.utils.deepCopy(self.keys), event.family, event.keyNum, self.options.scope, self.options.exclusive, self.pID)
end

---@async
---Removing existing buffer entries. This one is fucking ugly because maybe we merged modifier into the last key and we need to remove them.
---Or maybe modifiers were merged into our last key and we need to re-add those to the last remaining key.
---@param event Event #the event that originally triggered the timeout
function KeyBufferMacro:onTimeout(event)
   local bufferKeys = rv.utils.deepCopy(self.keys)
   local scope = self.options.scope
   local selector = (scope == "key" and ("_b" .. event.keyNum) or scope == "family" and event.family) or "global"
   local bufferState = rv.states.scriptStates.activeKeyBuffers[selector]
   local state = rv.profile.deviceState
   local fam = event.family
   local bufferTarget ---@type table
   if scope == "family" then
      bufferTarget = state[fam].keyBuffers
   elseif scope == "global" then
      bufferTarget = rv.profile.globalState.bufferContent
   else
      bufferTarget = state[fam].keyBuffers[selector]
   end
   if not bufferTarget then return end
   local lastKey = bufferTarget[bufferState[#bufferState][2] + #bufferKeys]
   local origLastKey = bufferKeys[#bufferKeys]
   local reMod = {} ---@type string[]
   if lastKey and not rv.tbl:sameContent(lastKey, origLastKey) then -- something put modifiers into our key...
      local modifiedMods = rv.tbl:ensureTable(lastKey.modifier) ---@type string[]
      if (not origLastKey.modifier) or #origLastKey.modifier == 0 then
         reMod = modifiedMods
      else
         local myMods = rv.tbl:ensureTable(origLastKey.modifier) ---@type string[]
         for i = 1, #modifiedMods do
            local testMod = modifiedMods[i]
            if not rv.tbl:find(myMods, testMod) then reMod[#reMod + 1] = testMod end
         end
      end
   end
   for i = #bufferState, 1, -1 do
      local item = bufferState[i]
      if item[1] == self.pID then
         for n = #bufferKeys, 0, -1 do
            if n == 0 then -- this is the key in which we might have inserted modifiers that need removed
               local modKey = bufferKeys[1]
               if rv.keys:IsKeyModifier(bufferKeys[1]) then
                  bufferTarget[item[2]] = rv.keys:removeModifier(bufferTarget[item[2]], modKey.key ~= "" and modKey.key --[[@as string]] or modKey.modifier)
               end
            else
               remove(bufferTarget, item[2] + n)
            end
         end
         for m = i + 1, #bufferState do
            local toShift = bufferState[m]
            toShift[2] = toShift[2] - #bufferKeys
         end
         remove(bufferState, i)
         if bufferTarget[item[2]] then
            bufferTarget[item[2]] = rv.keys:addModifiers(bufferTarget[item[2]], reMod)
         end
      end
   end
end

---@param depth? integer
function KeyBufferMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "Input buffer \"" .. self.command .. "\"" end

return KeyBufferMacro