--->>> Script Configuration ================================================================================
tl = {path = [[D:\T-lib\]]}					-- Path to plugin folder
tl.exFile = 1		    					-- Are bindings defined in an external file?
tl.workProfile = 1 							-- Load external file from separate work directory
tl.keyFile = "T-lib_keySetup.lua" 			-- Name of Keyboard Config file
tl.autoHot = 0 								-- Enable and disable AutoHotkey integration
tl.modeBound = 1 							-- Bind internal modes to hardware mouse modes
tl.sKey = 6 								-- Mouse button to use as G-shift modifier
tl.maxMode = 3 								-- Number of internal mouse modes. Binding the modes to the mouse only works for values up to 3.
tl.PollInterval = 5							-- delay (in milliseconds) before next loop, used to throttle polling rate
tl.actionDelay = 10							-- standard delay between key presses and sequence actions.
tl.keyDelay = 10							-- delay between pressing and releasing a button
tl.logicalMouse = 1							-- Use mouse mappings that I personally think make more sense.
tl.defMode = 0								-- In which modes should mouse buttons be active by default?
tl.defG = 2									-- In which G-shift state should the buttons activate by default?
tl.defStack = 1								-- Default stacking behavior for sequences
tl.pName = "Template" 						-- Define your internal profile name here.
tl.nameIndex = 1							-- Position of the profile's name in the list read by the AHK script.
tl.preferShort = 0							-- Prefer Shorthand names for properties over longhand names
tl.defaultHold = 500						-- How much time should pass between different stages of held keys by default?
tl.historyDepth = 2							-- How many previously pressed buttons will the script remember for testing?
tl.logEmpty = 0								-- should unbound and/or unsuccesfully triggered keys be counted as button presses?
--->>> Flex Syntax Configuration ===========================================================================
tl.modeStack = "prepend"					-- How should mode grouped keys be stacked during compilation?
tl.shiftStack = "prepend"					-- How should shift grouped keys be stacked during compilation?
tl.customStack = "prepend"					-- How should custom grouped keys be stacked during compilation?
tl.modeSort = "standard"					-- Which order should mode grouped keys be sorted during compilation?
tl.shiftSort = "standard"					-- Which order should shift grouped keys be sorted during compilation?
tl.customSort = {}							-- Which order should custom grouped keys be sorted during compilation?
tl.stackOrder = {"custom","mode","shift"}	-- Stacking Hierarchy for different groups during compilation
tl.stackDepth = 1							-- How deep should predefined tables for modes and shift states be defined by the script?
tl.stackAutoReverse = 1						-- Keep code chunks in the same order as they are prepended and enforce stack order
tl.singleType = 0							-- should inherited type definitions assume that all table contents are seperate functions
tl.showCompiled = 1							-- Show the final compiled key table at startup?
---> Config End =============================================================================================
dofile(tl.path.."T-lib.lua")function tl.setKeys()local a,b=tl.assign,tl.assign.key tl.loadEx()--Main Program, do not touch
--->>>Define Internal Key Assignments Here! ==============================================================================

--[[ Examples:
	b.m9 = "a"								-- simple key
	b.m10 = {"/s","a"} 						-- Combined Keys
	b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
	b.m12={0,type="m"} 						-- Mode change
--]]




end--->>> End of Assignment Program! =========================================================================
--[[ Key Test Area



--]]