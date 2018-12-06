--->>> Script Configuration ================================================================================
tl = {path = [[D:\T-lib\]]}			-- Path to plugin folder
tl.exFile = false
tl.keyFile = "T-lib_keySetup.lua" 	-- Name of Keyboard Config file
tl.autoHot = true 					-- Enable and disable AutoHotkey integration
tl.modeBound = true 				-- Bind internal modes to hardware mouse modes
tl.sKey = 6 						-- Mouse button to use as G-shift modifier
tl.maxMode = 1 					-- Number of internal mouse modes. Binding the modes to the mouse only works for values up to 3.
tl.PollInterval = 2				-- delay (in milliseconds) before next loop, used to throttle polling rate
tl.actionDelay = 2					-- standard delay between key presses and sequence actions.
tl.keyDelay = 2					-- delay between pressing and releasing a button
tl.logicalMouse = true				-- Use mouse mappings that I personally think make more sense.
tl.defMode = 0					-- In which modes should mouse buttons be active by default?
tl.defG = 2						-- In which G-shift state should the buttons activate by default?
tl.defStack = 1					-- Default stacking behavior for sequences
tl.pName = "Git Bash" 				-- Define your internal profile name here.
tl.nameIndex = 6					-- Position of the profile's name in the list read by the AHK script.
---> Config End =============================================================================================
dofile(tl.path.."T-lib.lua") function tl.setKeys()local b=tl.assign -- Main Program, do not touch
    if tl.exFile == true then dofile(tl.path.."ext_lua\\"..tl.pName..".lua")
--->>>Define Assignments Here! ==============================================================================
--[[ Examples:
	b.m9 = "a"								-- simple key
	b.m10 = {"/s","a"} 						-- Combined Keys
	b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
	b.m12={0,type="c"} 						-- Mode change
--]]

b.m3="/3"										-- Default Mouse functions
b.m4="/4"
b.m5="/5"



--	dofile(tl.path.."_tempEdit.lua")			--External file for prettier formatting

end--->>> End of Assignment Program! =========================================================================
--[[ Key Test Area



--]]