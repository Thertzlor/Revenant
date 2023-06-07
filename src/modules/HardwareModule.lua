local rv = ... ---@type Revenant
local type, pairs, assert = type, pairs, assert
local hardwarePresets = rv:import(rv.paths.configPath .. "/HardwareDefinitions.lua") ---@type table<string,HardwareDefinition>
local deviceOptions = {"ButtonCount", "ModeCount", "ShiftKey", "ModeConfig", "BindHardwareModes"}

--[[=============================================================]] --
---@alias ModeDefinition string[]|number[]|{[1]:string|integer,[2]?:(number|string)[]}[]
--[[=============================================================]] --
---@class HardwareDefinition #Describes the properties and state of a physical device
---@field name string #The name of the device
---@field blockedKey? number #number of the key that is currently blocking macro execution, if one exists
---@field shift integer #current g-shift state
---@field modus integer #current mode of the device.
---@field mBeforeG  integer #The mode the device was in before ge g-shift key was pressed. prevents desyncing from the hardware when changing mode while g-shift is active.
---@field dir DirectionValue #direction of the latest event triggered on this device
---@field modeIndex table<string,integer> #Mapping mode name to numbers
---@field lastModN integer #the number of key presses at which the last temporary mode was triggered
---@field nextModN integer #number of key presses after which the current temporary mode will be untriggered
---@field lastMod  integer #The previous mode before the device changed to the current one
---@field token string #first letter of the "family" property
---@field family HardwareFamily #The type of the device
---@field buttonCount integer #the number of programmable buttons on the device
---@field sKey integer? #The number of the standard g-shift key if the device has one
---@field modeCount integer #The maximum number of physical modes available on the device
---@field modeConfig ModeDefinition #The number of modes available for the device
---@field bindHardwareModes  boolean #true if the Revenant modes can be bound the "physical" modes supported by the device
--[[=============================================================]] --
---@class HardwareModule:BaseClass #Managing Hardware definitions
local HardwareModule = rv.baseClass:new()
---@protected
function HardwareModule:constructor()
   for k, v in pairs(hardwarePresets) do -- Filling up the tables with default values
      hardwarePresets[k] = rv.tbl:intersectSimple(v, {modeIndex = {}, lastModN = 0, blockedKey = 0, shift = 0, mBeforeG = 1, lastMod = 0, modus = 1, dir = "down", name = k, token = rv.str:token(v.family), bindHardwareModes = true})
   end
end

---Define devices based on profile information
---@param profile ProfileDefinition #the current profile
function HardwareModule:defineDevices(profile)
   local moreModes = 0
   local moreKeys = 0
   local sKey = false
   local config = profile.config
   local devicePreset = config.devices
   if profile.config.rename then
      for k, v in pairs(profile.config.rename) do -- mapping renamed keys to their original counterparts
         if type(v) == "table" then
            for i = 1, #v do profile.unRename[v[i]] = k end
         else
            profile.unRename[v] = k
         end
      end
   end
   ---Collecting data and forwarding it to the profile and global stats
   ---@param device HardwareDefinition
   local function compileDeviceStats(device)
      if device.sKey then sKey = true end
      if config.defaultModeTarget == "join" then device.modeConfig = config.globalModes end -- overwriting modes with global definitions
      for m = 1, device.buttonCount do profile.unRename[device.token .. m] = profile.unRename[device.token .. m] or device.token .. m end
      device.modeConfig = device.modeConfig or {} -- making sure that there's at least a table even if there are no modes
      if next(device.modeConfig) and #device.modeConfig ~= device.modeCount then device.modeCount = #device.modeConfig end -- table size overwrites count property.
      for h = 1, device.modeCount do -- Parsing mode information into more easily indexed format
         if type(device.modeConfig[h]) ~= "table" then device.modeConfig[h] = (device.modeConfig[h] and {device.modeConfig[h]}) or {} end
         local modName = device.modeConfig[h][1] or h --[[@as string|integer|table]]
         if type(modName ~= "table") then modName = {modName} end
         for m = 1, #modName do device.modeIndex[modName[m]] = h end ---@cast modName string|integer
         device.modeConfig[h][1] = modName[#modName]
      end
      if device.modeCount > moreModes then moreModes = device.modeCount end -- updating variables for maximum mode number
      moreKeys = moreKeys + device.buttonCount
   end

   if devicePreset then
      if type(devicePreset) ~= "table" then devicePreset = {devicePreset} end -- making sure we have a supporteed device
      for i = 1, #devicePreset do
         local dev = assert(hardwarePresets[devicePreset[i]], "No definition found for Device \"" .. devicePreset[i] .. "\"")
         if i == 1 and i == #devicePreset then profile.globalState.singleDevice = dev.token end
         local fam = dev.family
         for n = 1, #deviceOptions do
            local opt = deviceOptions[n]
            if config[fam .. opt] ~= nil then dev[rv.str:firstLower(opt)] = config[fam .. opt] end -- overwriting device presets with manually defined options
         end
         compileDeviceStats(dev)
         profile.deviceState[dev.token] = dev -- indexing device
      end
   end
   for g = 1, #rv.stringPresets.families do -- creating generic devices for all device families
      local fam = rv.stringPresets.families[g]
      local shorty = rv.str:token(fam) ---family token
      local rawDef = { ---generic fallback definition
         blockedKey = 0,
         shift = 0,
         modus = 1,
         mBeforeG = 1,
         dir = "down",
         lastModN = 0,
         lastMod = 0,
         buttonCount = config[fam .. "ButtonCount"] or 0,
         sKey = config[fam .. "ShiftKey"] or 0,
         modeCount = config[fam .. "ModeCount"] or 0,
         modeConfig = config[fam .. "ModeConfig"] or {},
         modeIndex = {},
         bindHardwareModes = config[fam .. "BindHardwareModes"] or false,
         family = fam,
         token = shorty
      }

      if not profile.deviceState[shorty] then
         profile.deviceState[shorty] = rawDef
         compileDeviceStats(profile.deviceState[shorty])
      end
   end
   -- updating global stats after compiling all devices
   profile.globalState.sKey = sKey
   profile.globalState.maxKeys = moreKeys
   profile.globalState.maxMode = moreModes
   for i = 1, profile.globalState.maxMode do
      config.globalModes[i] = config.globalModes[i] or {i}
      if type(config.globalModes[i]) ~= "table" then config.globalModes[i] = {config.globalModes[i] --[[@as string]] } end
   end
end

return HardwareModule
