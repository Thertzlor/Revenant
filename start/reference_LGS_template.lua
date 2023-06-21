local _, e = pcall((function()
   local rv = {}
   --->>> Script Configuration --================================================================================
   --- Any field prefixed with [*] NEEDS to be filled for Revenant to work.
   rv.profileName = "Template" ---[*] Define your internal profile name here.
   rv.path = "D:/Revenant" ---[*] Path to the folder in which Revenant is installed
   rv.configPath = "D:/Revenant/configs"
   rv.profilePath = "profiles" ---[*] name of the profile folder
   rv.externalProfile = true ---[*] Does the current profile use an external file in any of the external paths?
   rv.defaultDocPath = {prefix = "", suffix = "_doc"}
   rv.defaultConfigPath = {prefix = "", suffix = "_config"} ---does the documentation file have an altogether other name and/or path? (overwrites docSuffix option)
   rv.absoluteProfilePaths = false ---[*] Are the folders for profile groups child folders of the main script folder?
   rv.absoluteConfigPaths = false
   rv.absoluteDocPaths = false
   rv.absoluteParentPaths = false
   --->>>Path Config End =============================================================================================
   function rv.profile(a) --->>> You can define Internal Key Assignments and profile configs Here (but external files are recommended)

      --->>> end of Assignment Program! =========================================================================
   end
   loadfile(rv.path .. "/revenant.lua")():new(rv)
end))
if (e) then OutputLogMessage("Error loading Revenant.\n" .. e .. ".\n") end -- Main Program Logic, do not touch
--[[ Key Test Area




--]]
