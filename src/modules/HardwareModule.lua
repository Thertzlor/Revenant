local rv = ... ---@type Revenant
local type, pairs, assert = type, pairs, assert
local hardwarePresets = rv:import(rv.paths.configPath .. '/HardwareDefinitions.lua') ---@type table<string,HardwareDefinition>
local deviceOptions = { "ButtonCount", "ModeCount", "ShiftKey", "ModeConfig", "BindHardwareModes" }

--[[=============================================================]] --
---@class HardwareDefinition
---@field name string
---@field blockedKey  number
---@field shift  number
---@field modus  number
---@field mBeforeG  number
---@field dir string
---@field modeIndex table<string,number>
---@field lastModN number
---@field lastMod  number
---@field token string
---@field family string
---@field buttonCount number
---@field sKey number
---@field modeCount number
---@field modeConfig string[]|number[]|table)[]
---@field bindHardwareModes  boolean
--[[=============================================================]] --
local HardwareModule = rv.baseClass:new() ---@class HardwareModule:BaseClass Managing Hardware definitions

function HardwareModule:constructor()
    for k, v in pairs(hardwarePresets) do
        hardwarePresets[k] = rv.tbl:intersectSimple(v, { modeIndex = {}, lastModN = 0, blockedKey = 0, shift = 0, mBeforeG = 1, lastMod = 0, modus = 1, dir = "down", name = k, token = rv.str:token(v.family), bindHardwareModes = true })
    end
end

---@param profile ProfileDefinition
function HardwareModule:defineDevices(profile)
    local moreModes = 0
    local moreKeys = 0
    local sKey = false
    local config = profile.config
    local devicePreset = config.devices
    if profile.config.rename then
        for k, v in pairs(profile.config.rename) do
            if type(v) == "table" then for i = 1, #v do profile.unRename[v[i]] = k end
            else profile.unRename[v] = k end
        end
    end
    ---@param device HardwareDefinition
    local function compileDeviceSats(device)
        if device.sKey then sKey = true end
        if config.defaultModeTarget == "join" then device.modeConfig = config.globalModes end
        for m = 1, device.buttonCount do profile.unRename[device.token .. m] = profile.unRename[device.token .. m] or device.token .. m end
        device.modeConfig = device.modeConfig or {}
        if next(device.modeConfig) and #device.modeConfig ~= device.modeCount then device.modeCount = #device.modeConfig end
        for h = 1, device.modeCount do
            if type(device.modeConfig[h]) ~= "table" then device.modeConfig[h] = (device.modeConfig[h] and { device.modeConfig[h] }) or {} end
            local modName = device.modeConfig[h][1] or h ---@type integer|table
            if type(modName ~= "table") then modName = { modName } end
            for m = 1, #modName do device.modeIndex[modName[m]] = h end
            device.modeConfig[h][1] = modName[#modName]
        end
        if device.modeCount > moreModes then moreModes = device.modeCount end
        moreKeys = moreKeys + device.buttonCount
    end

    if devicePreset then
        if type(devicePreset) ~= "table" then devicePreset = { devicePreset } end
        for i = 1, #devicePreset do local dev = assert(hardwarePresets[devicePreset[i]], 'No definition found for Device "' .. devicePreset[i] .. '"')
            if i == 1 and i == #devicePreset then profile.globalState.singleDevice = dev.token end
            local fam = dev.family
            for n = 1, #deviceOptions do local opt = deviceOptions[n]
                if config[fam .. opt] ~= nil then dev[rv.str:firstLower(opt)] = config[fam .. opt] end
            end
            compileDeviceSats(dev)
            profile.deviceState[dev.token] = dev
        end
    end
    for g = 1, #rv.stringPresets.families do
        local fam = rv.stringPresets.families[g]
        local shorty = rv.str:token(fam)
        local rawDef = {
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
            compileDeviceSats(profile.deviceState[shorty])
        end
    end
    profile.globalState.sKey = sKey
    profile.globalState.maxKeys = moreKeys
    profile.globalState.maxMode = moreModes
    for i = 1, profile.globalState.maxMode do config.globalModes[i] = config.globalModes[i] or { i }
        if type(config.globalModes[i]) ~= "table" then config.globalModes[i] = { config.globalModes[i] } end
    end
end

return HardwareModule
