local _,e=pcall((function()local rv={}--->>> Script Configuration --================================================================================

                                 ---Any field prefixed with [*] NEEDS to be filled for Revenant to work.
rv.profileName = "Template"      ---[*] Define your internal profile name here.
rv.path = "./revenant"           ---[*] Path to the folder in which Revenant is installed, can be relative to LGS install path.
rv.profilePath = "@rv/profiles"  ---[*] path of the profile directory, "@rv" means relative to the Revenant root directory.
rv.externalProfile = false       ---[*] Does the current profile use an external file?
rv.defaultDocPath = {prefix = "", suffix = "_doc"}
rv.defaultConfigPath = {prefix = "", suffix = "_config"} ---does the documentation file have an altogether other name and/or path? (overwrites docSuffix option)
rv.configPath = nil

function rv.profile(profile)--->>> Script Configuration End =============================================================================================
--->>> You can define Internal Key Assignments and profile configs Here (but external files are recommended)



--->>> end of Assignment Program! =========================================================================
end loadfile(rv.path.."/revenant.lua")():new(rv)end))if(e)then OutputLogMessage("Error loading Revenant.\n"..e..".\n")end-- Main Program Logic, do not touch!

--[[ Key Test Area




--]]