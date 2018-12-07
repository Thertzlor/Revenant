--->>> Script Configuration ================================================================================
tl = {path = [[D:\T-lib\]]}			-- Path to plugin folder
tl.exFile = true					-- Are bindings defined in an external file?
tl.workProfile = true				-- Load external file from separate work directory
tl.keyFile = "T-lib_keySetup.lua" 	-- Name of Keyboard Config file
tl.autoHot = true 					-- Enable and disable AutoHotkey integration
tl.modeBound = true 				-- Bind internal modes to hardware mouse modes
tl.sKey = 6 						-- Mouse button to use as G-shift modifier
tl.maxMode = 3 					-- Number of internal mouse modes. Binding the modes to the mouse only works for values up to 3.
tl.PollInterval = 2				-- delay (in milliseconds) before next loop, used to throttle polling rate
tl.actionDelay = 10				-- standard delay between key presses and sequence actions.
tl.keyDelay = 10					-- delay between pressing and releasing a button
tl.logicalMouse = true				-- Use mouse mappings that I personally think make more sense.
tl.defMode = 0					-- In which modes should mouse buttons be active by default?
tl.defG = 2						-- In which G-shift state should the buttons activate by default?
tl.defStack = 1					-- Default stacking behavior for sequences
tl.pName = "Template" 				-- Define your internal profile name here.
tl.nameIndex = 1					-- Position of the profile's name in the list read by the AHK script.
---> Config End =============================================================================================
dofile(tl.path.."T-lib.lua") function tl.setKeys() local b=tl.assign tl.loadEx()--Main Program, do not touch

--->>>Define Internal Key Assignments Here! ==============================================================================

--[[ Examples:
	b.m9 = "a"								-- simple key
	b.m10 = {"/s","a"} 						-- Combined Keys
	b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
	b.m12={0,type="c"} 						-- Mode change
--]]

if b.m3 == nil then b.m3="/3" end				-- Default Mouse functions
if b.m4 == nil then b.m4="/4" end
if b.m5 == nil then b.m5="/5" end


end--->>> End of Assignment Program! =========================================================================
--[[ Key Test Area



--]]