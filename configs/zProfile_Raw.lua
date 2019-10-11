function Main()local tl={}--->>> Script Configuration ================================================================================
tl.config.profileName = "Template" 				--[*] Define your internal profile name here.
tl.config.path = "C:/mouse/t-lib_g600"	 			--[*] Path to plugin folder
tl.config.extPaths = {"ext_lua","ext_work"} 		--[*] What are the names of the folders
tl.config.childPaths = true							--[*] Are the folders for profile groups child folders of the main script folder?
tl.config.fileLocation =  2						--[*] Does the current profile use an external file in any of the external paths?
tl.fileName = nil							-- Load external file from separate work directory
tl.config.keyFile = "T-lib_keySetup.lua" 			-- Name of Keyboard Config file
tl.config.defaultMode = 1							-- In which modes should mouse buttons be active by default?
tl.config.defaultShift = 0							-- In which G-shift state should the buttons activate by default?
tl.config.genericModes = {}						-- Profile names to be used for the entire profile if defaultModeTarget is set to "all"
tl.config.actionDelay = 10							-- standard delay between key presses and sequence actions.
tl.config.keyDelay = 10							-- delay between pressing and releasing a button
tl.config.defaultHold = 500						-- How much time should pass between different stages of held keys by default?
tl.config.multiClickTime = 200						-- Default delay during which multi click functions can be triggered
tl.config.PollInterval = 5							-- delay (in milliseconds) before next loop, used to throttle polling rate
tl.config.randomActionDeviation = 0				-- Introduce random fluctuations in pauses during sequences
tl.config.randomKeyDeviation = 0					-- Introduce random fluctuations in delays between automated key presses
tl.config.customNames = true							-- Use mouse mappings that I personally think make more sense.
tl.config.defaultStacking = 1						-- Default stacking behavior for sequences
tl.config.preferShorthand = false						-- Prefer Shorthand names for properties over longhand names
tl.config.cacheLinks = false							-- Should linked macros be evaluated only when they are first generated or every time the button is pressed?
tl.config.historyDepth = 2							-- How many previously pressed buttons will the script remember for testing?
tl.config.mouseInterval = 3						-- How often should the script check the mouse position, relative to the polling rate?
tl.config.logMemory = false							-- Should the script log how much memory is in use when logging a button
tl.config.extends = ""								-- Name of Parent profile [WARNING: only use when you are certain that you won't extend any other profile from this one]

-- Documentation Configuration
tl.config.docModeButtonLock = true			-- Disable simulated button presses when in documentation mode
tl.config.docFile = 0								-- is the documentation for the profile saved in an external file?
tl.config.docPath =  ""							-- Where is the path for documentation files?
tl.config.docSuffix = "_doc"					-- what suffix does the documentation file have? (profileName.lua --> profileName_doc.lua)
tl.config.docName = 0								-- does the documentation file have an altogether other name and/or path? (overwrites docSuffix option)

--LCD Configuration
tl.config.outputLCD = true 							-- Show profile stats on logitech keyboard LCD screens or the LGS LCD emulator?
tl.config.clearLCD = true								-- Clear LCD screen before each message
tl.config.persistLCD = -1							-- Duration for which LCD messages should show on the screen in milliseconds. negative values show messages indefinitely
tl.config.keepNameOnLCD = true   						-- Always show profile name and mode information on LCD. only works if "clearLCD" is enabled
tl.config.appendNewLines = 1						-- Number of newlines to append after each LCD message.
tl.config.charsPerLine = 30						-- Maximum allowed characters in a line. Set to 0 for no automatic line breaks
tl.config.displayLines = 6							-- Maximum allowed lines on the LCD screen, set to 0 for no pagination.

-- Hardware Configuration
tl.config.resolutions = {1920,1080}				--[*] List of monitors with respective resolutions
tl.config.separateDeviceCycles = false					-- Should cycles be reset by inputs from other device families?
tl.config.defaultModeTarget = "self" 				-- which devices should be targetet by mode selection evens by default?
tl.config.logLevel = 0								-- Should unbound or unplayed buttons also be logged into the table of past keys?

tl.config.mouseButtonCount = 20					--[*] Number of Programmable buttons on the mouse
tl.config.mouseShiftKey = 6						--[*] G-Shift Key of the mouse
tl.config.mouseModeCount = 3						--[*] Number of modes on the mouse
tl.config.mouseModeConfig = {"mode 1","mode 2"}	-- Properties (name,color) of the modes on the mouse
tl.mouseBindHardwareModes = true				-- Should mouse modes be bound to the LGS hardware modes, if there are 3 or less?
tl.mousePositionCheck = false					-- Should the script track the position of the mouse?

tl.keyboardButtonCount = 6					--[*] Number of Programmable buttons on the keyboard
tl.keyboardShiftKey = 0						--[*] G-Shift Key of the keyboard
tl.keyboardModeCount = 0					--[*] Number of modes on the keyboard
tl.keyboardModeConfig = {} 					-- Properties (name,color) of the modes on the keyboard
tl.keyboardBindHardwareModes = true			-- Should keyboard modes be bound to the LGS hardware modes, if there are 3 or less?

tl.audioButtonCount = 0 					--[*] Number of Programmable buttons on the headset
tl.audioShiftKey = 0						--[*] G-Shift Key of the headset
tl.audioModeCount = 0						--[*] Number of modes on the headset
tl.audioModeConfig = {}						-- Properties (name,color) of the modes on the headset
tl.audioBindHardwareModes = false 				-- Should headset modes be bound to the LGS hardware modes, if there are 3 or less?

tl.lhcButtonCount = 0 						--[*] Number of Programmable buttons on the LHC
tl.lhcShiftKey = 0							--[*] G-Shift Key of the LHC
tl.lhcModeCount = 0							--[*] Number of modes on the LHC
tl.lhcModeConfig = {}						-- Properties (name,color) of the modes on the LHC
tl.lhcBindHardwareModes = false					-- Should LHC modes be bound to the LGS hardware modes, if there are 3 or less?

-- Flex Syntax Configuration
tl.config.showCompiled = true 						-- Show the compiled key table at startup?
tl.config.modeStack = "prepend" 					-- How should mode grouped keys be stacked during compilation?
tl.config.shiftStack = "prepend" 					-- How should shift grouped keys be stacked during compilation?
tl.config.customStack = "prepend" 					-- How should custom grouped keys be stacked during compilation?
tl.config.modeSort = "standard" 					-- Which order should mode grouped keys be sorted during compilation?
tl.config.shiftSort = "standard" 					-- Which order should shift grouped keys be sorted during compilation?
tl.config.customSort = {} 							-- Which order should custom grouped keys be sorted during compilation?
tl.config.stackOrder = {"custom","mode","shift"} 	-- Stacking Hierarchy for different groups during compilation
tl.config.stackAutoReverse = true 					-- Keep code chunks in the same order as they are prepended and enforce stack order
tl.config.stackDepth = 1 							-- How deep should predefined tables for modes and shift states be defined by the script?
tl.config.singleType = 0 							-- should inherited type definitions assume that all table contents are seperate functions

---> Config End =============================================================================================
function tl.setKeys(a,b) --->>>Define Internal Key Assignments Here! ==============================================================================

	--[[ Examples:
		b.m9 = "a"								-- simple key
		b.m10 = {"/s","a"} 						-- Combined Keys
		b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
		b.m12={0,type="m"} 						-- Mode change
	--]]

--->>> End of Assignment Area! =========================================================================
end loadfile(tl.config.path.."/T-lib.lua")(tl)end Main() --Main Program, do not touch
--[[ Key Test Area




--]]