local rv = ... ---@type Revenant
local type, concat, assert, super = type, table.concat, assert, rv.importer:classImport("MacroDefinition")
--[[=============================================================]] --
---@class _KeyOptions:MacroOptions
---@field unreverse? boolean #Normally buttons are released in reverse order, set this to `true` to release them in the same order they were pressed.
---@field allKeys? boolean #all keys ever
--[[=============================================================]] --
---@class _WrapKeyOptions:MacroOptions
---@field scope? "key"|"family"|"global"  #Should the `wrapKey` macro affect all following key outputs or just ones from the same device or key?
---@field direct? boolean  #Should the wrapping key(s) be pressed immediately?
---@field exclusive? boolean  #Should the wrapping key(s) be pressed immediately?
--[[=============================================================]] --
---@class __WrapKeyShorthands:MacroOptions
---@field d? boolean  #Sghorthand for "direct"
--[[=============================================================]] --
---Assign a Macro that handles the default key functions, it can also be called by key name or as a simple sequence. <br>[Documentation](https://github.com/Thertzlor/Revenant/wiki/Key-Macro)
---@alias AssignKey MacroInitDefinition<"key"|"keyup"|"keydown","k"|"u"|"d",_KeyOptions,(string|LogiKeyName)[]>|string|LogiKeyName
--[[=============================================================]] --
---Assign a Macro that defines one or more key inputs that will be pressed and wrapped around the next key output.
---@alias AssignWrapKey MacroInitDefinition<"wrapkey","w",_WrapKeyOptions|__WrapKeyShorthands,(string|LogiKeyName)[]>
--[[=============================================================]] --
---@class (exact) KeyMacro:MacroDefinition #Handles the default key functions, called by key name or as simple sequence.
---@field command l<string>
---@field keys KeyObject|KeyObject[]
---@field firstModifiers string[]|false
---@field options _KeyOptions|_WrapKeyOptions
---@field naturalKey boolean
---@field triggerMode 0|1|2|3|4
local KeyMacro = super:new()
KeyMacro.type = "key"
KeyMacro.lintProperties = { --
   scope = {type = "string", values = {"key", "global", "family"}},
   actionDelay = {type = "number", range = {0}},
   unreverse = {type = "boolean"},
   direct = {type = "boolean"},
   exclusive = {type = "boolean"},
   allKeys = {type = "boolean"},
   actionVariance = {type = "number", range = {0}},
   keyVariance = {type = "number", range = {0}},
   keyDelay = {type = "number", range = {0}}
}
KeyMacro.shorthands = {av = "actionVariance", ad = "actionDelay", kv = "keyVariance", kd = "keyDelay", d = "direct"}
KeyMacro.lintCommand = {type = "string"}

---@async
function KeyMacro:parseInstructions()
   local triggerModes = {keydown = 1, keyup = 2, keytoggle = 3, wrapkey = 4}
   self.triggerMode = triggerModes[self.type] or 0
   local mode = self.triggerMode
   self.singleTrigger = mode ~= 0
   local cmd = self.command
   assert(cmd and (self.options.allKeys or #cmd ~= 0), "Key macro cannot be empty!")
   if #cmd == 1 then cmd = cmd[1] --[[@as string]] end
   self.command = cmd
   if self.options.allKeys then
      self.keys = ({} --[[@as KeyObject[] ]])
      for _, p in pairs(rv.keys.keyboardDefinition) do if p.key and not p.modifier then self.keys[#self.keys + 1] = p --[[@as KeyObject]] end end
   elseif type(cmd) == "string" then
      self.keys = (mode ~= 4 and rv.keys:parseKeyName(cmd)) or rv.keys:keyParser(cmd, mode == 4)
   else
      local keyCollection = {} ---@type l<KeyObject>[]
      self.naturalKey = true
      for i = 1, #cmd do
         local k = assert(rv.keys:parseKeyName(cmd[i]), "In A key macro with multiple entries each entry needs to be a valid key name, not a combined string.")
         keyCollection[#keyCollection + 1] = k
      end
      self.keys = keyCollection
   end
   self.naturalKey = not self.options.allKeys and (self.naturalKey or rv.keys:parseKeyName(cmd --[[@as string]]) ~= nil)
   if self.keys.key or self.keys.mb then
      self.firstModifiers = self.keys.modifier --[[ @as string[] ]] or false
   elseif #self.keys ~= 0 then
      self.firstModifiers = self.keys[1].modifier --[[ @as string[] ]] or false
   end
   if mode == 4 and self.options.exclusive ~= false then self.options.exclusive = true end
   self:finishInit()
end

---@param depth integer
function KeyMacro:stringify(depth) return self:indent(depth) .. self.titleExport .. "\"" .. ((self.options.allKeys and "All Keys") or ((type(self.command) == "table" and rv.str:unbreak(concat(self.command --[[@as table]], "+")) or rv.str:unbreak(self.command --[[@as string]])))) .. "\"" end

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
   local keys = rv.keys:applyKeyBuffer(self.keys, press)
   press.forceSleep = true
   if self.triggerMode == 0 then -- normal press, key-down on press, keyup on release
      if event.direction == "down" or (vir and vir ~= 3) or (self.direction ~= "normal") then
         rv.keys:wrap(press, true, noReverse)
         if self.naturalKey then
            if (vir and vir ~= 3) or self.direction == "up" then -- virtual keys don't wait for keyup
               rv.keys:pressAndRelease(keys, press)
            else
               rv.keys:press(keys, press)
            end
         else -- for when the string is not a key name
            rv.threading.noNextMovementLag = true
            rv.threading.noNextWaitLag = true
            rv.keys:typingDelegator(keys, press, self.pID, true, noReverse)
            rv.keys:wrap(press, false, noReverse)
            self:unBuffer()
         end
      elseif self.naturalKey then -- key-up, no checks for virtual keys because releasing a non-pressed key does nothing.
         rv.keys:release(keys, press, noReverse)
         rv.keys:wrap(press, false, noReverse)
         self:unBuffer()
      end
   elseif self.triggerMode == 1 then -- only key-down
      rv.keys:wrap(press, true, noReverse)
      rv.keys:press(keys, press, true)
      self:unBuffer()
   elseif self.triggerMode == 2 then -- only key-up
      rv.keys:release(keys, press, noReverse)
      rv.keys:clearWrap(press, true)
      rv.keys:wrap(press, false, noReverse)
      self:unBuffer()
   elseif self.triggerMode == 3 then -- toggle a key, release on next key-down
      local keyName = self.pID
      local toggled = rv.profile.toggledMacroKeys
      if not toggled[keyName] then
         toggled[keyName] = 1
         rv.keys:wrap(press, true, noReverse)
         rv.keys:press(keys, press)
      else
         rv.keys:release(keys, press, noReverse)
         toggled[keyName] = nil
         rv.keys:wrap(press, false, noReverse)
         self:unBuffer()
      end
   elseif self.triggerMode == 4 then -- wrapping a key around the next output, globally or per family
      local fam = event.family
      local num = event.keyNum
      local wrapNow = self.options.direct
      local wrapScope = self.options.scope or "global"
      local excl = self.options.exclusive
      local state = rv.profile.deviceState
      local wrapperTargets = {key = state[fam]["_b" .. num] --[[@as integer]], family = state[fam], ["global"] = rv.profile.globalState}
      local wrapTarget = wrapperTargets[wrapScope] -- this can be the state of a device key or the global state
      if not wrapTarget and wrapScope == "key" then
         state[fam].keyBuffers["_b" .. num] = {}
         wrapTarget = state[fam].keyBuffers["_b" .. num]
      end
      if not wrapTarget.wrapperContentUp then wrapTarget.wrapperContentUp = {} end
      if (not wrapNow) and not wrapTarget.wrapperContentDown then wrapTarget.wrapperContentDown = {} end
      local isMulti = keys[1]
      if isMulti then -- wrapping multiple keys instead of one
         for i = 1, #keys do wrapTarget.wrapperContentUp[#wrapTarget.wrapperContentUp + 1] = keys[i] end
      else ---@cast keys KeyObject
         wrapTarget.wrapperContentUp[#wrapTarget.wrapperContentUp + 1] = keys
      end -- note that the exclusive option does not affect the wrapperContentUp array, because direct wrappers can always press multiple keys
      if wrapNow then -- pressing keys directly
         rv.keys:press(keys, press)
      else -- adding wrap keys to our pseudo buffer
         if excl then
            wrapTarget.wrapperContentDown = isMulti and keys or {keys}
         elseif isMulti then -- wrapping multiple keys instead of one
            for i = 1, #keys do wrapTarget.wrapperContentDown[#wrapTarget.wrapperContentDown + 1] = keys[i] end
         else ---@cast keys KeyObject
            wrapTarget.wrapperContentDown[#wrapTarget.wrapperContentDown + 1] = keys
         end
      end
   end
end

return KeyMacro