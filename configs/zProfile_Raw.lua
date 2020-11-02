local i,e=pcall((function()local tl={}--->>> Script Path Configuration ================================================================================
  tl.profileName = "Chrome_Ika" 				-- [*] Define your internal profile name here.
  tl.path = "C:/maus/T-lib_g600"				-- [*] Path to plugin folder
  tl.extPaths = {"profiles/ext_lua","profiles/ext_work"}			-- [*] What are the names of the folders
  tl.childPaths = true							-- [*] Are the folders for profile groups child folders of the main script folder?
  tl.fileLocation =  2						-- [*] Does the current profile use an external file in any of the external paths?
  tl.fileName = nil							-- Load external file from separate work directory
  
  --> Config End =============================================================================================
  function tl.profile(a)local b=a.key--->>>Define Internal Key Assignments Here! ==============================================================================
  --[[ Examples:
    b.m9 = "a"								-- simple key
    b.m10 = {"/s","a"} 						-- Combined Keys
    b.m11 = {"a","b",300,"c","dodo", type="s"}	-- Sequence
    b.m12={0,type="m"} 						-- Mode change
  --]]  
  --->>> End of Assignment Area! =========================================================================
  end loadfile(tl.path.."/T-lib.lua")():new(tl)end))if(e)then OutputLogMessage("Error loading T-Lib.\n"..e..".\n")end --Main Program, do not touch!
  
  
  --[[ Key Test Area
  
  
  --]]