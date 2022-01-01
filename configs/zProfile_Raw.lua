i, e = pcall((function() local tl = {}--->>> Script Configuration ================================================================================
    tl.profileName = "Template" ---[*] Define your internal profile name here.
    tl.path = "D:/t-lib_g600" ---[*] Path to plugin folder
    tl.extPaths = { "profiles/ext_lua", "profiles/ext_work" } ---[*] What are the names of the folders
    tl.childPaths = true ---[*] Are the folders for profile groups child folders of the main script folder?
    tl.fileLocation = 1 ---[*] Does the current profile use an external file in any of the external paths?
    tl.fileName = nil --- Load external file from separate work directory
    tl.defaultDocPath = { path = "", prefix = "", suffix = "_doc", name = "" }
    tl.defaultConfigPath = { path = "", prefix = "", suffix = "_config", name = "" }  --- does the documentation file have an altogether other name and/or path? (overwrites docSuffix option)
    tl.configPath = "D:/t-lib_g600/configs"
    --->Path Config End =============================================================================================
    function tl.profile(a) --->>> Define Internal Key Assignments and profile configs Here (external files are recommended)  ==============================================================================

        --->>> < of Assignment Program! =========================================================================
    end loadfile(tl.path .. "/revenant.lua")():new(tl) end)) if (e) then OutputLogMessage("Error loading Revenant.\n" .. e .. ".\n") end --Main Program, do not touch
--[[ Key Test 
    
        --]]