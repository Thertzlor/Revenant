local rv = ... ---@type Revenant
local type, concat, assert, super = type, table.concat, assert, rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _KeyOptions:MacroOptions
---@field scope "key"|"family"|"global"  #Should the `wrapKey` macro affect all following key outputs or just ones from the same device or key?
---@field unreverse boolean #Normally buttons are released in reverse order, set this to `true` to release them in the same order they were pressed.
---@field allKeys boolean #all keys ever
--[[=============================================================]] --
---@class __KeyShorthands
---@field ad integer #Shorthand for "actionDelay"
---@field kd integer #Shorthand for "keyDelay"
---@field av integer #Shorthand for "actionVariance"
---@field kv integer #Shorthand for "keyVariance"
--[[=============================================================]] --
---Assign a Macro that handles the default key functions, it can also be called by key name or as simple sequence.
---@alias AssignKey MacroInitDefinition<"key"|"keyup"|"keydown"|"wrapkey","k"|"u"|"d"|"w",_KeyOptions|__KeyShorthands,string[]>
--[[=============================================================]] --
---@class KeyMacro:MacroDefinition #Handles the default key functions, called by key name or as simple sequence.
---@field command l<string>
---@field keys l<KeyObject>
---@field firstModifiers string[]|false
---@field options _KeyOptions
---@field naturalKey boolean
---@field triggerMode 0|1|2|3|4
local KeyMacro = super:new()
KeyMacro.type = "key"
KeyMacro.lintProperties = { ---@type OptionsLintPreset
   scope = {type = "string", values = {"key", "global", "family"}},
   actionDelay = {type = "number", range = {0}},
   unreverse = {type = "boolean"},
   allKeys = {type = "boolean"},
   actionVariance = {type = "number", range = {0}},
   keyVariance = {type = "number", range = {0}},
   keyDelay = {type = "number", range = {0}}
}
KeyMacro.shorthands = {av = "actionVariance", ad = "actionDelay", kv = "keyVariance", kd = "keyDelay"}
KeyMacro.lintCommand = {type = "string"}

---@async
function KeyMacro:parseInstructions()
   local triggerModes = {keydown = 1, keyup = 2, keytoggle = 3, wrapkey = 4}
   self.triggerMode = triggerModes[self.type] or 0
   self.singleTrigger = self.triggerMode ~= 0
   local cmd = self.command
   assert(cmd and (self.options.allKeys or #cmd ~= 0), "Key macro cannot be empty!")
   if #cmd == 1 then cmd = cmd[1] --[[@as string]] end
   self.command = cmd
   if self.options.allKeys then
      self.keys = {}
      for _, p in pairs(rv.keys.keyboardDefinition) do if p.key and not p.modifier then self.keys[#self.keys + 1] = p end end
   elseif type(cmd) == "string" then
      self.keys = rv.keys:parseKeyName(cmd) or rv.keys:keyParser(cmd)
   else
      local keyCollection = {} ---@type KeyObject[]
      self.naturalKey = true
      for i = 1, #cmd do
         local k = assert(rv.keys:parseKeyName(cmd[i]), "In A key macro with multiple entries each entry needs to be a valid key name, not a combined string.")
         keyCollection[#keyCollection + 1] = k
      end
      self.keys = keyCollection
   end
   self.naturalKey = not self.options.allKeys and (self.naturalKey or rv.keys:parseKeyName(cmd --[[@as string]] ) ~= nil)
   if self.keys.key or self.keys.mb then
      self.firstModifiers = self.keys.modifier --[[ @as string[] ]] or false
   else
      self.firstModifiers = self.keys[1].modifier --[[ @as string[] ]] or false
   end
   self:finishInit()
end

---@param depth integer
function KeyMacro:export(depth) return self:indent(depth) .. self.titleExport .. "\"" .. ((self.options.allKeys and "All Keys") or ((type(self.command) == "table" and rv.str:unbreak(concat(self.command --[[@as table]] , "+")) or rv.str:unbreak(self.command --[[@as string]] )))) .. "\"" end

function KeyMacro:unBuffer()
   local k = self.keys[1] or self.keys
   k.modifier = self.firstModifiers
   k.buffer = nil
end

---@param event Event
---@async
function KeyMacro:execute(event)
   local noReverse = self.options.unreverse
   local press = self:keyPress(event)
   local vir = event.virtualType
   local keys = rv.keys:applyStringBuffer(self.keys, press)
   press.forceSleep = true
   if self.triggerMode == 0 then -- normal press, key-down on press, keyup on release
      if event.direction == "down" or (vir and vir ~= 3) then
         if self.naturalKey then
            if vir and vir ~= 3 then -- virtual keys don't wait for keyup
               rv.keys:pressAndRelease(keys, press)
            else
               rv.keys:press(keys, press)
            end
         else -- for when the string is not a key name
            rv.keys:typingDelegator(keys, press, self.pID, true)
            rv.keys:unwrap(press, noReverse)
            self:unBuffer()
         end
      elseif self.naturalKey then -- key-up, no checks for virtual keys because releasing a non-pressed key does nothing.
         rv.keys:release(keys, press, noReverse)
         rv.keys:unwrap(press, noReverse)
         self:unBuffer()
      end
   elseif self.triggerMode == 1 then -- only key-down
      rv.keys:press(keys, press)
      self:unBuffer()
   elseif self.triggerMode == 2 then -- only key-up
      rv.keys:release(keys, press, noReverse)
      rv.keys:unwrap(press, noReverse)
      self:unBuffer()
   elseif self.triggerMode == 3 then -- toggle a key, release on next key-down
      local keyName = self.pID
      local toggled = rv.profile.toggledMacroKeys
      if not toggled[keyName] then
         toggled[keyName] = 1
         rv.keys:press(keys, press)
      else
         rv.keys:release(keys, press, noReverse)
         toggled[keyName] = nil
         rv.keys:unwrap(press, noReverse)
         self:unBuffer()
      end
   elseif self.triggerMode == 4 then -- wrapping a key around the next output, globally or per family
      local fam = event.family
      local num = event.keyNum
      local wrapScope = self.options.scope or "global"
      local state = rv.profile.deviceState
      local wrapperTargets = {key = state[fam]["_b" .. num] --[[@as integer]] , family = state[fam], ["global"] = rv.profile.globalState}
      local wrapTarget = wrapperTargets[wrapScope] -- this can be the state of a device key or the global state
      if not wrapTarget and wrapScope == "key" then
         state[fam].keyBuffers["_b" .. num] = {}
         wrapTarget = state[fam].keyBuffers["_b" .. num]
      end
      if not wrapTarget.wrapperContent then wrapTarget.wrapperContent = {} end
      if keys[1] then -- wrapping multiple keys instead of one
         for i = 1, #keys do wrapTarget.wrapperContent[#wrapTarget.wrapperContent + 1] = keys[i] end
      else
         wrapTarget.wrapperContent[#wrapTarget.wrapperContent + 1] = keys
      end
      rv.keys:press(keys, press)
   end
end

return KeyMacro
