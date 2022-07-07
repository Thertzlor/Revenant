---@type OptionsCollection
local config = {
    defaultMode = 1, -- General Profile configuration
    defaultShift = 0,
    globalModes = {}, --Compile relevant
    globalGShift = true,
    defaultStacking = 1,
    externalDocs = nil,
    historyDepth = 2,
    mouseHistoryLimit = 100,
    description = "",
    -- Timing Configuration
    actionDelay = 2,
    keyDelay = 2,
    multiClickTime = 200,
    defaultHold = 500,
    actionVariance = 0,
    keyVariance = 0,
    -- Hardware Configuration
    devices = "G600",
    separateDeviceCycles = false,
    defaultModeTarget = nil, --Compile relevant
    defaultKeys = {
        m3 = { "/3", m = 0, g = 2 },
        m4 = { "/4", m = 0, g = 2 },
        m5 = { "/5", m = 0, g = 2 }
    },
    rename = {
        m4 = "m8",
        m5 = "m7",
        m9 = "g1",
        m10 = "g2",
        m11 = "g3",
        m12 = "g4",
        m13 = "g5",
        m14 = "g6",
        m15 = "g7",
        m16 = "g8",
        m17 = "g9",
        m18 = "g10",
        m19 = "g11",
        m20 = "g12"
    },
    globalModeFamily = "kb",
    primaryButtons = false,
    modeReset = true,
    --Screen configuration
    monitors = { { 3840, 2160, main = true } },
    restrictToMainScreen = true,
    -- polling configuration
    pollInterval = 1,
    pollFamily = "lhc",
    pollMKeysOnly = true,
    --LCD Configuration
    outputLCD = true,
    LCDLines = 10,
    LCDLineLength = 76,
    LCDMessageDuration = 3000,
    LCDPersistentProfile = true,
    keepNameOnLCD = true,
    LCDSeparator = true,
    LCDHidePrimaryMode = "unnamed",
    LCDLastLinePagination = true,
    -- Flex Syntax Configuration (obviously all compile relevant)
    modeStack = "append",
    shiftStack = "append",
    customStack = "append",
    modeSort = "standard",
    shiftSort = "standard",
    customSort = {},
    stackOrder = { "custom", "mode", "shift" },
    stackAutoReverse = true,
    -- Profile Inheritance Configuration
    extends = "", --Compile relevant
    externalConfigs = {},
    preventDocOverride = true,
    preventOptionOverride = true,
    preventInheritance = {},
    mergeDocumentation = true,
    mergeScopeDefaults = true,
    --Debug logging settings
    logLevel = 0,
    logEvents = false,
    logMemory = false,
    logDebounce = false,
    showCompiled = false, --except this one
    clearLog = true,
    -- Linter Settings
    enableLinting = true,
    enableConfigLinting = true,
    abortOnLintError = true,
    -- lag offset
    offsetMovementLag = true,
    offsetWaitLag = true,
    maxLagSamples = 100,
    waitLagThreshold = 50,
    lagPositionThreshold = 1000,
    maxMovementLagSamples = 100,
    -- debounce
    enableDebounce = false,
    debounceSettings = {
        mouse = {
            { 1, 30, 'up' },
            { 2, 30, 'up' }
        }
    }
}
return config
