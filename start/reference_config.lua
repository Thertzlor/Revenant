---@type OptionsCollection
local config = {
    defaultMode = 1, -- General Profile configuration
    defaultShift = 0,
    globalModes = {}, --Compile relevant
    actionDelay = 2,
    keyDelay = 2,
    globalGShift = true,
    defaultHold = 500,
    multiClickTime = 200,
    pollInterval = 1,
    pollFamily = "lhc",
    actionVariance = 0,
    keyVariance = 0,
    defaultStacking = 1,
    externalConfigs = nil,
    externalDocs = nil,
    extends = "", --Compile relevant
    historyDepth = 2,
    mouseInterval = 5,
    mouseHistoryLimit = 100,
    restrictToMainScreen = true,
    -- Hardware Configuration
    resolutions =  {{ 3840, 2160, main = true}},
    scaleCoordinates = false,
    separateDeviceCycles = false,
    defaultModeTarget = nil, --Compile relevant
    mousePositionCheck = false,
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
    --LCD Configuration
    LCDPersistentProfile = true,
    outputLCD = true,
    clearLCD = true,
    keepNameOnLCD = true,
    LCDHidePrimaryMode = "unnamed",
    -- Flex Syntax Configuration (obviously all compile relevant)
    showCompiled = false, --except this one
    modeStack = "append",
    shiftStack = "append",
    customStack = "append",
    modeSort = "standard",
    shiftSort = "standard",
    customSort = {},
    stackOrder = { "custom", "mode", "shift" },
    stackAutoReverse = true,
    -- Profile Inheritance Configuration
    preventDocOverride = true,
    preventOptionOverride = true,
    -- Linter Settings
    enableLinting = true,
    abortOnLintError = true,
    enableConfigLinting = true,
    --Debug logging settings
    logLevel = 0,
    logEvents = false,
    logMemory = false,
    clearLog = true,
    -- lag offset
    offsetMovementLag = true,
    offsetWaitLag = true,
    maxLagSamples = 100,
    waitLagThreshold = 50,
    lagPositionThreshold = 1000,
    maxMovementLagSamples = 100,
}
return config