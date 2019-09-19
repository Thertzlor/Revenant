function Main()local tl={}--->>> Script Configuration ================================================================================
tl.profileName = "Template" 				--[*] Define your internal profile name here.
tl.path = "C:/mouse/t-lib_g600"	 			--[*] Path to plugin folder
tl.extPaths = {"ext_lua","ext_work"} 		--[*] What are the names of the folders
tl.childPaths = true							--[*] Are the folders for profile groups child folders of the main script folder?
tl.fileLocation =  2						--[*] Does the current profile use an external file in any of the external paths?
tl.fileName = nil							-- Load external file from separate work directory
tl.keyFile = "T-lib_keySetup.lua" 			-- Name of Keyboard Config file
tl.defaultMode = 1							-- In which modes should mouse buttons be active by default?
tl.defaultShift = 0							-- In which G-shift state should the buttons activate by default?
tl.genericModes = {}						-- Profile names to be used for the entire profile if defaultModeTarget is set to "all"
tl.actionDelay = 10							-- standard delay between key presses and sequence actions.
tl.keyDelay = 10							-- delay between pressing and releasing a button
tl.defaultHold = 500						-- How much time should pass between different stages of held keys by default?
tl.multiClickTime = 200						-- Default delay during which multi click functions can be triggered
tl.PollInterval = 5							-- delay (in milliseconds) before next loop, used to throttle polling rate
tl.randomActionDeviation = 0				-- Introduce random fluctuations in pauses during sequences
tl.randomKeyDeviation = 0					-- Introduce random fluctuations in delays between automated key presses
tl.customNames = true							-- Use mouse mappings that I personally think make more sense.
tl.defaultStacking = 1						-- Default stacking behavior for sequences
tl.preferShorthand = false						-- Prefer Shorthand names for properties over longhand names
tl.cacheLinks = false							-- Should linked macros be evaluated only when they are first generated or every time the button is pressed?
tl.historyDepth = 2							-- How many previously pressed buttons will the script remember for testing?
tl.mouseInterval = 3						-- How often should the script check the mouse position, relative to the polling rate?
tl.logMemory = false							-- Should the script log how much memory is in use when logging a button
tl.extends = ""								-- Name of Parent profile [WARNING: only use when you are certain that you won't extend any other profile from this one]

-- Documentation Configuration
tl.docModeButtonLock = true			-- Disable simulated button presses when in documentation mode
tl.docFile = 0								-- is the documentation for the profile saved in an external file?
tl.docPath =  ""							-- Where is the path for documentation files?
tl.docSuffix = "_doc"					-- what suffix does the documentation file have? (profileName.lua --> profileName_doc.lua)
tl.docName = 0								-- does the documentation file have an altogether other name and/or path? (overwrites docSuffix option)

--LCD Configuration
tl.outputLCD = true 							-- Show profile stats on logitech keyboard LCD screens or the LGS LCD emulator?
tl.clearLCD = true								-- Clear LCD screen before each message
tl.persistLCD = -1							-- Duration for which LCD messages should show on the screen in milliseconds. negative values show messages indefinitely
tl.keepNameOnLCD = true   						-- Always show profile name and mode information on LCD. only works if "clearLCD" is enabled
tl.appendNewLines = 1						-- Number of newlines to append after each LCD message.
tl.charsPerLine = 30						-- Maximum allowed characters in a line. Set to 0 for no automatic line breaks
tl.displayLines = 6							-- Maximum allowed lines on the LCD screen, set to 0 for no pagination.

-- Hardware Configuration
tl.resolutions = {1920,1080}				--[*] List of monitors with respective resolutions
tl.separateDeviceCycles = false					-- Should cycles be reset by inputs from other device families?
tl.defaultModeTarget = "self" 				-- which devices should be targetet by mode selection evens by default?
tl.logLevel = 0								-- Should unbound or unplayed buttons also be logged into the table of past keys?

tl.mouseButtonCount = 20					--[*] Number of Programmable buttons on the mouse
tl.mouseShiftKey = 6						--[*] G-Shift Key of the mouse
tl.mouseModeCount = 3						--[*] Number of modes on the mouse
tl.mouseModeConfig = {"mode 1","mode 2"}	-- Properties (name,color) of the modes on the mouse
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
tl.showCompiled = true 						-- Show the compiled key table at startup?
tl.modeStack = "prepend" 					-- How should mode grouped keys be stacked during compilation?
tl.shiftStack = "prepend" 					-- How should shift grouped keys be stacked during compilation?
tl.customStack = "prepend" 					-- How should custom grouped keys be stacked during compilation?
tl.modeSort = "standard" 					-- Which order should mode grouped keys be sorted during compilation?
tl.shiftSort = "standard" 					-- Which order should shift grouped keys be sorted during compilation?
tl.customSort = {} 							-- Which order should custom grouped keys be sorted during compilation?
tl.stackOrder = {"custom","mode","shift"} 	-- Stacking Hierarchy for different groups during compilation
tl.stackAutoReverse = true 					-- Keep code chunks in the same order as they are prepended and enforce stack order
tl.stackDepth = 1 							-- How deep should predefined tables for modes and shift states be defined by the script?
tl.singleType = 0 							-- should inherited type definitions assume that all table contents are seperate functions

---> Config End =============================================================================================
function tl.setKeys(a,b) --->>>Define Internal Key Assignments Here! ==============================================================================

	--[[ Examples:
		b.m9 = "a"								-- simple key
		b.m10 = {"/s","a"} 						-- Combined Keys
		b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
		b.m12={0,type="m"} 						-- Mode change
	--]]

end --->>> End of Assignment Program! =========================================================================
loadfile(table.concat({tl.path,"T-lib.lua"},"/"))(tl)end Main() --Main Program, do not touch
--[[ Key Test Area



--]]