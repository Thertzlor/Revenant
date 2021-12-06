return {
  defaultMode = 0, -- General Profile configuration
  defaultShift = 0,
  genericModes = {}, --Compile relevant
  customNames = true,
  actionDelay = 2,
  keyDelay = 2,
  defaultHold = 500,
  multiClickTime = 200,
  pollInterval = 2,
  pollFamily = "lhc",
  randomActionDeviation = 0,
  randomKeyDeviation = 0,
  primaryButtons = false,
  defaultStacking = 1,
  preferShorthand = false,
  externalConfigs=nil,
  externalDocs=nil,
  historyDepth = 2,
  mouseInterval = 5,
  mouseHistoryLimit = 100,
  logEvents = false,
  logMemory = false,
  logBounce=true,
  clearLog = true,
  extends = "", --Compile relevant
  enableLinting = true,
  abortOnLintError = true,
  enableConfigLinting = true,
  hubMode = false,
  -- Hardware Configuration
  resolutions = {1920, 1080},
  scaleCoordinates = false,
  separateDeviceCycles = false,
  defaultModeTarget = nil, --Compile relevant
  logLevel = 0,
  mouseButtonCount = 20, --Compile relevant
  mouseShiftKey = 6, --Compile relevant
  mouseModeCount = 3, --Compile relevant
  mouseModeConfig = {"mode 1", "mode 2", "mode 3"}, --Compile relevant
  mouseBindHardwareModes = true,
  mousePositionCheck = false,
  keyboardButtonCount = 6,
  keyboardShiftKey = 6,
  keyboardModeCount = 0,
  keyboardModeConfig = {},
  keyboardBindHardwareModes = true,
  lhcButtonCount = 1,
  lhcShiftKey = 0,
  lhcModeCount = 1,
  lhcModeConfig = {},
  lhcBindHardwareModes = false,
  --LCD Configuration
  outputLCD = true,
  clearLCD = true,
  persistLCD = -1,
  keepNameOnLCD = true,
  appendNewLines = 1,
  docModeButtonLock = true,
  charsPerLine = 30,
  displayLines = 6,
  -- Flex Syntax Configuration (obviously all compile relevant)
  showCompiled = true, --except this one
  modeStack = "append",
  shiftStack = "append",
  customStack = "append",
  modeSort = "standard",
  shiftSort = "standard",
  customSort = {},
  stackOrder = {"custom", "mode", "shift"},
  stackAutoReverse = true,
  -- Profile Inheritance Configuration
  maxInheritanceDepth = 20,
  handleOptionConflicts = "replaceDuplicates",
  handleDocumentationConflicts = "replaceDuplicates",
  debouncerSettings = {
    mouse={
      {1,30,'up'},
      {2,30,'up'}
    }
  },
  defaultKeys = {
    m1 = {"/1", m = 0, g = 2},
    m2 = {"/2", m = 0, g = 2},
    m3 = {"/3", m = 0, g = 2},
    m4 = {"/4", m = 0, g = 2},
    m5 = {"/5", m = 0, g = 2}
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
}