local error, sub, match, gsub = error, string.sub, string.match, string.gsub
---Storing loaded classes to prevent double imports
local fileCache = {} ---@type table<string,{new:fun():any}>
local lenientFileCache = {} ---@type table<string,any>
---Utilities for importing files and classes
---@class ImportModule
---@field private rv Revenant
local ImportModule = {}
---Initialize the Import Module
---@param rev Revenant
function ImportModule:new(rev)
   local o = {}
   self.__index = self ---@private
   setmetatable(o, self)
   o:constructor(rev)
   return o --[[@as ImportModule]]
end

---@protected
---@param rev Revenant
function ImportModule:constructor(rev)
   self.rv = rev
   self.macroTerms = rev.presets.stringPresets.macroTerms
   self.macroImports = {} ---@type table<string,true>
   self.classMap = {} ---@type table<string, {[1]:string, [2]:string}>
   for i = 1, #self.macroTerms do
      local el = self.macroTerms[i]
      self.classMap[el[2]] = {el[1], el[2]}
      self.classMap[el[3]] = {el[1], el[2]}
   end -- dynamically initializing shorthand options
end

---Add an import error to the error array
---@param e string
---@param path string
function ImportModule:_handleImportErrors(e, path) self.rv.states.scriptStates.errors[#self.rv.states.scriptStates.errors + 1] = "could not load file from path '" .. path .. ", Error:\n  \"" .. e .. "\"" end

---safely load an external lua file
---@param path string
---@param handler? fun(arg1:string, arg2:string)
---@param currentPath? string
---@return unknown? #Whatever comes back from the targeted file
function ImportModule:loadFile(path, handler, currentPath)
   local realpath = self:resolvePath(path, currentPath, true)
   ---@type boolean, any
   local code, ret = xpcall(function() return (loadfile(realpath) or error("No File/Syntax Error", 2))(self.rv) end, function(err)
      if handler then return handler(err, realpath) end
      self:_handleImportErrors(err, realpath)
   end)
   if code then
      fileCache[path] = ret
      return ret
   end
end

---resolves an indirect path into a an absolute path
---@param path string
---@param currentPath? string
---@param acceptRelative? boolean
---@return string
function ImportModule:resolvePath(path, currentPath, acceptRelative)
   if sub(path, 1, 10) == "@profiles/" then path = self.rv.paths.profilePath .. sub(path, 10) end
   if sub(path, 1, 4) == "@rv/" then path = self.rv.paths.path .. sub(path, 4) end
   if not match(path, "^[%l%u]:/") then
      if not currentPath then
         if not acceptRelative then error("Cannot resolve a relative path '" .. path .. "' without absolute parent path") end
      elseif sub(path, 1, #currentPath) ~= currentPath then
         path = currentPath .. "/" .. path
      end
   end
   path = gsub(path, "/+", "/")
   return path
end

---import and cache a class from an external lua file
---@param path string #The location of the file, relative to revenant directory
---@param handler? fun(str:string, str:string) #Custom Error handler
---@param parentPath? string #parent profile for resolving paths
---@return any #the loaded class
function ImportModule:import(path, handler, parentPath)
   local p = gsub(gsub(path, "%.lua$", ""), "$", ".lua")
   return fileCache[p] or self:loadFile(p, handler, parentPath)
end

---import a class
---@generic T
---@param name `T` The name of the class
---@return T #The new instance
function ImportModule:classImport(name)
   local isMacro = match(name, "Macro$")
   if isMacro and name ~= "GroupMacro" then self.macroImports[name] = true end
   return self:import("@rv/src/" .. ((isMacro and "macros/") or "classes/") .. name)
end

---Fakes a profile import
---@param path string
---@param currentPath? string
---@return ProfileTemplate
function ImportModule:fakeProfileImport(path, currentPath)
   local base = self.rv.baseClass:new() ---@diagnostic disable-next-line: invisible
   base.autoKeys = true ---@diagnostic disable-next-line: invisible
   local magTable = base:autoTable({library = {}} --[[@as any]])
   assert(self:lenientLoad(path, true, currentPath), "Error importing '" .. path .. "': File not found/syntax error")(magTable, self.rv) ---@diagnostic disable-next-line: invisible
   base.autoKeys = false
   return magTable
end

---Load lua files in an environment with auto-filled variables
---@param path string #Path to the file
---@param noExec? boolean #true if we want a returned class to be instantiated later
---@param currentPath? string #The current path
---@return any #whatever was imported
function ImportModule:lenientLoad(path, noExec, currentPath)
   local p = gsub(gsub(self.rv.importer:resolvePath(path, currentPath), "%.lua$", ""), "$", ".lua")
   if lenientFileCache[p] then return lenientFileCache[p] end
   self.rv.utils.simplifiedLua()
   local imp = loadfile(p) or function() end
   local ret = noExec and imp or imp()
   self.rv.utils.developerMode(0)
   if ret then lenientFileCache[p] = ret end
   return ret
end

return ImportModule